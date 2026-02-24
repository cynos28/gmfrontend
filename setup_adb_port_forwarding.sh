#!/bin/bash
# Setup ADB port forwarding for Android device testing
# This allows Android device to access localhost:8000 on your Mac

echo "🔧 Setting up ADB port forwarding..."
echo ""

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo "❌ ADB not found. Please install Android SDK Platform Tools"
    echo "   Download from: https://developer.android.com/studio/releases/platform-tools"
    exit 1
fi

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device connected"
    echo "   Please connect your device via USB and enable USB debugging"
    echo ""
    echo "   To enable USB debugging:"
    echo "   1. Go to Settings > About Phone"
    echo "   2. Tap 'Build Number' 7 times"
    echo "   3. Go to Settings > Developer Options"
    echo "   4. Enable 'USB Debugging'"
    exit 1
fi

echo "✅ Android device connected"
echo ""

# Setup port forwarding for unit-rag-service (port 8000)
echo "Setting up port forwarding..."
adb reverse tcp:8000 tcp:8000

if [ $? -eq 0 ]; then
    echo "✅ Port forwarding configured successfully!"
    echo ""
    echo "📱 Your Android device can now access:"
    echo "   http://localhost:8000 → Your Mac's port 8000"
    echo ""
    echo "🚀 You can now run your Flutter app!"
else
    echo "❌ Failed to setup port forwarding"
    exit 1
fi
