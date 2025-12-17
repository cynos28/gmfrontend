#!/bin/bash

# AR Object Detection Model Download Script
# Downloads SSD MobileNet V1 for object detection

echo "🤖 Downloading Object Detection Model..."
echo ""

# Create models directory if it doesn't exist
mkdir -p assets/models
cd assets/models

echo "📥 Downloading SSD MobileNet V1..."

# Download from TensorFlow Hub
curl -L -o ssd_mobilenet.zip "https://storage.googleapis.com/download.tensorflow.org/models/tflite/coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip"

if [ $? -eq 0 ]; then
    echo "✅ Download complete"
else
    echo "❌ Download failed"
    echo "Try manual download from:"
    echo "https://www.tensorflow.org/lite/examples/object_detection/overview"
    exit 1
fi

echo ""
echo "📦 Extracting model..."

# Unzip
unzip -o ssd_mobilenet.zip

# Rename model file
if [ -f "detect.tflite" ]; then
    mv detect.tflite ssd_mobilenet.tflite
    echo "✅ Model extracted: ssd_mobilenet.tflite"
else
    echo "❌ Model file not found in archive"
    exit 1
fi

# Clean up
rm ssd_mobilenet.zip
rm -f labelmap.txt  # We use our own labels.txt

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Files created:"
ls -lh

echo ""
echo "Next steps:"
echo "1. Run: flutter pub get"
echo "2. Run: flutter run"
echo "3. Test AR camera with object detection!"
