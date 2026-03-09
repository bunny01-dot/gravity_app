"""
Image Conversion and Deployment Script
Converts generated PNG images to WebP and copies them to asset folders
Session: 2026-02-03
"""

import os
import glob
from PIL import Image
from pathlib import Path

# Configuration: List of brain directories to search for images
SOURCE_DIRS = [
    r"C:\Users\HAPPY\.gemini\antigravity\brain\8056e0de-e712-4245-9823-a661499e05e7",
    r"C:\Users\HAPPY\.gemini\antigravity\brain\17b91c75-5845-4666-bcc4-8aac4dd96fcb",
    r"C:\Users\HAPPY\.gemini\antigravity\brain\665c2ef1-9485-4c2f-a1ad-04afbc03c665",
    r"C:\Users\HAPPY\.gemini\antigravity\brain\d35fd96c-6560-468b-8d81-3fb9a5fe9cd6", # Older session with many images
]
BASE_ASSETS_DIR = r"e:\Apps\gravity_app\assets\Lessons"

# Image mappings: (source_pattern, target_dir, target_filename)
IMAGE_MAPPINGS = [
    # Direct & Indirect Speech (7 images)
    ("direct_indirect_hook_square_*.png", "Lesson_Direct_Indirect_Speech", "direct_indirect_hook_square.webp"),
    ("tense_backshift_square_*.png", "Lesson_Direct_Indirect_Speech", "tense_backshift_square.webp"),
    ("pronoun_changes_square_*.png", "Lesson_Direct_Indirect_Speech", "pronoun_changes_square.webp"),
    ("time_place_changes_square_*.png", "Lesson_Direct_Indirect_Speech", "time_place_changes_square.webp"),
    ("question_indirect_square_*.png", "Lesson_Direct_Indirect_Speech", "question_indirect_square.webp"),
    ("commands_indirect_square_*.png", "Lesson_Direct_Indirect_Speech", "commands_indirect_square.webp"),
    ("speech_reference_square_*.png", "Lesson_Direct_Indirect_Speech", "speech_reference_square.webp"),
    
    # Irregular Verbs (6 images)
    ("no_change_square_*.png", "Lesson_04_Irregular_Verbs", "no_change_square.webp"),
    ("vowel_change_square_*.png", "Lesson_04_Irregular_Verbs", "vowel_change_square.webp"),
    ("past_equals_square_*.png", "Lesson_04_Irregular_Verbs", "past_equals_square.webp"),
    ("perfect_tense_square_*.png", "Lesson_04_Irregular_Verbs", "perfect_tense_square.webp"),
    ("learning_strategy_square_*.png", "Lesson_04_Irregular_Verbs", "learning_strategy_square.webp"),
    ("irregular_chart_square_*.png", "Lesson_04_Irregular_Verbs", "irregular_chart_square.webp"),

    # Question Types (5 images - recovered from staging)
    ("question_types_hook_square_*.png", "Lesson_14_Question_Types", "question_types_hook_square.webp"),
    ("5_question_types_square_*.png", "Lesson_14_Question_Types", "5_question_types_square.webp"),
    ("wh_questions_square_*.png", "Lesson_14_Question_Types", "wh_questions_square.webp"),
    ("yes_no_questions_square_*.png", "Lesson_14_Question_Types", "yes_no_questions_square.webp"),
    ("choice_questions_square_*.png", "Lesson_14_Question_Types", "choice_questions_square.webp"),

    # Determiners (Fixing improperly converted/renamed files)
    ("determiners_hook_square_*.png", "Lesson_Determiners", "determiners_hook_square.webp"),
    ("determiner_types_square_*.png", "Lesson_Determiners", "determiner_types_square.webp"),
    ("articles_determiners_square_*.png", "Lesson_Determiners", "articles_determiners_square.webp"),
    ("possessive_determiners_square_*.png", "Lesson_Determiners", "possessive_determiners_square.webp"),
    ("demonstratives_square_*.png", "Lesson_Determiners", "demonstratives_square.webp"),
    ("quantifiers_square_*.png", "Lesson_Determiners", "quantifiers_square.webp"),
    ("numbers_determiners_square_*.png", "Lesson_Determiners", "numbers_determiners_square.webp"),
    ("determiner_rules_square_*.png", "Lesson_Determiners", "determiner_rules_square.webp"),
    ("determiner_chart_square_*.png", "Lesson_Determiners", "determiner_chart_square.webp"),

    # Correlative Conjunctions (Fixing improperly converted/renamed files)
    ("both_and_square_*.png", "Lesson_Correlative_Conjunctions", "both_and_square.webp"),
    ("either_or_square_*.png", "Lesson_Correlative_Conjunctions", "either_or_square.webp"),
    ("neither_nor_square_*.png", "Lesson_Correlative_Conjunctions", "neither_nor_square.webp"),
    ("not_only_but_also_square_*.png", "Lesson_Correlative_Conjunctions", "not_only_but_also_square.webp"),
    ("comparison_pairs_square_*.png", "Lesson_Correlative_Conjunctions", "comparison_pairs_square.webp"),
    ("parallel_structure_square_*.png", "Lesson_Correlative_Conjunctions", "parallel_structure_square.webp"),
]

def convert_and_copy_image(source_pattern, target_dir, target_filename):
    """Convert PNG to WebP and copy to target directory"""
    source_file = None
    
    # Search for the latest file match across all source directories
    for source_dir in SOURCE_DIRS:
        if not os.path.exists(source_dir):
            continue
            
        matches = glob.glob(os.path.join(source_dir, source_pattern))
        if matches:
            latest = max(matches, key=os.path.getctime)
            if source_file is None or os.path.getctime(latest) > os.path.getctime(source_file):
                source_file = latest
    
    if not source_file:
        print(f"❌ No file found for pattern: {source_pattern}")
        return False
    
    # Create target path
    target_subdir = os.path.join(BASE_ASSETS_DIR, target_dir)
    if not os.path.exists(target_subdir):
        os.makedirs(target_subdir)
        
    target_path = os.path.join(target_subdir, target_filename)
    
    try:
        # Open and convert image
        img = Image.open(source_file)
        
        # Convert to RGB if necessary
        if img.mode in ('RGBA', 'LA', 'P'):
            img.save(target_path, 'WEBP', quality=90, method=6)
        else:
            img = img.convert('RGB')
            img.save(target_path, 'WEBP', quality=90, method=6)
        
        # Get file sizes for reporting
        source_size = os.path.getsize(source_file) / 1024  # KB
        target_size = os.path.getsize(target_path) / 1024  # KB
        compression_ratio = (1 - target_size / source_size) * 100
        
        print(f"✅ {target_filename}")
        print(f"   {source_size:.1f}KB → {target_size:.1f}KB ({compression_ratio:.1f}% smaller)")
        return True
        
    except Exception as e:
        print(f"❌ Error processing {source_pattern}: {str(e)}")
        return False

def main():
    print("=" * 60)
    print("Image Conversion and Deployment Script (v2.0)")
    print("=" * 60)
    print()
    
    # Process each image mapping
    success_count = 0
    total_count = len(IMAGE_MAPPINGS)
    
    print("Processing images from staging directories...")
    print()
    
    for source_pattern, target_dir, target_filename in IMAGE_MAPPINGS:
        if convert_and_copy_image(source_pattern, target_dir, target_filename):
            success_count += 1
        print()
    
    # Summary
    print("=" * 60)
    print(f"✅ Successfully processed: {success_count}/{total_count} images")
    print(f"❌ Failed: {total_count - success_count}")
    print("=" * 60)
    
    if success_count == total_count:
        print()
        print("🎉 All identified staging images successfully converted and deployed!")
        print()

if __name__ == "__main__":
    main()
