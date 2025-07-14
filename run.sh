#!/bin/bash

# LEAF Notes App Launcher
# This script works around NVIDIA driver segfaults by using software rendering

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✓ Virtual environment activated"
fi

# Set Qt environment variables for stable rendering
export QT_QPA_PLATFORM=xcb
export QT_QUICK_BACKEND=software

echo "Starting LEAF with software rendering..."
echo ""
echo "(This avoids NVIDIA driver segfaults)"
echo ""

# Run the application
python3 main.py

# Deactivate virtual environment when done
if [ -d "venv" ]; then
    deactivate
fi