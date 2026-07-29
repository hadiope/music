#!/bin/bash
set -e

echo "Checking Flutter and Android setup..."

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found. Installing..."
    # Install Flutter (this is a simplified version)
    git clone https://github.com/flutter/flutter.git /tmp/flutter
    export PATH="/tmp/flutter/bin:$PATH"
    flutter doctor -v
else
    echo "Flutter found: $(flutter --version)"
fi

# Check if Android SDK is available
if ! command -v sdkmanager &> /dev/null && ! command -v adb &> /dev/null; then
    echo "Android SDK not found. Please install Android Studio or Android SDK manually."
    echo "Skipping APK build..."
    exit 1
fi

echo "Building Android APK..."

# Build APK
cd /tmp/iranseda-music

# Check if this is a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo "pubspec.yaml not found in current directory"
    exit 1
fi

# Clean and build
flutter clean
flutter pub get

# Build APK for debug mode (first)
flutter build apk --debug --no-sound-null-safety

if [ $? -eq 0 ]; then
    echo "APK debug build successful!"
    echo "APK location: $(find . -name "*.apk" -type f | head -1)"
else
    echo "Debug build failed. Trying release build..."
    # Build APK for release mode
    flutter build apk --release --no-sound-null-safety
    
    if [ $? -eq 0 ]; then
        echo "APK release build successful!"
        echo "APK location: $(find . -name "*.apk" -type f | head -1)"
    else
        echo "Release build also failed."
        exit 1
    fi
fi

echo "APK build complete!"