import os
import shutil

# Config: Lesson Directory -> (Subfolder with new images OR None for root), [List of Image Filenames in Order]
# Note: Paths are relative to headers or absolute.
BASE_ASSETS = r"e:\Apps\gravity_app\assets\Lessons"

lessons_config = {
    "Lesson_12_Active_Passive": {
        "source_folder": "New folder",
        "images": [
            "active_passive_hook_square.webp",
            "active_passive_structure_square.webp",
            "present_voice_square.webp",
            "past_voice_square.webp",
            "voice_reference_square.webp",
            "passive_when_square.webp",
            "voice_quiz_square.webp",
            "voice_arrow_flow_square.webp",
            "phrasal_speaking_square.webp"
        ]
    },
    "Lesson_27_Adverbs": {
        "source_folder": "New folder",
        "images": [
            "adverb_hook_square.webp",
            "5_adverb_types_square.webp",
            "manner_adverbs_square.webp",
            "frequency_adverbs_square.webp",
            "place_time_adverbs_square.webp",
            "degree_adverbs_square.webp",
            "adverb_quiz_square.webp",
            "adverb_positions_square.webp",
            "adverb_mistakes_square.webp",
            "adverb_chart_square.webp"
        ]
    },
    "Lesson_Idioms": {
        "source_folder": None, # Root
        "images": [
            "idioms_confusion_square.webp",
            "literal_vs_idiom_square.webp",
            "food_idioms_square.webp",
            "body_idioms_square.webp",
            "animal_idioms_square.webp",
            "school_idioms_square.webp",
            "emotion_idioms_square.webp",
            "idioms_speaking_square.webp"
        ]
    },
    "Lesson_Infinitives_Participles": {
        "source_folder": None,
        "images": [
            "verb_forms_hook_square.webp",
            "verb_spectrum_square.webp",
            "infinitive_purpose_square.webp",
            "bare_infinitive_square.webp",
            "present_participle_square.webp",
            "past_participle_square.webp",
            "verb_patterns_square.webp",
            "verb_forms_chart_square.webp"
        ]
    },
    "Lesson_Phrasal_Verbs": {
        "source_folder": None,
        "images": [
            "ravi_pick_up_square.webp",
            "phrasal_vs_literal_square.webp",
            "separable_inseparable_square.webp",
            "home_phrasals_square.webp",
            "school_phrasals_square.webp",
            "particle_meanings_square.webp",
            "phrasal_speaking_square.webp"
        ]
    }
}

def process_lessons():
    for lesson_dir_name, config in lessons_config.items():
        lesson_path = os.path.join(BASE_ASSETS, lesson_dir_name)
        source_subfolder = config["source_folder"]
        target_images = config["images"]
        
        # Determine source directory for new images
        if source_subfolder:
            source_dir = os.path.join(lesson_path, source_subfolder)
        else:
            source_dir = lesson_path
            
        if not os.path.exists(source_dir):
            print(f"Skipping {lesson_dir_name}: Source directory {source_dir} not found.")
            continue
            
        # Find Gemini images
        files = os.listdir(source_dir)
        gemini_files = [f for f in files if f.startswith("Gemini_Generated_Image") and f.endswith(".webp")]
        
        # Sort files to ensure correct order (Base, (1), (2)...)
        # Python's default sort handles '... (1)' after '...' usually, but let's be safe
        # Actually ' ' (space) comes before '.'? No.
        # 'Image.webp' vs 'Image (1).webp'. '.' is 46, ' ' is 32. So ' ' comes FIRST.
        # So 'Image (1).webp' comes BEFORE 'Image.webp' in ASCII sort?
        # Let's check: 'a (1)' vs 'a.'. ' ' < '.'.
        # So 'Gemini... (1).webp' sorts BEFORE 'Gemini... .webp'.
        # This is CRITICAL.
        # Usually base file is the FIRST generated.
        # If I sort alphabetically, I might get (1) before Base.
        # I need to put Base FIRST.
        
        def sort_key(filename):
            # Extract number if present
            if "(" in filename and ")" in filename:
                try:
                    num_part = filename.split("(")[1].split(")")[0]
                    return int(num_part)
                except:
                    return 0
            else:
                return -1 # Base file comes first (0 index usually implies 1st, but let's make Base -1 to be absolutely first)
        
        # However, if there are multiple batches (different hash IDs), we need to sort by hash first, then number.
        # Filename format: Gemini_Generated_Image_<HASH> (<NUM>).webp OR Gemini_Generated_Image_<HASH>.webp
        
        def advanced_sort_key(filename):
            base_part = filename.split(" (")[0].replace(".webp", "")
            # Extract number
            if "(" in filename:
                try:
                    num = int(filename.split("(")[1].split(")")[0])
                except:
                    num = 0
            else:
                num = -1 # Base
            
            return (base_part, num)

        gemini_files.sort(key=advanced_sort_key)
        
        print(f"Processing {lesson_dir_name}...")
        print(f"Found {len(gemini_files)} new images.")
        print(f"Target {len(target_images)} images.")
        
        # Map and Rename
        for i, new_filename in enumerate(gemini_files):
            if i >= len(target_images):
                print(f"  Warning: More new images than targets. Skipping extra: {new_filename}")
                continue
                
            target_filename = target_images[i]
            src_path = os.path.join(source_dir, new_filename)
            dest_path = os.path.join(lesson_path, target_filename) # Destination is always Lesson root
            
            print(f"  Renaming {new_filename} -> {target_filename}")
            
            # Copy/Move
            try:
                # If source is same as dest dir (root), we rename.
                # If source is subfolder, we move to parent.
                if source_subfolder:
                    shutil.move(src_path, dest_path)
                else:
                    # Rename in place (delete old if exists? rename overwrites on Windows usually, but let's be safe)
                    if os.path.exists(dest_path):
                        os.remove(dest_path)
                    os.rename(src_path, dest_path)
            except Exception as e:
                print(f"  Error moving {new_filename}: {e}")
        
        # Cleanup
        if source_subfolder:
            try:
                # Remove subfolder if empty or just used
                # Check if empty of webp files?
                remaining = [f for f in os.listdir(source_dir) if f.startswith("Gemini") and f.endswith(".webp")]
                if not remaining:
                    shutil.rmtree(source_dir)
                    print(f"  Removed source directory: {source_dir}")
                else:
                    print(f"  Source directory not empty, left {len(remaining)} files.")
            except Exception as e:
                print(f"  Error cleaning up {source_dir}: {e}")

if __name__ == "__main__":
    process_lessons()
