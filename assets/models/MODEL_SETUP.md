# 🤖 ML Model Setup for Object Detection

## Download Required Model

### Option 1: SSD MobileNet V1 (Recommended)

**Size**: ~4 MB  
**Speed**: Fast (real-time on most devices)  
**Accuracy**: Good for common objects

**Download from TensorFlow**:
```bash
cd ganithamithura/assets/models

# Download SSD MobileNet V1
curl -LO https://storage.googleapis.com/download.tensorflow.org/models/tflite/coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip

# Extract
unzip coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip

# Rename to standard name
mv detect.tflite ssd_mobilenet.tflite

# Clean up
rm coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip labelmap.txt
```

### Option 2: MobileNet V2 (Better Accuracy)

```bash
cd ganithamithura/assets/models

# Download
curl -LO https://storage.googleapis.com/download.tensorflow.org/models/tflite/coco_ssd_mobilenet_v2_1.0_2018_07_03.zip

# Extract
unzip coco_ssd_mobilenet_v2_1.0_2018_07_03.zip
mv detect.tflite ssd_mobilenet.tflite

# Clean up
rm coco_ssd_mobilenet_v2_1.0_2018_07_03.zip labelmap.txt
```

### Option 3: YOLO (Highest Accuracy, Slower)

```bash
cd ganithamithura/assets/models

# Download YOLOv4 Tiny (lighter version)
curl -LO https://github.com/hunglc007/tensorflow-yolov4-tflite/releases/download/v1.0/yolov4-tiny-416.tflite

# Rename
mv yolov4-tiny-416.tflite yolo.tflite
```

---

## Quick Setup (Recommended)

Use the pre-quantized SSD MobileNet:

```bash
cd /Users/shehandulmina/Downloads/Research/GM/ganithamithura/ganithamithura/assets/models

# Download directly
curl -o ssd_mobilenet.tflite https://tfhub.dev/tensorflow/lite-model/ssd_mobilenet_v1/1/metadata/2?lite-format=tflite
```

**Alternative: Use TensorFlow Hub**

Visit: https://tfhub.dev/tensorflow/collections/lite/task-library/object-detector/1

Download any of these:
- EfficientDet Lite0
- SSD MobileNet V1
- MobileNet V2

---

## Verify Model

After downloading, your structure should be:

```
ganithamithura/assets/models/
├── ssd_mobilenet.tflite    ← Model file
└── labels.txt              ← Already created ✓
```

**File size check**:
```bash
ls -lh assets/models/
# Should show:
# ssd_mobilenet.tflite  ~4-8 MB
# labels.txt            ~1 KB
```

---

## Using Custom Models

If you want to use your own trained model:

1. **Train with TensorFlow**:
   ```python
   # Export to TFLite
   converter = tf.lite.TFLiteConverter.from_saved_model('model/')
   tflite_model = converter.convert()
   
   # Save
   with open('custom_model.tflite', 'wb') as f:
       f.write(tflite_model)
   ```

2. **Update service**:
   ```dart
   // In object_detection_service.dart
   static const String _modelPath = 'assets/models/custom_model.tflite';
   ```

3. **Update labels**:
   - Edit `assets/models/labels.txt`
   - One label per line
   - Match training labels

---

## Troubleshooting

### "Model file not found"

```bash
# Verify path
ls -R assets/models/

# Make sure pubspec.yaml includes:
flutter:
  assets:
    - assets/models/
    - assets/models/labels.txt
```

### "Model incompatible"

Check TFLite version compatibility:
```yaml
# pubspec.yaml
dependencies:
  tflite_flutter: ^0.10.4  # Use this version
```

### "Out of memory"

Use quantized (smaller) models:
- Look for files ending in `_quant.tflite`
- Or use `int8` quantization

---

## Model Performance

### SSD MobileNet V1
- **Speed**: 30-60 FPS
- **Accuracy**: 70-80%
- **Best for**: Real-time detection
- **File size**: 4 MB

### SSD MobileNet V2
- **Speed**: 20-40 FPS
- **Accuracy**: 75-85%
- **Best for**: Better accuracy, still fast
- **File size**: 7 MB

### YOLO Tiny
- **Speed**: 15-30 FPS
- **Accuracy**: 80-90%
- **Best for**: Best detection quality
- **File size**: 23 MB

---

## Testing Object Detection

After setup, test in app:

1. Run app: `flutter run`
2. Go to Measurements → AR Challenge
3. Point camera at objects
4. Should see bounding boxes with labels
5. Confidence scores displayed

---

## Next: Flutter Setup

```bash
cd ganithamithura
flutter pub get
flutter run
```

The object detection will initialize automatically when you open the AR camera!
