from psychopy import parallel
import time

# Replace with your actual parallel port address 
# (0xCFF0 is for EEG1 & EEG2 Stim Computers)
port = parallel.ParallelPort(address=0xCFF0)

# IMPORTANT: Reset all data lines to 0 (low) at the beginning.
# The parallel port does NOT automatically reset lines between triggers.
port.setData(0)

def send_trigger(value, duration=0.05):
    """
    Send a parallel port trigger.
    Parameters
    ----------
    value : int
        Trigger value (0–255; 8-bit binary pattern).
        Example: 1 = 00000001 (Pin 2 high)
    duration : float
        Pulse length in seconds (default = 50 ms).
        Very short pulses (<10 ms) may be missed by the EEG system.
    """
    port.setData(value)
    time.sleep(duration)
    port.setData(0)  # Always reset lines to 0 after pulse

print("Sending trigger")

# Example trigger
send_trigger(1)

print("Done")

# ------------------------------------------------------------
# Optional: Control individual pins directly (advanced/debugging)
# ------------------------------------------------------------
# setPin(pinNumber, state)
# Pin numbers refer to PHYSICAL parallel port pins.
# Data output pins are 2–9 (DO0–DO7).
#
# Example:
# port.setPin(3, 1)  # Set physical pin 3 HIGH
# port.setPin(3, 0)  # Set physical pin 3 LOW
#
# See: https://en.wikipedia.org/wiki/Parallel_port

# ------------------------------------------------------------
# Testing
# ------------------------------------------------------------
# The Parallel Port Tester program is useful for verifying output lines.
# It is already installed on EEG1 & EEG2 Stim Computers.
# https://www.downtowndougbrown.com/2013/06/parallel-port-tester/