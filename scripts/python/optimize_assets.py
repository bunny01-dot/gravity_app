import os
from PIL import Image

def optimize_assets(directory):
    total_original_size = 0
    total_new_size = 0
    count = 0

    print(f"Scanning {directory}...")

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith(('.png', '.jpg', '.jpeg')):
                file_path = os.path.join(root, file)
                original_size = os.path.getsize(file_path)
                
                # Setup new path
                file_name_without_ext = os.path.splitext(file)[0]
                new_file_path = os.path.join(root, file_name_without_ext + ".webp")

                try:
                    with Image.open(file_path) as img:
                        # Convert to RGB (in case of RGBA PNGs, WebP supports transparency but best to ensure mode)
                        # WebP supports RGBA.
                        
                        # Save as WebP
                        img.save(new_file_path, 'WEBP', quality=80)
                    
                    new_size = os.path.getsize(new_file_path)
                    
                    # If new file is actually smaller, keep it and delete old
                    # (It almost always is, but good to check)
                    if new_size < original_size:
                        os.remove(file_path)
                        total_original_size += original_size
                        total_new_size += new_size
                        count += 1
                        print(f"Converted: {file} -> {os.path.basename(new_file_path)} ({(original_size/1024):.1f}KB -> {(new_size/1024):.1f}KB)")
                    else:
                        # If larger (rare), delete generated webp
                        os.remove(new_file_path)
                        print(f"Skipped (larger): {file}")
                        
                except Exception as e:
                    print(f"Error processing {file}: {e}")

    print("-" * 30)
    print(f"Total Files Converted: {count}")
    print(f"Original Size: {total_original_size / 1024 / 1024:.2f} MB")
    print(f"New Size:      {total_new_size / 1024 / 1024:.2f} MB")
    print(f"Space Saved:   {(total_original_size - total_new_size) / 1024 / 1024:.2f} MB")

if __name__ == "__main__":
    optimize_assets("assets/Lessons")
