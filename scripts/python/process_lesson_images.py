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

# Data for conversion (Adverbs lesson)
images_to_process = [
    (r"C:/Users/HAPPY/.gemini/antigravity/brain/4ae45e03-ae7a-4a39-b59c-617e6a44cc94/adverb_hook_square_1769779645702.png", r"e:/Apps/gravity_app/assets/Lessons/Lesson_27_Adverbs", "adverb_hook_square.webp"),
    (r"C:/Users/HAPPY/.gemini/antigravity/brain/4ae45e03-ae7a-4a39-b59c-617e6a44cc94/5_adverb_types_square_1769779677955.png", r"e:/Apps/gravity_app/assets/Lessons/Lesson_27_Adverbs", "5_adverb_types_square.webp"),
    (r"C:/Users/HAPPY/.gemini/antigravity/brain/4ae45e03-ae7a-4a39-b59c-617e6a44cc94/manner_adverbs_square_1769779709136.png", r"e:/Apps/gravity_app/assets/Lessons/Lesson_27_Adverbs", "manner_adverbs_square.webp"),
    (r"C:/Users/HAPPY/.gemini/antigravity/brain/4ae45e03-ae7a-4a39-b59c-617e6a44cc94/frequency_adverbs_square_1769779762551.png", r"e:/Apps/gravity_app/assets/Lessons/Lesson_27_Adverbs", "frequency_adverbs_square.webp"),
    (r"C:/Users/HAPPY/.gemini/antigravity/brain/4ae45e03-ae7a-4a39-b59c-617e6a44cc94/place_time_adverbs_square_1769779799289.png", r"e:/Apps/gravity_app/assets/Lessons/Lesson_27_Adverbs", "place_time_adverbs_square.webp"),
    (r"C:/Users/HAPPY/.gemini/antigravity/brain/4ae45e03-ae7a-4a39-b59c-617e6a44cc94/degree_adverbs_square_1769779834263.png", r"e:/Apps/gravity_app/assets/Lessons/Lesson_27_Adverbs", "degree_adverbs_square.webp"),
]

for src, dest_dir, dest_file in images_to_process:
    convert_and_move(src, dest_dir, dest_file)
