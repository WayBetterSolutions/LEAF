# -*- mode: python ; coding: utf-8 -*-
import os
from pathlib import Path

block_cipher = None

# Get PySide6 installation path
import PySide6
pyside6_path = Path(PySide6.__file__).parent

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('qml', 'qml'),
        ('assets', 'assets'),
        ('config', 'config'),
        # Include Qt plugins and resources
        (str(pyside6_path / 'Qt/plugins'), 'PySide6/Qt/plugins'),
        (str(pyside6_path / 'Qt/translations'), 'PySide6/Qt/translations'),
        (str(pyside6_path / 'Qt/qml'), 'PySide6/Qt/qml'),
    ],
    hiddenimports=[
        'PySide6.QtCore',
        'PySide6.QtGui', 
        'PySide6.QtQml',
        'PySide6.QtQuick',
        'PySide6.QtQuickControls2',
        'PySide6.QtWidgets',
        'PySide6.QtNetwork',
        'PySide6.QtOpenGL',
        'PySide6.QtSvg',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='LEAF',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='assets/LEAFico.ico',
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='LEAF',
)

# macOS app bundle
app = BUNDLE(
    coll,
    name='LEAF.app',
    icon='assets/LEAF.icns',
    bundle_identifier='com.yourcompany.leaf',
    info_plist={
        'CFBundleName': 'LEAF',
        'CFBundleDisplayName': 'LEAF Notes',
        'CFBundleVersion': '1.0.0',
        'CFBundleShortVersionString': '1.0.0',
        'NSHighResolutionCapable': True,
    },
)