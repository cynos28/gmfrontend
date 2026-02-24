#!/bin/bash
# Quick IP Update Script for Flutter App
# Run this whenever you switch between WiFi/hotspot

echo "🔄 Updating Flutter app IP configuration..."
echo ""

# Get current IP address
CURRENT_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

if [ -z "$CURRENT_IP" ]; then
    echo "❌ Could not detect IP address"
    exit 1
fi

echo "📍 Current Mac IP: $CURRENT_IP"

# Files to update
FILES=(
    "gmfrontend/gmfrontend/lib/utils/constants.dart"
    "gmfrontend/gmfrontend/lib/services/api/measurement_api_service.dart"
    "gmfrontend/gmfrontend/lib/services/unit_progress_service.dart"
)

echo "🔧 Updating configuration files..."

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        # Create backup
        cp "$file" "$file.backup"
        
        # Update IP in the file
        sed -i.tmp "s/http:\/\/[0-9.]*:8000/http:\/\/$CURRENT_IP:8000/g" "$file"
        rm "$file.tmp"
        
        echo "   ✅ Updated: $file"
    else
        echo "   ⚠️  File not found: $file"
    fi
done

echo ""
echo "✅ IP configuration updated to: $CURRENT_IP"
echo ""
echo "📋 Next steps:"
echo "   1. Restart your Flutter app (flutter run)"
echo "   2. Ensure your phone is on the same network as your Mac"
echo "   3. Test the AR measurement feature"
echo ""
echo "💡 Tips for physical device testing:"
echo "   • Both devices must be on the same WiFi network"
echo "   • Avoid switching between WiFi/hotspot during testing"
echo "   • Run this script after network changes"