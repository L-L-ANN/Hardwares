# Event Triggering with Parallel Port  

This guide describes standard procedures for sending *Event Triggers* using the parallel port in PsychoPy

Basic Trigger Template
```python
from psychopy import parallel
import time

# Verify address on each stimulus computer
port = parallel.ParallelPort(address=0xCFF0)

# Always reset lines before starting
port.setData(0)

def send_trigger(value, duration=0.05):
    # value : Trigger value (0–255; 8-bit binary pattern; 00000000-11111111)
    # duration Pulse length in seconds (default = 50 ms)
    port.setData(value)
    time.sleep(duration)
    port.setData(0)  # Always reset to zero

send_trigger(1)   # Event type 1 (00000001)
time.sleep(1.0)
send_trigger(2)   # Event type 2 (00000010)
time.sleep(1.0)
send_trigger(4)   # Event type 3 (00000100)
time.sleep(1.0)

# --- Using win.callOnFlip for precise timing ---
# Typical monitors refresh at ~60 Hz (~16.67 ms per frame)
# If you send triggers using time.sleep() alone, the exact timing may vary due to CPU delays.
# win.callOnFlip schedules a function (e.g., sending a parallel port trigger) to execute
# exactly at the next screen refresh (the moment the stimulus appears).
# This ensures precise synchronization between visual stimulus onset and EEG recording.
  
# Create a PsychoPy window and stimulus
win = visual.Window([800,600], color=[0,0,0])
stim = visual.TextStim(win, text="Testing Event Maker", color=[1,1,1])

trigger_value = 8  # Event type 8

# Schedule the trigger to occur exactly at the next screen flip
win.callOnFlip(port.setData, trigger_value)

# Draw stimulus and flip the screen
stim.draw()
win.flip()  # <-- trigger is sent at this exact flip

# Wait a short pulse and reset the port
core.wait(0.05)
port.setData(0)  # Reset lines

# Close window
win.close()
core.quit()

```
