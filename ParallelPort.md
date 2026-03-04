# Event Triggering with Parallel Port  

This guide describes standard procedures for sending *Event triggers* using the parallel port in PsychoPy

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
