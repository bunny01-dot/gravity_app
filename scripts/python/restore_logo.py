import os
from PIL import Image

def restore_logo():
    webp_path = r"e:\Apps\gravity_app\assets\images\app_logo.webp"
    png_path = r"e:\Apps\gravity_app\assets\images\app_logo.png"

    if os.path.exists(webp_path):
        print(f"Restoring {png_path} from {webp_path}...")
        try:
            with Image.open(webp_path) as img:
                img.save(png_path, 'PNG')
            print("Restoration complete.")
            # Keep both? Usually app_logo is needed as png.
            # But the asset bundle one can be webp.
            # However, safer to have png for launcher icons.
        except Exception as e:
            print(f"Error restoring logo: {e}")
    else:
        print(f"Warning: {webp_path} not found.")

if __name__ == "__main__":
    restore_logo()
