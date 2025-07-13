#!/bin/bash
# Build script for Linux

echo "Building LEAF for Linux..."

# Install dependencies
pip install -r requirements.txt

# Build with PyInstaller
pyinstaller leaf.spec --clean --noconfirm

echo "Build complete! Executable is in dist/LEAF/"
echo "To run: ./dist/LEAF/LEAF"