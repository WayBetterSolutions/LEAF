#!/bin/bash
# Build Debian package

echo "Building Debian package for LEAF..."

# Install build dependencies
sudo apt-get update
sudo apt-get install -y python3-stdeb dh-python debhelper

# Clean previous builds
rm -rf deb_dist/

# Build the package
python3 setup.py --command-packages=stdeb.command bdist_deb

echo "Debian package built successfully!"
echo "Package location: deb_dist/"
echo "To install: sudo dpkg -i deb_dist/python3-leaf-notes_*.deb"