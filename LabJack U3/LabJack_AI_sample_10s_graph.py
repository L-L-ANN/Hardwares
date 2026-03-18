import u3       # The LabJack Support plugin needs to be installed in PsychoPy
import time
import matplotlib.pyplot as plt

# --- Open LabJack U3 ---
d = u3.U3()
d.configIO(FIOAnalog=15)  # first 4 FIOs analog (00001111)

# --- Plot setup ---
plt.ion()                # for real-time plotting 
fig, ax = plt.subplots()
line, = ax.plot([], [], lw=2)
ax.set_xlim(0, 10)       # fixed x-axis for 10 seconds
ax.set_ylim(-2, 5)       # fixed y-axis
ax.set_xlabel("Time (seconds)")
ax.set_ylabel("Voltage (V)")
ax.set_title("LabJack U3 AIN0 - Real-Time Recording")

# Max/min voltage display
max_text = ax.text(0.95, 0.95, '', transform=ax.transAxes, 
                   ha='right', va='top', fontsize=10, 
                   bbox=dict(facecolor='white', alpha=0.7))
min_text = ax.text(0.05, 0.95, '', transform=ax.transAxes, 
                   ha='left', va='top', fontsize=10, 
                   bbox=dict(facecolor='white', alpha=0.7))

# --- Data storage ---
timestamps = []
values = []

start_time = time.time()
record_duration = 10  # seconds

# --- 20 Hz sampling & plotting ---
SAMPLE_RATE = 0.05      # 20 Hz sampling (1 / 0.05)
PLOT_UPDATE_RATE = 0.05 # 20 Hz plot updates

last_plot_time = 0

print(f"Recording AIN0 in real-time at {1/SAMPLE_RATE:.0f} Hz sampling...")

while True:
    current_time = time.time() - start_time
    if current_time > record_duration:
        break

    # --- Sample data ---
    value = d.getAIN(0)
    timestamps.append(current_time)
    values.append(value)

    # Keep only last 10 seconds
    while timestamps and timestamps[0] < current_time - 10:
        timestamps.pop(0)
        values.pop(0)

    # --- Update plot at fixed rate ---
    if current_time - last_plot_time >= PLOT_UPDATE_RATE:
        line.set_data(timestamps, values)
        if values:
            max_text.set_text(f"Max Voltage: {max(values):.2f} V")
            min_text.set_text(f"Min Voltage: {min(values):.2f} V")
        plt.pause(0.001)
        last_plot_time = current_time

    time.sleep(SAMPLE_RATE)  # maintain sampling rate

# --- Close device ---
d.close()
plt.ioff()
plt.show()
print("Finished recording.")