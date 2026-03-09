import cv2
import numpy as np
from PIL import Image
import os

video_path = "assets/images/app_logo.mp4"
output_path = "assets/images/app_logo_anim.webp"

if not os.path.exists(video_path):
    print("Video not found!")
    exit(1)

cap = cv2.VideoCapture(video_path)
frames = []

width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fps = cap.get(cv2.CAP_PROP_FPS)

print(f"Original Video: {width}x{height} @ {fps}fps")

# Determine crop box. Assuming the logo is roughly in the center
# Often 16:9 videos have a central square logo. We'll take the central square.
size = min(width, height)
x_start = (width - size) // 2
y_start = (height - size) // 2

# Actually let's crop it even tighter to 80% of the center height to cut out letterboxing
crop_size = int(size * 0.9) 
c_x = width // 2
c_y = height // 2

x1 = c_x - crop_size // 2
x2 = c_x + crop_size // 2
y1 = c_y - crop_size // 2
y2 = c_y + crop_size // 2

print(f"Cropping to standard square: {crop_size}x{crop_size} at ({x1},{y1}) to ({x2},{y2})")

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # 1. Crop to central square containing logo
    cropped = frame[y1:y2, x1:x2]
    
    # 2. Convert BGR to RGB
    frame_rgb = cv2.cvtColor(cropped, cv2.COLOR_BGR2RGB)
    
    # 3. Create WebP directly without destroying the original transparent corners
    # (The logo in the MP4 might already have empty space or Flutter's ClipRRect will handle it)
    rgba = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2RGBA)
    
    # 4. Resize optimization (down to 256x256 max for performance)
    img = Image.fromarray(rgba).resize((256, 256), Image.Resampling.LANCZOS)
    frames.append(img)

cap.release()

if frames:
    print(f"Saving {len(frames)} optimized, heavily-cropped transparent frames to WebP...")
    duration = int(1000 / (fps if fps > 0 else 30))
    
    frames[0].save(
        output_path,
        format="WEBP",
        save_all=True,
        append_images=frames[1:],
        duration=duration,
        loop=0,
        quality=85,
        method=4 # higher compression effort
    )
    print("Crop complete: Saved as", output_path)
else:
    print("No frames extracted.")
