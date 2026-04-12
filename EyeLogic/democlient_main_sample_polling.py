# -----------------------------------------------------------------------
# Copyright (C) 2019-2026, EyeLogic GmbH
#
# Permission is hereby granted, free of charge, to any person or
# organization obtaining a copy of the software and accompanying
# documentation covered by this license (the "Software") to use,
# reproduce, display, distribute, execute, and transmit the Software,
# and to prepare derivative works of the Software, and to permit
# third-parties to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND
# NON-INFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR ANYONE
# DISTRIBUTING THE SOFTWARE BE LIABLE FOR ANY DAMAGES OR OTHER
# LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# -----------------------------------------------------------------------

from eyelogic.ELApi import *
from sys import exit
import time

if __name__ == "__main__":

    global ELInvalidValue
    api = ELApi("Demo Client")

    resultConnect = api.connect()
    if (resultConnect != ELApi.ReturnConnect.SUCCESS):
        print("Connection to server failed. Is the server up and running?",
              flush=True)
        input('Press Enter to exit')
        exit()
    print("Successfully connected to server: {}".format(api.isConnected()),
          flush=True)

    activeScreen = api.getActiveScreen()
    print("Screen resolution: {}x{}".format(activeScreen.resolutionX,
                                            activeScreen.resolutionY))

    deviceConfig = api.getDeviceConfig()
    if (deviceConfig.deviceSerial == 0):
        print("No device connected, will exit")
        input('Press Enter to exit')
        exit()
    else:
        print("Device found: name = {}".format(deviceConfig.deviceName),
              flush=True)
        print("brandedName = {}".format(deviceConfig.brandedName),
              flush=True)
        if (deviceConfig.isDemoDevice):
            print("This is a DEMO unit for demonstration purposes only, not for sale.",
                  flush=True)
        print("framerates: {}".format(deviceConfig.frameRates),
              flush=True)

    resultTracking = api.requestTracking(0)
    if (resultTracking != ELApi.ReturnStart.SUCCESS):
        print("Start tracking failed: {}".format(resultTracking), flush=True)
        exit()

    resultCalibrate = api.calibrate(0)
    if (resultCalibrate != ELApi.ReturnCalibrate.SUCCESS):
        print("Calibration failed: {}".format(resultCalibrate), flush=True)
        input('Press Enter to exit')
        exit()

    # receive some some gaze data
    for i in range(0, 100):
        (resultNextSample, sample) = api.getNextGazeSample(1000)
        if (resultNextSample == ELApi.ReturnNextData.SUCCESS):
            if (sample.porRawX == ELInvalidValue):
                porStr = "INVALID"
            else:
                porStr = "{}, {}".format(sample.porRawX,
                                     sample.porRawY)
            print('GazeSample: time={}, index={}, POR = {}'.format(sample.timestampMicroSec,\
          sample.index, porStr))
        elif (resultNextSample == ELApi.ReturnNextData.TIMEOUT):
            print("no GazeSample received since 1s. Will exit.")
            input('Press Enter to exit')
            exit()
        elif (resultNextSample == ELApi.ReturnNextData.CONNECTION_CLOSED):
            print("Connection to server closed")
            input('Press Enter to exit')
            exit()

    api.disconnect()

    input('Press Enter to exit')
