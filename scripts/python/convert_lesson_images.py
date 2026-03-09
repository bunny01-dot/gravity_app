from PIL import Image
import os
import glob

# Define image names and directories
direct_indirect_images = [
    "direct_indirect_hook_square",
    "tense_backshift_square", 
    "pronoun_changes_square",
    "time_place_changes_square",
    "question_indirect_square",
    "commands_indirect_square",
    "speech_reference_square"
]

future_continuous_images = [
    "future_continuous_hook",
    "future_continuous_formation",
    "future_continuous_positive",
    "future_continuous_negative",
    "future_continuous_questions",
    "future_continuous_time",
    "future_continuous_uses",
    "future_continuous_vs_simple",
    "future_continuous_reference"
]

brain_dir = r"C:\Users\HAPPY\.gemini\antigravity\brain\d35fd96c-6560-468b-8d81-3fb9a5fe9cd6"
target_dir_direct = r"e:\Apps\gravity_app\assets\Lessons\Lesson_Direct_Indirect_Speech"
target_dir_future = r"e:\Apps\gravity_app\assets\Lessons\Lesson_03_Tense_Present"

def convert_and_move(image_names, target_dir):
    """Convert PNG to WebP and move to target directory"""
    converted_count = 0
    
    for img_name in image_names:
        # Find PNG file in brain directory
        pattern = os.path.join(brain_dir, f"{img_name}*.png")
        png_files = glob.glob(pattern)
        
        if png_files:
            png_file = png_files[0]
            webp_name = f"{img_name}.webp"
            output_path = os.path.join(target_dir, webp_name)
            
            try:
                # Open and convert to WebP
                img = Image.open(png_file)
                img.save(output_path, 'WEBP', quality=85)
                print(f"✅ Converted: {webp_name}")
                converted_count += 1
            except Exception as e:
                print(f"❌ Error converting {img_name}: {e}")
        else:
            print(f"⚠️ Not found: {img_name}")
    
    return converted_count

print("Converting Direct & Indirect Speech images...")
direct_count = convert_and_move(direct_indirect_images, target_dir_direct)

print("\nConverting Future Continuous images...")
future_count = convert_and_move(future_continuous_images, target_dir_future)

print(f"\n✅ Total converted: {direct_count + future_count} images")
print(f"   - Direct & Indirect: {direct_count}/7")
print(f"   - Future Continuous: {future_count}/9")
