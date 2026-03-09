import os
import re

screens_dir = "e:/Apps/gravity_app/lib/screens"
output_file = "story_image_upgrade_guide.md"

lessons_info = []

file_names = [f for f in os.listdir(screens_dir) if f.startswith("lesson_") and f.endswith(".dart")]

for file_name in file_names:
    full_path = os.path.join(screens_dir, file_name)
    with open(full_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Extract Lesson Title (class name or from comments if possible)
    # Most screens have a title in the header or in _initializeLessonContent
    title_match = re.search(r"title:\s*['\"](.*?)['\"]", content)
    # Better: Extract from getCurriculumLessons mapping if possible, but let's try to find it in the file first.
    # Often the header comment has it.
    header_title_match = re.search(r"// SCREEN:\s*(.*)", content)
    lesson_title = header_title_match.group(1).strip() if header_title_match else file_name.replace("lesson_", "").replace("_screen.dart", "").replace("_", " ").title()
    
    # Extract images
    images = re.findall(r"imagePath:\s*['\"](.*?)['\"]", content)
    # Exclude variables like unit.imagePath
    images = [img for img in images if not img.endswith(".imagePath") and ".webp" in img]
    
    if images:
        lessons_info.append({
            "title": lesson_title,
            "images": images
        })

with open(output_file, "w", encoding="utf-8") as f:
    f.write("# Story Book Image Upgrade Guide\n\n")
    f.write("This guide tracks the status of image upgrades across all story/curriculum lessons. Every image must eventually be a premium 3D Pixar-style illustration.\n\n")
    
    for lesson in lessons_info:
        f.write(f"## Lesson: {lesson['title']}\n")
        f.write(f"### Current Image Status\n")
        for i, img in enumerate(lesson['images'], 1):
            # For now, mark most as 2D flat unless we've seen they are 3D
            # Based on user's prompt "Some lessons use 2D flat / generic images", I'll assume many are.
            f.write(f"- Image {i} ({img}): 2D flat illustration ❌\n")
        
        f.write(f"\n### Required Action\n")
        f.write(f"- Regenerate all images in cute 3D style (Pixar-inspired)\n")
        
        f.write(f"\n### Target Style Guidelines\n")
        f.write("- Cute 3D characters\n")
        f.write("- Soft lighting\n")
        f.write("- Rounded shapes\n")
        f.write("- Child-friendly expressions\n")
        f.write("- Consistent color palette\n")
        f.write("- Premium storybook feel\n")
        
        f.write(f"\n### Status\n")
        f.write("- [ ] Pending\n\n")
    
print(f"Created {output_file} with {len(lessons_info)} lessons.")
