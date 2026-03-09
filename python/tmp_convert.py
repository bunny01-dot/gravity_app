import os
import glob
from PIL import Image

src_dir = r"C:\Users\HAPPY\.gemini\antigravity\brain\52918bcc-cdda-4882-ac46-9bb5b0b24aa2"
dest_dir = r"e:\Apps\gravity_app\assets\Lessons\Lesson_04_Tense_Past\04_Past_Perfect_Continuous"

os.makedirs(dest_dir, exist_ok=True)

files = [
    "ravi_been_studying_square",
    "past_perfect_cont_timeline_square",
    "had_been_verb_table_square",
    "ravi_study_duration_square",
    "for_since_past_perfect_square",
    "evidence_duration_square",
    "past_perfect_cont_qa_square",
    "past_perfect_cont_quiz_square",
    "past_perfect_cont_speaking_square"
]

for base_name in files:
    pattern = os.path.join(src_dir, f"{base_name}*.png")
    matches = glob.glob(pattern)
    if matches:
        # Take the most recent one if multiple
        latest_file = max(matches, key=os.path.getctime)
        img = Image.open(latest_file)
        dest_path = os.path.join(dest_dir, f"{base_name}.webp")
        img.save(dest_path, "WEBP", quality=85)
        print(f"Converted {latest_file} to {dest_path}")
    else:
        print(f"File not found for {base_name}")
