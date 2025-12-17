#!/bin/bash
# Fix namespace issues in old Flutter plugins for newer Android Gradle Plugin

echo "🔧 Fixing plugin namespace issues..."

# Fix arcore_flutter_plugin build.gradle
ARCORE_BUILD="/Users/shehandulmina/.pub-cache/hosted/pub.dev/arcore_flutter_plugin-0.1.0/android/build.gradle"
if [ -f "$ARCORE_BUILD" ]; then
    if ! grep -q "namespace" "$ARCORE_BUILD"; then
        echo "Adding namespace to arcore_flutter_plugin build.gradle..."
        sed -i '' 's/^android {/android {\n    namespace "com.difrancescogianmarco.arcore_flutter_plugin"/' "$ARCORE_BUILD"
        echo "✅ arcore_flutter_plugin build.gradle fixed"
    else
        echo "✅ arcore_flutter_plugin build.gradle already has namespace"
    fi
else
    echo "⚠️  arcore_flutter_plugin not found (may not be installed)"
fi

# Fix tflite_flutter build.gradle
TFLITE_BUILD="/Users/shehandulmina/.pub-cache/hosted/pub.dev/tflite_flutter-0.9.5/android/build.gradle"
if [ -f "$TFLITE_BUILD" ]; then
    if ! grep -q "namespace" "$TFLITE_BUILD"; then
        echo "Adding namespace to tflite_flutter build.gradle..."
        sed -i '' 's/^android {/android {\n    namespace "com.tfliteflutter.tflite_flutter_plugin"/' "$TFLITE_BUILD"
        echo "✅ tflite_flutter build.gradle fixed"
    else
        echo "✅ tflite_flutter build.gradle already has namespace"
    fi
else
    echo "⚠️  tflite_flutter not found (may not be installed)"
fi

# Fix tflite_flutter tensor.dart
TFLITE_TENSOR="/Users/shehandulmina/.pub-cache/hosted/pub.dev/tflite_flutter-0.9.5/lib/src/tensor.dart"
if [ -f "$TFLITE_TENSOR" ]; then
    if grep -q "UnmodifiableUint8ListView" "$TFLITE_TENSOR"; then
        echo "Fixing tflite_flutter tensor.dart UnmodifiableUint8ListView error..."
        sed -i '' 's/UnmodifiableUint8ListView(/Uint8List.view(/' "$TFLITE_TENSOR"
        sed -i '' 's/data\.asTypedList(tfLiteTensorByteSize(_tensor)));/data.asTypedList(tfLiteTensorByteSize(_tensor)).buffer);/' "$TFLITE_TENSOR"
        echo "✅ tflite_flutter tensor.dart fixed"
    else
        echo "✅ tflite_flutter tensor.dart already fixed"
    fi
else
    echo "⚠️  tflite_flutter tensor.dart not found"
fi

echo ""
echo "✨ Plugin fixes applied!"
echo ""
echo "Now run: flutter run -d <device>"
