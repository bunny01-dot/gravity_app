from PIL import Image
import sys

def convert_to_webp(in_path, out_path):
    try:
        img = Image.open(in_path)
        img.save(out_path, 'webp', quality=80)
        print(f"Successfully converted {in_path} to {out_path}")
    except Exception as e:
        print(f"Failed to convert {in_path}. Error: {e}")

if __name__ == "__main__":
    convert_to_webp(sys.argv[1], sys.argv[2])
