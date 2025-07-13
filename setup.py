#!/usr/bin/env python3
"""Setup script for LEAF Notes application."""

from setuptools import setup, find_packages
import os

# Read the README file
current_dir = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(current_dir, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='leaf-notes',
    version='1.0.0',
    description='A beautiful note-taking application with themes and collections',
    long_description=long_description,
    long_description_content_type='text/markdown',
    author='Your Name',
    author_email='your.email@example.com',
    url='https://github.com/yourusername/leaf-notes',
    
    # Package discovery
    packages=find_packages(),
    py_modules=['main'],
    
    # Dependencies
    install_requires=[
        'PySide6>=6.5.0',
    ],
    
    # Entry points
    entry_points={
        'gui_scripts': [
            'leaf-notes=main:main',
        ],
    },
    
    # Include additional files
    package_data={
        '': ['qml/*.qml', 'assets/*', 'config/*'],
    },
    include_package_data=True,
    
    # Metadata
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: End Users/Desktop',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Operating System :: OS Independent',
        'Topic :: Office/Business',
        'Topic :: Text Processing',
    ],
    
    python_requires='>=3.8',
    
    # For Debian packaging
    options={
        'bdist_deb': {
            'debian_dir': 'debian',
            'package': 'leaf-notes',
            'section': 'text',
            'priority': 'optional',
            'architecture': 'all',
            'depends': 'python3, python3-pyside6.qtcore, python3-pyside6.qtgui, python3-pyside6.qtqml, python3-pyside6.qtquick, python3-pyside6.qtwidgets',
            'description': 'A beautiful note-taking application with themes and collections',
            'maintainer': 'Your Name <your.email@example.com>',
        }
    }
)