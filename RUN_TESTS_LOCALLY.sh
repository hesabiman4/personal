#!/bin/bash

# Personal Income/Expense Tracker - Local Testing Script
# Run this script on your local machine after copying the project files

set -e

echo "🚀 Personal Income/Expense Tracker - Testing Suite"
echo "=================================================="

PROJECT_DIR="Personal/app"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter from https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory '$PROJECT_DIR' not found"
    echo "Please ensure you've copied the project files correctly"
    exit 1
fi

cd "$PROJECT_DIR"

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo "📂 Project directory: $(pwd)"

# Step 1: Clean and get dependencies
echo ""
echo "📦 Step 1: Getting dependencies..."
flutter clean
flutter pub get

# Step 2: Check for connected devices
echo ""
echo "📱 Step 2: Checking for connected devices..."
flutter devices

DEVICE_COUNT=$(flutter devices | grep -c "•")
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "⚠️  No devices detected. Please connect a device or start an emulator."
    echo "   You can still run unit/widget tests without a device."
    READ_ONLY=true
else
    echo "✅ Device(s) detected!"
    READ_ONLY=false
fi

# Step 3: Run static analysis
echo ""
echo "🔍 Step 3: Running static analysis..."
flutter analyze

# Step 4: Run unit and widget tests
echo ""
echo "🧪 Step 4: Running unit and widget tests..."
flutter test --coverage

# Generate coverage report (if lcov is available)
if command -v genhtml &> /dev/null; then
    echo "📊 Generating HTML coverage report..."
    genhtml coverage/lcov.info -o coverage/html
    echo "✅ Coverage report generated at: coverage/html/index.html"
else
    echo "ℹ️  Install 'lcov' to generate HTML coverage report"
fi

# Step 5: Build APK (optional, only if device connected)
if [ "$READ_ONLY" = false ]; then
    echo ""
    echo "📲 Step 5: Building and running on device..."
    echo "Choose an option:"
    echo "  1) Run in debug mode (hot reload enabled)"
    echo "  2) Build release APK"
    echo "  3) Skip build and exit"
    
    read -p "Enter choice (1-3): " BUILD_CHOICE
    
    case $BUILD_CHOICE in
        1)
            echo "🚀 Running in debug mode..."
            flutter run
            ;;
        2)
            echo "📦 Building release APK..."
            flutter build apk --release
            echo "✅ APK built at: build/app/outputs/flutter-apk/app-release.apk"
            ;;
        3)
            echo "⏭️  Skipping build"
            ;;
        *)
            echo "Invalid choice, skipping build"
            ;;
    esac
else
    echo ""
    echo "⏭️  Skipping device build (no device connected)"
fi

echo ""
echo "=================================================="
echo "✅ Testing complete!"
echo ""
echo "📊 Summary:"
echo "   - Static analysis: Completed"
echo "   - Unit/Widget tests: Completed"
echo "   - Coverage report: coverage/lcov.info"
if [ -f "coverage/html/index.html" ]; then
    echo "   - HTML report: coverage/html/index.html"
fi
echo ""
echo "🎯 Next Steps:"
echo "   - Review test results above"
echo "   - Check coverage report for untested code"
echo "   - Perform manual testing using TESTING_GUIDE.md"
echo "=================================================="
