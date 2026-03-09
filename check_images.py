import os
import re

guide_path = r"e:\Apps\gravity_app\guide\story_image_upgrade_guide.md"

with open(guide_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

current_lesson_id = None
current_lesson_name = None
lesson_images = {}

for line in lines:
    line = line.strip()
    if line.startswith("## Lesson:"):
        current_lesson_name = line.replace("## Lesson:", "").strip()
    elif line.startswith("Lesson ID:"):
        match = re.search(r'`([^`]+)`', line)
        if match:
            current_lesson_id = match.group(1)
            lesson_images[current_lesson_id] = {'name': current_lesson_name, 'images': []}
    elif line.startswith("- Image") and current_lesson_id:
        img_match = re.search(r'\(([^)]+)\)', line)
        status_match = "2D" if "2D" in line else ("Premium 3D" if "Premium 3D" in line else "Unknown")
        if img_match:
            img_name = img_match.group(1).split("}")[-1] # Handle ${assetPath}
            lesson_images[current_lesson_id]['images'].append({
                'name': img_name,
                'status': status_match,
                'is_3d': "Premium 3D" in status_match,
                'raw': line
            })

report = []
missing_3d = []

for lesson_id, data in lesson_images.items():
    not_3d = [img for img in data['images'] if not img['is_3d']]
    if not_3d:
        missing_3d.append(f"### Lesson: {data['name']} (ID: `{lesson_id}`)\nHas {len(not_3d)} images that are NOT 3D Pixar style.")
        for img in not_3d:
            missing_3d.append(f"  - `{img['name']}`: {img['status']}")

out_path = r"e:\Apps\gravity_app\missing_images_report.md"
with open(out_path, 'w', encoding='utf-8') as f:
    f.write("# Missing 3D Pixar Style Images Report\n\n")
    if not missing_3d:
        f.write("All images in the guide are marked as Premium 3D Pixar style!\n")
    else:
        f.write("\n".join(missing_3d) + "\n")
