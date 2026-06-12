#!/usr/bin/env python3
"""Convert background to solid color PNG to prevent dark mode inversion."""
import os
from PIL import Image

output_dir = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "android", "app", "src", "main", "res", "drawable"
)

# Create 324x324 teal background PNG
img = Image.new("RGBA", (324, 324), (92, 184, 165, 255))  # #5CB8A5
img.save(os.path.join(output_dir, "ic_launcher_background.png"), "PNG")
print("Saved: ic_launcher_background.png")
