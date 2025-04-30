#!/bin/bash

# setup.sh - Script to create all files and folders for the repository
# Usage: ./setup.sh

# Exit on error
set -e

echo "Creating repository structure..."

# Create directories
mkdir -p src
mkdir -p tests
mkdir -p docs
mkdir -p config

# Create source files
touch src/__init__.py
touch src/main.py

# Create test files
touch tests/__init__.py
touch tests/test_main.py

# Create configuration files
touch .gitignore
touch requirements.txt
touch config/settings.json

# Create documentation files
touch docs/index.md
touch docs/usage.md

# Make the main script executable
chmod +x src/main.py

echo "Repository structure created successfully!"
echo ""
echo "Created directories:"
echo "- src/: Source code"
echo "- tests/: Unit tests"
echo "- docs/: Documentation"
echo "- config/: Configuration files"
echo ""
echo "Created files:"
echo "- src/__init__.py, src/main.py: Source code files"
echo "- tests/__init__.py, tests/test_main.py: Test files"
echo "- .gitignore, requirements.txt: Project configuration"
echo "- config/settings.json: Application settings"
echo "- docs/index.md, docs/usage.md: Documentation files"