#!/bin/bash
# Build script for macOS

echo "Building LEAF for macOS..."

# Install dependencies
pip install -r requirements.txt

# Convert PNG icon to ICNS format for macOS (requires iconutil)
if [ ! -f "assets/LEAF.icns" ]; then
    echo "Converting icon to ICNS format..."
    # Create iconset directory
    mkdir -p LEAF.iconset
    
    # Create different sizes (you may need to resize your PNG)
    cp assets/LEAF.png LEAF.iconset/icon_512x512.png
    
    # Generate ICNS file
    iconutil -c icns LEAF.iconset
    mv LEAF.icns assets/
    rm -rf LEAF.iconset
fi

# Build with PyInstaller
pyinstaller leaf.spec --clean --noconfirm

echo "Build complete! App bundle is in dist/LEAF.app/"
echo "To run: open dist/LEAF.app"