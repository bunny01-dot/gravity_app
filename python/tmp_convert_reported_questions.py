import os
from PIL import Image

def convert_and_move(src_path, dest_dir, dest_filename):
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
    
    dest_path = os.path.join(dest_dir, dest_filename)
    
    try:
        with Image.open(src_path) as img:
            # Convert to WebP
            img.save(dest_path, "WEBP", quality=80)
        print(f"Successfully converted and saved to {dest_path}")
    except Exception as e:
        print(f"Error processing {src_path}: {e}")

images_to_process = [
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\reported_questions_backshift_1772893315515.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_Reported_Questions", "reported_questions_backshift.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\reported_questions_commands_robot_1772893396056.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_Reported_Questions", "reported_questions_commands_robot.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\reported_questions_direct_indirect_1772893299970.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_Reported_Questions", "reported_questions_direct_indirect.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\reported_questions_if_whether_mark_1772893378150.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_Reported_Questions", "reported_questions_if_whether_mark.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\reported_questions_library_mixed_1772893426606.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_Reported_Questions", "reported_questions_library_mixed.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\reported_questions_pronouns_1772893332236.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_Reported_Questions", "reported_questions_pronouns.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\reported_questions_speaking_mic_1772893445967.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_Reported_Questions", "reported_questions_speaking_mic.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\reported_questions_time_place_signpost_1772893361503.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_Reported_Questions", "reported_questions_time_place_signpost.webp"),
]

for src, dest_dir, dest_file in images_to_process:
    convert_and_move(src, dest_dir, dest_file)
