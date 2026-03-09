from PIL import Image
import os
import glob

# Define image names
images_to_process = [
    "ravi_fut_perf_cont_square",
    "duration_to_future_square",
    "will_have_been_table_square",
    "ravi_study_marathon_square",
    "for_since_future_square",
    "duration_evidence_square",
    "fut_perf_cont_qa_square",
    "future_perfects_compare_square",
    "fut_perf_cont_quiz_square",
    "fut_perf_cont_celebration_square"
]

# Configure paths
brain_dir = r"C:\Users\HAPPY\.gemini\antigravity\brain\5ce4bb3f-1d3f-41c5-838e-8a0948fb4677"
target_dir = r"e:\Apps\gravity_app\assets\Lessons\Lesson_05_Tense_Future\04_Future_Perfect_Continuous"

def convert_and_move(image_names, source_dir, dest_dir):
    """Convert PNG to WebP and move to target directory"""
    if not os.path.exists(dest_dir):
        print(f"Creating directory: {dest_dir}")
        os.makedirs(dest_dir)
        
    converted_count = 0
    
    for img_name in image_names:
        # Find PNG file in brain directory (handling unpredictable suffixes)
        pattern = os.path.join(source_dir, f"{img_name}*.png")
        png_files = glob.glob(pattern)
        
        if png_files:
            # Sort by modification time to get the latest one if multiple exist
            png_file = max(png_files, key=os.path.getmtime)
            
            webp_name = f"{img_name}.webp"
            output_path = os.path.join(dest_dir, webp_name)
            
            try:
                # Open and convert to WebP
                img = Image.open(png_file)
                img.save(output_path, 'WEBP', quality=90)
                print(f"✅ Converted: {webp_name}")
                converted_count += 1
            except Exception as e:
                print(f"❌ Error converting {img_name}: {e}")
        else:
            print(f"⚠️ Not found: {img_name}")
    
    return converted_count

print(f"Processing {len(images_to_process)} images for Future Perfect Continuous...")
count = convert_and_move(images_to_process, brain_dir, target_dir)
print(f"\n✅ Successfully processed {count}/{len(images_to_process)} images.")
