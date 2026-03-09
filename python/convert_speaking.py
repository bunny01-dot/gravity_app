import os
from PIL import Image
import glob

source_dir = r"C:\Users\HAPPY\.gemini\antigravity\brain\124c2193-6a0c-4be3-bd9c-e0617c5ec806"

# Dictionary mapping base filename without extension to its target directory and final filename
targets = {
    "past_perfect_speaking_square": {
        "dir": r"e:\Apps\gravity_app\assets\Lessons\Lesson_04_Tense_Past\03_Past_Perfect",
        "name": "past_perfect_speaking_square.webp"
    },
    "speaking_evidence_1": {
        "dir": r"e:\Apps\gravity_app\assets\Lessons\Lesson_03_Tense_Present\04_Perfect_Continuous_Present",
        "name": "speaking_evidence_1.webp"
    }
}

png_files = glob.glob(os.path.join(source_dir, "*.png"))

for png_path in png_files:
    base_name = os.path.basename(png_path)
    
    # Check which target it belongs to
    for key, target_info in targets.items():
        if base_name.startswith(key):
            target_dir = target_info["dir"]
            final_name = target_info["name"]
            
            if not os.path.exists(target_dir):
                os.makedirs(target_dir)

            target_path = os.path.join(target_dir, final_name)
            print(f"Converting {png_path} to {target_path}")
            
            with Image.open(png_path) as img:
                img.save(target_path, "WEBP", quality=85)
            
            # Optionally remove PNG after successful conversion
            # os.remove(png_path)

print("Done!")
