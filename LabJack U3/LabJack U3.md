# Analog Input with LabJack U3 

This guide describes standard procedures for receiving *Analog Input* using the LabJack U3 (https://labjack.com/products/u3-hv) in PsychoPy<br><br>  

## Prerequites 

These steps have already been installed on the 2056A and 2056B Stim computers

1. Install the LabJack UD Software Windows Installer Package 
   (https://support.labjack.com/docs/ud-software-installer-downloads-u3-u6-ue9)

2. Install the LabJack Support (LabJackPython) plugin via PsychoPy → Tools → Plugin/Package Manager  


## Basic Analog Input Template

```python
import u3       # The LabJack Support plugin needs to be installed in PsychoPy
import time

# --- Open LabJack U3 ---
d = u3.U3()
d.configIO(FIOAnalog=15) # set up the first 4 FIOs as analog (00001111)

print("Recording AIN0 for 5 seconds at 20 Hz...") # a higher sampling rate may reduce the performance of general PsychoPy functions

start_time = time.time()

SAMPLE_RATE = 0.05  # 20 Hz sampling (1 / 0.05)

while time.time() - start_time < 5:
    value = d.getAIN(0)            # analog input (e.g., hand dynamometer) is connected to CH 0
    print(f"AIN0: {value:.3f} V")  # print every sample at 20 Hz
    time.sleep(SAMPLE_RATE)

d.close()
print("Finished recording.")
```
