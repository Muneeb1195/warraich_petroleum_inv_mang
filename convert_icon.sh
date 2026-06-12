#!/bin/bash
# Run this script with your nozzle image:
# ./convert_icon.sh /path/to/nozzle_image.png

INPUT="$1"
RES_DIR="android/app/src/main/res"

if [ -z "$INPUT" ]; then
    echo "Usage: ./convert_icon.sh <path_to_nozzle_image.png>"
    echo "Save your nozzle image first, then run this script."
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "File not found: $INPUT"
    exit 1
fi

echo "Converting image to adaptive icon..."

# Create foreground PNG (108dp = 324px at xxxhdpi)
# Place original image centered on transparent background
ffmpeg -y -i "$INPUT" \
  -vf "scale=216:216:force_original_aspect_ratio=decrease,pad=324:324:(ow-iw)/2:(oh-ih)/2:color=0x00000000" \
  "${RES_DIR}/drawable/ic_launcher_foreground.png" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "ffmpeg not found. Trying with ImageMagick..."
    convert "$INPUT" \
      -resize 216x216 \
      -gravity center -background none -extent 324x324 \
      "${RES_DIR}/drawable/ic_launcher_foreground.png"
fi

if [ -f "${RES_DIR}/drawable/ic_launcher_foreground.png" ]; then
    echo "Created: ${RES_DIR}/drawable/ic_launcher_foreground.png"
    
    # Remove the vector foreground since we're using PNG now
    rm -f "${RES_DIR}/drawable/ic_launcher_foreground.xml"
    
    echo "Done! Now run: flutter run"
else
    echo "Failed to convert image. Please manually place a 324x324 PNG at:"
    echo "  ${RES_DIR}/drawable/ic_launcher_foreground.png"
fi
