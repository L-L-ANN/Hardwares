%
% RDAClient.m  MATLAB RDA Client without GUI
%
% Demonstration file for implementing a simple MATLAB client for the
% RDA tcpip interface of BrainVision Recorder.
% It reads all information of the recorded EEG, prints marker information
% to the MATLAB console, and calculates the average power in the EEG as
% an example.
%
%
% Development notes
% ------------------
% Requires MATLAB Version R2014b or higher
%
% The function was developed and tested using
% MATLAB Version: 24.1.0.2628055 (R2024a) Update 4
% Operating System: Microsoft Windows 11 Pro Version 10.0 (Build 26100)
%
%
%--------------------------------------------------------------------------
% Copyright 2024 Brain Products GmbH
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:
%
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
% OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
% THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%--------------------------------------------------------------------------

%% Main RDA Client function
function RDAClient()

% Enter IP address and port of the PC running BrainVision Recorder with RDA
% Connecting to 32-bit RDA-port (use 51234 to connect to 16-bit port):
remoteHostIP = '127.0.0.1';
remotePort = 51244;
con = tcpclient(remoteHostIP, remotePort);

% Checking for available data every 100 ms:
while con.NumBytesAvailable < 24
    pause(0.1)
end
disp('connection established');

% --- Main reading loop ---
header_size = 24;
finish = false;
while ~finish
    try
        % Checking for existing data in socket buffer:
        while con.NumBytesAvailable >= 24
            
            % Reading header of RDA message:
            hdr = ReadHeader(con);

            % Performing action depending on the type of the data package:
            switch hdr.type
                case 1       % Start; Setup information like EEG properties
                    disp('Start');
                    % Reading and displaying EEG properties:
                    props = ReadStartMessage(con, hdr);
                    disp(props);

                    % Resetting block counter to check overflows:
                    lastBlock = -1;

                    % Setting data buffer to empty:
                    data1s = [];

                case 3       % Stop message
                    disp('Stop');
                    data = read(con, hdr.size - header_size);
                    finish = true;

                case 4       % 32-bit data block
                    % Reading data and markers from message:
                    [datahdr, data, markers] = ReadDataMessage(con, hdr, props);
                    
                    % Checking tcpip buffer overflow:
                    if lastBlock ~= -1 && datahdr.block > lastBlock + 1
                        disp(['******* Overflow with '...
                            int2str(datahdr.block-lastBlock) ' blocks ******']);
                    end
                    lastBlock = datahdr.block;

                    % Print marker info to MATLAB console:
                    if datahdr.markerCount > 0
                        for m = 1:datahdr.markerCount
                            disp(markers(m));
                        end
                    end

                    % Processing EEG data (extracting last recorded second):
                    EEGData = reshape(data, props.channelCount,...
                        length(data)/props.channelCount);
                    data1s = [data1s EEGData];
                    dims = size(data1s);
                    % Calculating the average power of the signal:
                    if dims(2) > 1000000 / props.samplingInterval
                        data1s = data1s(:, dims(2) - 1000000 / props.samplingInterval : dims(2));
                        avg = mean(mean(data1s.*data1s));
                        disp(['Average power: ' num2str(avg)]);

                        % Setting data buffer to empty for next second:
                        data1s = [];
                    end

                otherwise    % Reading the package from buffer for other types:
                    data = read(con, hdr.size - header_size);
            end
        end
    catch
        er = lasterror;
        disp(er.message);
    end
end

% Closing the connection:
clear con

%% Additional functions
% Reading the message header:
function hdr = ReadHeader(con)
% con    tcpip connection object

% Defining a struct for the header:
hdr = struct('uid',[],'size',[],'type',[]);

% Reading id, size, and type of the message:
hdr.uid = read(con, 16);
hdr.size = read(con, 1, 'uint32');
hdr.type = read(con, 1, 'uint32');


% Reading the start message:
function props = ReadStartMessage(con, hdr)
% con    tcpip connection object
% hdr    message header
% props  returned EEG properties

% Defining a struct for the EEG properties:
props = struct('channelCount',[],'samplingInterval',[],'resolutions',[],...
    'channelNames',[]);

% Reading EEG properties:
props.channelCount = read(con, 1, 'uint32');
props.samplingInterval = read(con, 1, 'double');
props.resolutions = read(con,props.channelCount, 'double');
allChannelNames = read(con, hdr.size-36-props.channelCount*8);
props.channelNames = SplitChannelNames(allChannelNames);


% Reading a data message:
function [datahdr, data, markers] = ReadDataMessage(con, hdr, props)
% con       tcpip connection object
% hdr       message header
% props     EEG properties
% datahdr   data header with information on datalength and number of markers
% data      data as one dimensional arry
% markers   markers as array of marker structs

% Defining data header struct and reading data header:
datahdr = struct('block',[],'points',[],'markerCount',[]);
datahdr.block = read(con, 1, 'uint32');
datahdr.points = read(con, 1, 'uint32');
datahdr.markerCount = read(con, 1, 'uint32');

% Reading data in float format:
data = read(con, props.channelCount*datahdr.points, 'single');

% Defining markers struct and reading markers:
markers = struct('size',[],'position',[],'points',[],'channel',[],...
    'type',[],'description',[]);
for m = 1:datahdr.markerCount
    marker = struct('size',[],'position',[],'points',[],'channel',[],...
        'type',[],'description',[]);

    % Reading integer information of markers:
    marker.size = read(con, 1, 'uint32');
    marker.position = read(con, 1, 'uint32');
    marker.points = read(con, 1, 'uint32');
    marker.channel = read(con, 1, 'int32');

    % Type and description of markers are zero-terminated char arrays
    % of unknown length
    c = read(con, 1);
    while c ~= 0
        marker.type = [marker.type c];
        c = read(con, 1);
    end
    marker.type = char(marker.type);

    c = read(con, 1);
    while c ~= 0
        marker.description = [marker.description c];
        c = read(con, 1);
    end
    marker.description = native2unicode(marker.description, "UTF-8");

    % Adding marker to array:
    markers(m) = marker;
end


% Helper function for channel name splitting, used by function
% ReadStartMessage for extraction of channel names
function channelNames = SplitChannelNames(allChannelNames)
% allChannelNames   all channel names together in an array of char
% channelNames      channel names splitted in a cell array of strings

% Cell array to return
channelNames = {};

% Helper for actual name in loop
name = [];

% Looping over all chars in array:
for i = 1:length(allChannelNames)
    if allChannelNames(i) ~= 0
        % if not a terminating zero, add char to actual name
        name = [name allChannelNames(i)];
    else
        % add name to cell array and clear helper for reading next name
        channelNames = [channelNames {name}];
        name = [];
    end
end

