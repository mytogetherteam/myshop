import sys
import os
from PIL import Image

def create_notification_icons(source_path, target_res_dir):
    try:
        img = Image.open(source_path).convert("RGBA")
        
        # Make all pixels white, preserving alpha
        r, g, b, a = img.split()
        white = Image.new('L', img.size, 255)
        white_img = Image.merge("RGBA", (white, white, white, a))
        
        sizes = {
            'mdpi': 24,
            'hdpi': 36,
            'xhdpi': 48,
            'xxhdpi': 72,
            'xxxhdpi': 96
        }
        
        for dpi, size in sizes.items():
            resized = white_img.resize((size, size), Image.Resampling.LANCZOS)
            out_dir = os.path.join(target_res_dir, f'drawable-{dpi}')
            os.makedirs(out_dir, exist_ok=True)
            out_path = os.path.join(out_dir, 'ic_notification.png')
            resized.save(out_path)
            print(f"Saved {out_path}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    src = r"C:\Users\User\.gemini\antigravity-ide\brain\734dedd2-d69b-4df7-9b33-bd95ba0f0ba0\media__1781856727022.png"
    dest = r"d:\my_shop\android\app\src\main\res"
    create_notification_icons(src, dest)
