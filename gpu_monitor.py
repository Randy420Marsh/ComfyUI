import pynvml
import matplotlib.pyplot as plt
import time
import collections

# Configuration
GPU_INDEX = 0  # Change this if you have multiple GPUs and want to monitor a different one (0 is usually the primary)
INTERVAL = 2.0 # Time in seconds between readings (reduced for potentially smoother updates)
MAX_POINTS = 200 # Maximum number of data points to show on the graph (increased to show more history)

# Data storage
gpu_memory_usage_mb = collections.deque(maxlen=MAX_POINTS)
time_points = collections.deque(maxlen=MAX_POINTS)

# Setup the plot
plt.style.use('seaborn-v0_8-darkgrid') # Optional: use a nice style
fig, ax = plt.subplots()
ax.set_title(f'GPU {GPU_INDEX} Memory Usage (MB)')
ax.set_xlabel('Time (s)')
ax.set_ylabel('Memory Used (MB)')

# Enable interactive plot updates
plt.ion()

# Create the line object early
line, = ax.plot([], [], lw=2)

# Variables for time tracking
start_time = time.time()

try:
    # Initialize NVML
    pynvml.nvmlInit()
    handle = pynvml.nvmlDeviceGetHandleByIndex(GPU_INDEX)
    gpu_name = pynvml.nvmlDeviceGetName(handle) # Corrected line

    total_memory_bytes = pynvml.nvmlDeviceGetMemoryInfo(handle).total
    total_memory_mb = total_memory_bytes / (1024**2)
    ax.set_title(f'{gpu_name} (GPU {GPU_INDEX}) Memory Usage (MB) - Total: {total_memory_mb:.0f} MB')
    ax.set_ylim(0, total_memory_mb * 1.1) # Set Y-limit based on total GPU memory

    print(f"Monitoring GPU {GPU_INDEX} ({gpu_name}). Press Ctrl+C to stop.")

    # Monitoring loop
    while True:
        # Get memory info
        info = pynvml.nvmlDeviceGetMemoryInfo(handle)
        used_memory_bytes = info.used
        used_memory_mb = used_memory_bytes / (1024**2) # Convert bytes to MB

        # Get current time relative to start
        current_time = time.time() - start_time

        # Append data
        time_points.append(current_time)
        gpu_memory_usage_mb.append(used_memory_mb)

        # Print current usage to console (for debugging)
        print(f"Time: {current_time:.2f}s, Used Memory: {used_memory_mb:.2f} MB")


        # Update the plot data
        line.set_data(list(time_points), list(gpu_memory_usage_mb))

        # Adjust plot limits dynamically
        ax.set_xlim(max(0, current_time - MAX_POINTS * INTERVAL), current_time + INTERVAL) # Add small buffer


        # --- Use plt.pause() for smoother updates ---
        plt.pause(INTERVAL * 0.01) # Pause for a small fraction of the interval to allow updates

        # Wait for the rest of the interval
        time.sleep(INTERVAL - (INTERVAL * 0.01))
        if INTERVAL - (INTERVAL * 0.01) < 0: # Handle cases with very small intervals
             time.sleep(0)


except pynvml.NVMLError as err:
    print(f"NVML Error: {err}")
except KeyboardInterrupt:
    print("\nMonitoring stopped by user.")
except Exception as e:
    print(f"An error occurred: {e}")
    # Keep the plot window open if an unexpected error occurs, for inspection
    plt.ioff()
    plt.show()

finally:
    # Shutdown NVML
    try:
        pynvml.nvmlShutdown()
        print("NVML shutdown.")
    except pynvml.NVMLError as err:
        print(f"Error during NVML shutdown: {err}")

    # Close the plot window if it's still open
    if plt.fignum_exists(fig.number):
         plt.close(fig)
