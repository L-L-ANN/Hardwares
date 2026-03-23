import u3
import time
import matplotlib.pyplot as plt

# --- Open LabJack U3 ---
d = u3.U3()
d.configIO(FIOAnalog=15)

# --- Plot setup ---
plt.ion()
fig, ax = plt.subplots()
line, = ax.plot([], [], lw=2)
ax.set_xlim(0, 10)
ax.set_ylim(-2, 5)
ax.set_xlabel("Time (seconds)")
ax.set_ylabel("Voltage (V)")
ax.set_title("LabJack U3 AIN0 - Real-Time Recording")

# show window immediately
plt.show(block=False)

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
record_duration = 10

# --- Timing ---
SAMPLE_RATE = 0.05
PLOT_UPDATE_RATE = 0.1

next_sample_time = start_time
last_plot_time = start_time

print(f"Recording AIN0 in real-time at {1/SAMPLE_RATE:.0f} Hz sampling...")

while True:
    now = time.time()
    current_time = now - start_time

    if current_time > record_duration:
        break

    # --- Sample ---
    if now >= next_sample_time:
        value = d.getAIN(0)
        timestamps.append(current_time)
        values.append(value)
        next_sample_time += SAMPLE_RATE

    # Keep only last 10 seconds
    while timestamps and timestamps[0] < current_time - 10:
        timestamps.pop(0)
        values.pop(0)

    # --- Plot update ---
    if now - last_plot_time >= PLOT_UPDATE_RATE:
        line.set_data(timestamps, values)

        if values:
            max_text.set_text(f"Max Voltage: {max(values):.2f} V")
            min_text.set_text(f"Min Voltage: {min(values):.2f} V")

        # (force real-time update)
        fig.canvas.draw()
        fig.canvas.flush_events()

        last_plot_time = now

# --- Cleanup ---
d.close()
plt.ioff()
plt.show()

print("Finished recording.")