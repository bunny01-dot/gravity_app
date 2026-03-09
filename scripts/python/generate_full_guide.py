import os
import re

screens_dir = "e:/Apps/gravity_app/lib/screens"
output_file = "story_image_upgrade_guide.md"

lessons_info = []

file_names = sorted([f for f in os.listdir(screens_dir) if f.startswith("lesson_") and f.endswith(".dart")])

for file_name in file_names:
    full_path = os.path.join(screens_dir, file_name)
    with open(full_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    header_title_match = re.search(r"// SCREEN:\s*(.*)", content)
    lesson_title = header_title_match.group(1).strip() if header_title_match else file_name.replace("lesson_", "").replace("_screen.dart", "").replace("_", " ").title()
    
    lesson_id_match = re.search(r"lessonId:\s*['\"](.*?)['\"]", content)
    lesson_id = lesson_id_match.group(1) if lesson_id_match else file_name.replace("lesson_", "").replace("_screen.dart", "")

    images = re.findall(r"imagePath:\s*['\"](.*?)['\"]", content)
    # Filter for webp images and exclude variables/logic
    unique_images = []
    for img in images:
        if ".webp" in img and not img.endswith(".imagePath") and img not in unique_images:
            unique_images.append(img)
    
    if unique_images:
        lessons_info.append({
            "title": lesson_title,
            "id": lesson_id,
            "images": unique_images
        })

with open(output_file, "w", encoding="utf-8") as f:
    f.write("# Story Book Image Upgrade Guide\n\n")
    f.write("This guide tracks the status of image upgrades across all story/curriculum lessons. Every image must eventually be a premium 3D Pixar-style illustration.\n\n")
    f.write("## Target Style Guidelines\n")
    f.write("- **Cute 3D Characters**: High-quality stylized 3D personalities.\n")
    f.write("- **Soft Lighting**: Cinematic depth and warm tones.\n")
    f.write("- **Rounded Shapes**: Safe, child-friendly, and modern aesthetic.\n")
    f.write("- **Premium Storybook Feel**: Consistency in lead characters (e.g., Ravi).\n\n")
    f.write("---\n\n")
    
    for lesson in lessons_info:
        f.write(f"## Lesson: {lesson['title']}\n")
        f.write(f"Lesson ID: `{lesson['id']}`\n\n")
        f.write(f"### Current Image Status\n")
        for i, img in enumerate(lesson['images'], 1):
            f.write(f"- Image {i} ({img}): 2D flat illustration ❌\n")
        
        f.write(f"\n### Required Action\n")
        f.write(f"- Regenerate all images in cute 3D Pixar-style.\n")
        
        f.write(f"\n### Status\n")
        f.write("- [ ] Pending\n\n")
        f.write("---\n\n")

print(f"Created full guide {output_file} with {len(lessons_info)} lessons.")
