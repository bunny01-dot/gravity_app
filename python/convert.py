import os
from PIL import Image
import glob

source_dir = r"C:\Users\HAPPY\.gemini\antigravity\brain\124c2193-6a0c-4be3-bd9c-e0617c5ec806"
target_dir = r"e:\Apps\gravity_app\assets\Lessons\Lesson_Punctuation"

if not os.path.exists(target_dir):
    os.makedirs(target_dir)

png_files = glob.glob(os.path.join(source_dir, "*.png"))

for png_path in png_files:
    base_name = os.path.basename(png_path)
    # The name is something like '4_enders_square_1772818647923.png'
    # we need to remove '_timestamp'
    parts = base_name.replace('.png', '').split('_')
    
    # Check if last part is a digit (timestamp)
    if len(parts) > 1 and parts[-1].isdigit() and len(parts[-1]) > 5:
        final_name = '_'.join(parts[:-1]) + ".webp"
    else:
        final_name = base_name.replace('.png', '.webp')

    target_path = os.path.join(target_dir, final_name)
    print(f"Converting {png_path} to {target_path}")
    
    with Image.open(png_path) as img:
        img.save(target_path, "WEBP", quality=85)
        
print("Done!")
