import cv2
from PIL import Image
import os

video_path = "assets/images/Google Gemini.mp4"
output_path = "assets/images/gemini_logo_anim.webp"

if not os.path.exists(video_path):
    print("Video not found!")
    exit(1)

cap = cv2.VideoCapture(video_path)
frames = []

width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fps = cap.get(cv2.CAP_PROP_FPS)

print(f"Original Gemini Video: {width}x{height} @ {fps}fps")

# The Google Gemini video is likely 16:9 (1280x720). 
# We need to crop to a perfect center square to remove the wide margins.
size = min(width, height) # Usually 720
x_start = (width - size) // 2 
y_start = (height - size) // 2

# We can crop even a little tighter to ensure the logo is big and prominent
# 90% of the height
crop_size = int(size * 0.9)
c_x = width // 2
c_y = height // 2

x1 = c_x - crop_size // 2
x2 = c_x + crop_size // 2
y1 = c_y - crop_size // 2
y2 = c_y + crop_size // 2

print(f"Cropping to perfect tight square: {crop_size}x{crop_size} from center")

while True:
    ret, frame = cap.read()
    if not ret:
        break
        
    # Crop to the perfect center square
    cropped = frame[y1:y2, x1:x2]
    
    # Convert BGR to RGB
    frame_rgb = cv2.cvtColor(cropped, cv2.COLOR_BGR2RGB)
    
    # Resize slightly to save RAM on the animated WebP (perfect square 300x300)
    img = Image.fromarray(frame_rgb).resize((304, 304), Image.Resampling.LANCZOS)
    frames.append(img)

cap.release()

if frames:
    print(f"Saving {len(frames)} tightly cropped frames to animated webp...")
    # Perfectly match the framerate timeline 
    duration = int(1000 / fps) if fps > 0 else 41
    
    frames[0].save(
        output_path,
        format="WEBP",
        save_all=True,
        append_images=frames[1:],
        duration=duration,
        loop=0,
        quality=85,
        method=4
    )
    print("Crop complete: Saved as", output_path)
else:
    print("No frames extracted.")
