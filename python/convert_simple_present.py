import os
import glob
from PIL import Image

src_dir = r"C:\Users\HAPPY\.gemini\antigravity\brain\4a00b703-4900-4a05-bbe8-ba506bad9ec4"
dest_dir = r"e:\Apps\gravity_app\assets\Lessons\Lesson_03_Tense_Present\01_Simple_Present"

patterns = [
    "ravi_waking_up_*.png",
    "ravi_brushing_*.png",
    "ravi_eating_idli_*.png",
    "ravi_school_run_*.png",
    "boys_playing_football_*.png",
    "ravi_refuse_coffee_*.png",
    "sunny_draw_*.png",
    "studying_together_*.png",
]

for pattern in patterns:
    files = glob.glob(os.path.join(src_dir, pattern))
    if files:
        file_path = files[0]
        base_name_parts = os.path.basename(file_path).split('_')
        base_name = "_".join(base_name_parts[:-1])
        
        try:
            img = Image.open(file_path)
            dest_path = os.path.join(dest_dir, f"{base_name}.webp")
            img.save(dest_path, "WEBP", quality=85)
            print(f"Converted and saved to {dest_path}")
        except Exception as e:
            print(f"Failed to process {file_path}: {e}")
    else:
        print(f"No file found for pattern: {pattern}")
