#!/bin/bash
# Simple DEB package creator using dpkg-deb

echo "Creating DEB package for LEAF..."

# Build directory structure
DEB_DIR="leaf-notes_1.0.0_amd64"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/opt/leaf-notes"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/256x256/apps"

# Copy application files
cp -r dist/LEAF/* "$DEB_DIR/opt/leaf-notes/"

# Create launcher script in /usr/bin
cat > "$DEB_DIR/usr/bin/leaf-notes" << 'EOF'
#!/bin/bash
export QT_QPA_PLATFORM=xcb
export QT_PLUGIN_PATH="/opt/leaf-notes/_internal/PySide6/Qt/plugins"
cd /opt/leaf-notes
exec ./LEAF "$@"
EOF

chmod +x "$DEB_DIR/usr/bin/leaf-notes"

# Create desktop entry
cat > "$DEB_DIR/usr/share/applications/leaf-notes.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=LEAF Notes
Comment=A beautiful note-taking application with themes and collections
Exec=leaf-notes
Icon=leaf-notes
Terminal=false
Categories=Office;TextEditor;Utility;
MimeType=text/plain;
EOF

# Copy icon
cp assets/LEAF.png "$DEB_DIR/usr/share/icons/hicolor/256x256/apps/leaf-notes.png"

# Create control file
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: leaf-notes
Version: 1.0.0
Section: text
Priority: optional
Architecture: amd64
Maintainer: Your Name <your.email@example.com>
Description: A beautiful note-taking application with themes and collections
 LEAF Notes is a modern note-taking application built with Qt/QML.
 Features include multiple collections, themes, and a clean interface.
Depends: libc6, libgcc-s1, libqt6core6, libqt6gui6, libqt6widgets6
EOF

# Build the package
dpkg-deb --build "$DEB_DIR"

echo "DEB package created: ${DEB_DIR}.deb"
echo "To install: sudo dpkg -i ${DEB_DIR}.deb"