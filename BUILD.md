# Build Instructions

This document explains how to build LEAF Notes for different platforms.

## Prerequisites

```bash
pip install -r requirements.txt
```

## Build Commands

### Linux Executable
```bash
./build_scripts/build_linux.sh
```
Output: `dist/LEAF/LEAF`

### Windows Executable
```batch
build_scripts\build_windows.bat
```
Output: `dist\LEAF\LEAF.exe`

### macOS App Bundle
```bash
./build_scripts/build_macos.sh
```
Output: `dist/LEAF.app`

### Debian Package
```bash
./build_scripts/create_deb.sh
```
Output: `leaf-notes_1.0.0_amd64.deb`

## Manual Build

### Using PyInstaller directly:
```bash
pyinstaller leaf.spec --clean --noconfirm
```

### Using Python packaging:
```bash
python setup.py bdist_wheel
```

## Notes

- Build artifacts are automatically ignored by git
- The `venv/` directory contains a development environment
- QML files and assets are automatically bundled
- Cross-platform builds require the target platform