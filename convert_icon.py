#!/usr/bin/env python3
"""
Convert a nozzle image to Android adaptive icon foreground.
Usage: python3 convert_icon.py "/path/to/nozzle image.png"
"""
import sys
import os

try:
    from PIL import Image
except ImportError:
    print("Installing Pillow...")
    os.system("pip3 install Pillow")
    from PIL import Image

def convert(input_path, output_dir):
    target_size = 324
    
    img = Image.open(input_path).convert("RGBA")
    img.thumbnail((216, 216), Image.LANCZOS)
    
    # Create foreground with white nozzle on transparent
    canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    x = (target_size - img.width) // 2
    y = (target_size - img.height) // 2
    
    # Make all non-transparent pixels white for the foreground
    white_img = Image.new("RGBA", img.size, (255, 255, 255, 0))
    # Copy alpha channel from original
    r, g, b, a = img.split()
    white_img = Image.merge("RGBA", (
        Image.new("L", img.size, 255),
        Image.new("L", img.size, 255),
        Image.new("L", img.size, 255),
        a
    ))
    
    canvas.paste(white_img, (x, y), white_img)
    
    output_path = os.path.join(output_dir, "ic_launcher_foreground.png")
    canvas.save(output_path, "PNG")
    print(f"Saved: {output_path}")
    
    # Monochrome: black nozzle on transparent (for Android 13 themed icons)
    mono_canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    black_img = Image.merge("RGBA", (
        Image.new("L", img.size, 0),
        Image.new("L", img.size, 0),
        Image.new("L", img.size, 0),
        a
    ))
    mono_canvas.paste(black_img, (x, y), black_img)
    
    mono_path = os.path.join(output_dir, "ic_launcher_monochrome.png")
    mono_canvas.save(mono_path, "PNG")
    print(f"Saved: {mono_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print('Usage: python3 convert_icon.py "/path/to/nozzle image.png"')
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_dir = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "android", "app", "src", "main", "res", "drawable"
    )
    
    os.makedirs(output_dir, exist_ok=True)
    convert(input_path, output_dir)
    print("\nNow run: flutter run")
