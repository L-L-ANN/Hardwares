# Event Triggering with Parallel Port  

This guide describes standard procedures for sending *Event Triggers* using the parallel port in PsychoPy

**Basic Trigger Template**
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
```

**Precise Timing Trigger Template** 

Typical monitors refresh at ~60 Hz (~16.67 ms per frame). If you send triggers using time.sleep() alone, the exact timing may vary due to CPU delays. <br>

*win.callOnFlip* schedules a function (e.g., sending a parallel port trigger) to execute
exactly at the next screen refresh (the moment the stimulus appears). 
This ensures precise synchronization between visual stimulus onset and EEG recording.

```python
from psychopy import visual, core, parallel

# --- Parallel Port Setup ---
# Verify address on each stimulus computer
port = parallel.ParallelPort(address=0xCFF0)
port.setData(0)  # Reset lines before starting

# --- Helper Function for Frame-Locked Triggers ---
def send_trigger_flip(win, port, value, pulse=0.05):
    """
    Send a parallel port trigger synchronized to the next screen flip.

    Parameters:
    win   : PsychoPy Window object
    port  : ParallelPort object
    value : Trigger value (0–255)
    pulse : Duration of the pulse in seconds (default 50 ms)
    """
    # Schedule the trigger at the next flip
    win.callOnFlip(port.setData, value)

    # Flip the window (trigger fires at this exact moment)
    win.flip()

    # Wait for the pulse duration
    core.wait(pulse)

    # Reset port to 0
    port.setData(0)

# --- Create a PsychoPy Window and Stimuli ---
win = visual.Window([800,600], color=[0,0,0])
stim = visual.TextStim(win, text="Testing Event Maker", color=[1,1,1])

# --- Example: Multiple Frame-Locked Triggers ---
trigger_values = [1, 2, 4, 8]  # Event types
for trig in trigger_values:
    stim.text = f"Trigger {trig}"
    stim.draw()                    # Draw stimulus to back buffer
    send_trigger_flip(win, port, trig)  # Flip + send trigger
    core.wait(1.0)                 # Wait 1 second between events

# --- Cleanup ---
win.close()
core.quit()
```
