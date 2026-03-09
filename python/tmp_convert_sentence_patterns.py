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
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\ravi_5_patterns_square_1772893571269.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_07_Sentence_Patterns", "ravi_5_patterns_square.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\5_patterns_overview_square_1772893592509.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_07_Sentence_Patterns", "5_patterns_overview_square.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\svo_ravi_eats_square_1772893608379.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_07_Sentence_Patterns", "svo_ravi_eats_square.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\sv_ravi_runs_square_1772893638778.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_07_Sentence_Patterns", "sv_ravi_runs_square.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\sva_ravi_happy_square_1772893659568.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_07_Sentence_Patterns", "sva_ravi_happy_square.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\svadv_ravi_fast_square_1772893676655.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_07_Sentence_Patterns", "svadv_ravi_fast_square.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\svn_ravi_student_square_1772893700881.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_07_Sentence_Patterns", "svn_ravi_student_square.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\pattern_detective_square_1772893716726.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_07_Sentence_Patterns", "pattern_detective_square.webp"),
    (r"C:\Users\HAPPY\.gemini\antigravity\brain\52e6000b-3c49-4c16-9296-5e10c19d18a6\mix_match_sentence_square_1772893737070.png", r"e:\Apps\gravity_app\assets\Lessons\Lesson_07_Sentence_Patterns", "mix_match_sentence_square.webp"),
]

for src, dest_dir, dest_file in images_to_process:
    convert_and_move(src, dest_dir, dest_file)
