import cv2
import textwrap

build_info = cv2.getBuildInformation()
print(build_info)

print("OpenCV:", cv2.__version__)
print("CUDA devices:", cv2.cuda.getCudaEnabledDeviceCount())
print("FFmpeg:", "YES" if "FFMPEG: YES" in cv2.getBuildInformation() else "NO")

