@echo off
REM Build script for Windows

echo Building LEAF for Windows...

REM Install dependencies
pip install -r requirements.txt

REM Build with PyInstaller
pyinstaller leaf.spec --clean --noconfirm

echo Build complete! Executable is in dist\LEAF\
echo To run: dist\LEAF\LEAF.exe