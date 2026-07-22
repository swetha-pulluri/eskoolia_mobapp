#!/bin/bash
# eSkoolia Mobile App - Build Script
# This script installs dependencies and generates code

echo "========================================"
echo "eSkoolia Mobile App - Setup"
echo "========================================"
echo ""

echo "[1/3] Cleaning previous build..."
flutter clean
echo ""

echo "[2/3] Installing dependencies..."
flutter pub get
echo ""

echo "[3/3] Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "You can now run the app with:"
echo "  flutter run"
echo ""
