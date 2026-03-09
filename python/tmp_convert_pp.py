import os
import glob
from PIL import Image

src_dir = r"C:\Users\HAPPY\.gemini\antigravity\brain\52918bcc-cdda-4882-ac46-9bb5b0b24aa2"
dest_dir = r"e:\Apps\gravity_app\assets\Lessons\Lesson_04_Tense_Past\05_Past_Perfect"

os.makedirs(dest_dir, exist_ok=True)

files = [
    "ravi_before_school_square",
    "past_perfect_timeline_square",
    "had_pastpart_table_square",
    "ravi_morning_sequence_square",
    "before_after_by_square",
    "past_perfect_neg_questions_square",
    "pp_vs_past_simple_square",
    "past_perfect_quiz_square",
    "past_perfect_speaking_square"
]

for base_name in files:
    pattern = os.path.join(src_dir, f"{base_name}*.png")
    matches = glob.glob(pattern)
    if matches:
        latest_file = max(matches, key=os.path.getctime)
        img = Image.open(latest_file)
        dest_path = os.path.join(dest_dir, f"{base_name}.webp")
        img.save(dest_path, "WEBP", quality=85)
        print(f"Converted {latest_file} to {dest_path}")
    else:
        print(f"File not found for {base_name}")
