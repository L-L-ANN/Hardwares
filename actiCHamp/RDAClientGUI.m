%
% RDAClientGUI.m  MATLAB RDA Client with GUI
%
% Demonstration file for implementing a simple MATLAB client for the
% RDA tcpip interface of BrainVision Recorder.
% It reads all information of the recorded EEG, displays a channel of
% choice and its Fourier transform and prints EEG and marker information
% to the MATLAB console.
% In addition, it shows the accumulated average of epochs following a
% marker of choice.
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

function RDAGUI()

% Global definitions for easy use in other functions:
global editHost         % Host Name or IP edit control
global editChannel      % Channel edit control
global editMarker       % Marker edit control
global axTime           % Time domain axis
global axFreq           % Frequency domain axis
global axERP            % Time domain axis for averaged ERPs
global ERP              % Required to collect ERP epochs
global ERPOn            % Required to collect ERP epochs
global ERPMean          % Required to collect ERP epochs

ERP = [];
ERPMean = [];
ERPOn = false;

% Creating and hiding the GUI figure as it is being constructed:
f = figure('Visible','off',...
    'CloseRequestFcn',{@RDA_CloseRequestFcn},'Position',[0,0,750,700]);

% Constructing the controls:
lblHost = uicontrol('Style','text','String','Host:',...
    'BackgroundColor',get(f,'Color'),'Position',[25,675,50,16]);
editHost = uicontrol('Style','edit','String','127.0.0.1',...
    'Position',[75,675,150,16]);
lblChannel = uicontrol('Style','text','String','Channel:',...
    'BackgroundColor',get(f,'Color'),'Position',[250,675,50,16]);
editChannel = uicontrol('Style','edit','String','2',...
    'Position',[300,675,50,16]);
lblMarker = uicontrol('Style','text','String','Marker:',...
    'BackgroundColor',get(f,'Color'),'Position',[375,675,50,16]);
editMarker = uicontrol('Style','edit','String','S  1',...
    'Position',[425,675,50,16]);
btConnect = uicontrol('Style','pushbutton','String','Connect',...
    'Position',[525,675,100,16],'Callback',{@btConnect_Callback});

% Constructing the axes to display time and frequency domain data:
axTime = axes('Units','Pixels','Position',[60,265,650,180]);
axFreq = axes('Units','Pixels','Position',[60,50,650,180]);
axERP = axes('Units','Pixels','Position',[60,480,650,180]);

% Assigning the GUI a name to appear in the window title:
set(f,'Name','Brain Vision RDA Client for MATLAB');
% Moving the GUI to the center of the screen and making it visible:
movegui(f,'center');
set(f,'Visible','on');


%% Closing request handler: executes when user attempts to close the GUI
function RDA_CloseRequestFcn(hObject, eventdata)

selection = questdlg(['Close MATLAB RDA Client?'],['Closing...'],...
    'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end
try
    CloseConnection();
catch
end
delete(hObject);


%% Connection handling functions

% Pushbutton handler: executes on button press in btConnect:
function btConnect_Callback(hObject, eventdata)

text = get(hObject, 'String');
if strcmp(text, 'Connect')
    OpenConnection();
    set(hObject,'String','Disconnect');
else
    CloseConnection();
    set(hObject,'String','Connect');
end

% Opening the connection:
function OpenConnection()

% Global definitions for easy use in other functions:
global readTimer        % Timer object for reading data from tcpip socket
global con              % TCPIP connection
global editHost         % Host Name or IP edit control

recorderip = get(editHost, 'String');

% Establish connection to RDA server 32-bit:
con=tcpclient(recorderip, 51244);

% Define and start timer for reading from socket
readTimer = timer('TimerFcn', @RDATimerCallback, 'Period', .01, ...
    'ExecutionMode', 'fixedSpacing');
start(readTimer);

% Connection closing
function CloseConnection()

% Global definitions for easy use in other functions:
global readTimer        % Timer object for reading data from tcpip socket
global con              % TCPIP connection

stop(readTimer);
delete(con);

disp('Connection closed');


%% Callback function for RDA Timer

% After a connection is established, this is the main data processing
% function.

function RDATimerCallback(hObject, eventdata)

% Global definitions for easy use in other functions:
global con              % TCPIP connection
global lastBlock        % Number of last block for overflow test
global props            % EEG Properties
global readTimer        % Timer object
global data1s           % EEG data of the last recorded second
global editChannel      % Channel edit control
global editMarker       % Marker edit control
global axTime           % Time domain axis
global axFreq           % Frequency domain axis
global axERP            % Time domain axis for averaged ERPs
global ERP              % Required to collect ERP epochs
global ERPOn            % Required to collect ERP epochs
global ERPMean          % Required to collect ERP epochs
global hTime            % Time domain graph handle
global hFreq            % Frequency domain graph handle
global hERP             % Time domain graph handle for averaged ERPs

% Reading the selected channel and marker information:
channel_num = str2double(get(editChannel, 'String'));
marker_description = get(editMarker, 'String');

% Setting axes limits and labels; adjust if needed, or comment if
% autoscaling is preferred:
set(axTime,'YLim',[-20, 20]);
set(axERP,'YLim',[-10, 10]);
set(axFreq,'YLim',[0, 1000]);

set(get(axERP,'Xlabel'),'String','samples');
set(get(axTime,'Xlabel'),'String','samples');
set(get(axFreq,'Xlabel'),'String','f (Hz)');


% Reading the channel name and using it as y-axis label:
try
    label = append(props.channelNames(channel_num), " (uV)");
    set(get(axERP,'Ylabel'),'String', strcat("EEG ",label), 'Interpreter', 'none');
    set(get(axTime,'Ylabel'),'String', strcat("EEG ",label), 'Interpreter', 'none');
    set(get(axFreq,'Ylabel'),'String', strcat("FFT ",label), 'Interpreter', 'none');
catch
    set(get(axERP,'Ylabel'),'String','EEG (uV)');
    set(get(axTime,'Ylabel'),'String','EEG (uV)');
    set(get(axFreq,'Ylabel'),'String','FFT (uV)');
end

% --- Main reading loop ---
header_size = 24;
try
    % Continue as long as there is data available:
    while con.NumBytesAvailable >= 24

        % Reading header of RDA message
        hdr = ReadHeader(con);

        % Performing action depending on the type of the data package:
        switch hdr.type
            case 1       % Start; Setup information like EEG properties
                disp('Starting RDA');
                % Reading and displaying EEG properties:
                props = ReadStartMessage(con, hdr);
                disp(props);

                % Resetting block counter to check overflows
                lastBlock = -1;

                % Filling data buffer with zeros and plotting for the 
                % first time to get handles (in chunks of seconds):
                data1s = zeros(props.channelCount,1000000/...
                    round(props.samplingInterval));
                ERP = [];
                ERPMean = [];

                EEG_FFT = abs(fft(data1s(1,:)));
                hTime = plot(axTime, data1s(1,:));                
                hFreq = plot(axFreq, EEG_FFT(1:int32(length(EEG_FFT)/2)));
                hERP = plot(axERP, data1s(1,:));               

            case 3       % Stop message
                disp('Stop');
                data = read(con, hdr.size - header_size);

            case 4       % 32-bit data block
                % Reading data and markers from the data block:
                [datahdr, data, markers] = ReadDataMessage(con, hdr);

                % Checking tcpip buffer overflow:
                if lastBlock ~= -1 && datahdr.block > lastBlock + 1
                    disp(['******* Overflow with ' int2str(datahdr.block...
                        -lastBlock) ' blocks ******']);
                end
                lastBlock = datahdr.block;

                % Printing marker information to MATLAB console:
                if datahdr.markerCount > 0
                    for m = 1:datahdr.markerCount
                        disp(markers(m));
                    end
                    % If the marker matches the selected type, use the
                    % following epoch for ERP averaging:
                    if strcmp(markers(m).description, marker_description)
                        ERPOn = true;
                    end
                end

                % Process EEG data (extract last recorded second):
                EEG = reshape(data, props.channelCount, length(data)/...
                    props.channelCount);
                for k = 1:props.channelCount
                    EEG(k,:) = EEG(k,:) * props.resolutions(k);
                end
                data1s = [data1s EEG];
                
                % Collecting data for the ERP averaging only when the
                % marker was dectected previously:
                if ERPOn
                    ERP = [ERP EEG(channel_num,:)];
                end
                   
                % Constantly keeping the currently last second in data1s:
                if size(data1s,2) > 1000000/round(props.samplingInterval)
                    data1s = data1s(:, size(data1s,2)-1000000/...
                        round(props.samplingInterval)+1:size(data1s,2));
                end

                % Plotting the evolving average of the epoch after the
                % selected marker:
                if size(ERP,2) >= 1000000/round(props.samplingInterval)
                    ERPOn = false;
                    ERP = ERP-mean(ERP);
                    ERPMean = [ERPMean; ERP];
                    set(hERP,'YData', mean(ERPMean,1));
                    ERP = [];
                end

                % Plotting the chosen channel (with DC offset removed):
                tmp = data1s(channel_num,:)-mean(data1s(channel_num,:));
                set(hTime,'YData', tmp);

                % Performing and plotting fast fourier transform (FFT):
                EEG_FFT = abs(fft(data1s(1,:)));
                set(hFreq, 'YData', EEG_FFT(1:int32(length(EEG_FFT)/2)));
               
            otherwise    % Read the package from buffer for other types:
                data = read(con, hdr.size-header_size);
        end
    end
catch
    er = lasterror;
    disp(er.message);
    clear con
end

%% Additional functions 
% Reading the message header:
function hdr = ReadHeader(con)
% con       tcpip connection object
% hdr       message header

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
function [datahdr, data, markers] = ReadDataMessage(con, hdr)
% con       tcpip connection object
% hdr       message header
% datahdr   data header with information on datalength and number of markers
% data      data as one dimensional arry
% markers   markers as array of marker structs

% Global definitions for easy use in other functions:
global props           % EEG Properties

% Defining data header struct and read data header:
datahdr = struct('block',[],'points',[],'markerCount',[]);
datahdr.block = read(con, 1, 'uint32');
datahdr.points = read(con, 1, 'uint32');
datahdr.markerCount = read(con, 1, 'uint32');

% Reading data in float format:
data = read(con, props.channelCount * datahdr.points, 'single');

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

    % Adding marker to array
    markers(m) = marker;
end


% Helper function for channel name splitting, used by function
% ReadStartMessage for extraction of channel names:
function channelNames = SplitChannelNames(allChannelNames)
% allChannelNames   all channel names together in an array of char
% channelNames      channel names split in a cell array of strings

% Cell array to return
channelNames = {};

% Helper for actual name in loop
name = [];

% Looping over all chars in array:
for i = 1:length(allChannelNames)
    if allChannelNames(i) ~= 0
        % If not a terminating zero, add char to actual name
        name = [name allChannelNames(i)];
    else
        % Add name to cell array and clear helper for reading next name
        channelNames = [channelNames char(name)];
        name = [];
    end
end

