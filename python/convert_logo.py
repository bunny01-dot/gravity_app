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

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # Convert BGR to RGB
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    # Resize proportionally to width 384 while preserving 16:9 aspect ratio
    img = Image.fromarray(frame_rgb).resize((384, 216), Image.Resampling.LANCZOS)
    frames.append(img)

cap.release()

if frames:
    print(f"Saving {len(frames)} frames to animated webp...")
    # Get FPS
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    cap.release()
    duration = int(1000 / (fps if fps > 0 else 30))
    
    frames[0].save(
        output_path,
        format="WEBP",
        save_all=True,
        append_images=frames[1:],
        duration=duration,
        loop=0,
        quality=80
    )
    print("Optimization complete: Saved as", output_path)
else:
    print("No frames extracted.")
