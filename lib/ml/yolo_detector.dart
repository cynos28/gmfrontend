import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Detection {
  final Rect box; // in preview coordinates
  final int classId;
  final String label;
  final double score;

  Detection({required this.box, required this.classId, required this.label, required this.score});
}

class YoloDetector {
  static const int inputSize = 640;
  static const double confThreshold = 0.30;
  static const double iouThreshold = 0.45;

  late final Interpreter _interpreter;
  late final List<String> _labels;

  bool _busy = false;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset('assets/models/classroom.tflite');

    final labelsRaw = await rootBundle.loadString('assets/labels/classes.txt');
    _labels = labelsRaw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void close() {
    _interpreter.close();
  }

  bool get isBusy => _busy;

  /// Main function: CameraImage -> detections in preview coordinates
  Future<List<Detection>> detect(CameraImage image, {required double previewW, required double previewH}) async {
    if (_busy) return [];
    _busy = true;

    try {
      final rgb = _cameraImageToImage(image);

      // Resize (warp) to 640x640. Simple and works for demos.
      final resized = img.copyResize(rgb, width: inputSize, height: inputSize);

      // Build input tensor: [1, 640, 640, 3] float32
      final input = _imageToFloat32(resized);

      // Output: [1, 24, 8400]
      final output = List.generate(1, (_) => List.generate(24, (_) => List.filled(8400, 0.0)));

      _interpreter.run(input, output);

      // Decode YOLO output into boxes in 640x640 space
      final ОС = output[0]; // [24][8400]
      final raw = <_RawDet>[];

      for (int i = 0; i < 8400; i++) {
        final x = ОС[0][i];
        final y = ОС[1][i];
        final w = ОС[2][i];
        final h = ОС[3][i];

        // Find best class score among 20 classes (index 4..23)
        double best = 0.0;
        int bestId = -1;
        for (int c = 0; c < _labels.length; c++) {
          final s = ОС[4 + c][i];
          if (s > best) {
            best = s;
            bestId = c;
          }
        }

        if (best < confThreshold || bestId < 0) continue;

        // YOLO gives center-x, center-y, width, height (usually in input pixels)
        final left = x - w / 2;
        final top = y - h / 2;
        final right = x + w / 2;
        final bottom = y + h / 2;

        // Clamp to 0..640
        final l = left.clamp(0.0, inputSize.toDouble());
        final t = top.clamp(0.0, inputSize.toDouble());
        final r = right.clamp(0.0, inputSize.toDouble());
        final b = bottom.clamp(0.0, inputSize.toDouble());

        raw.add(_RawDet(
          box640: Rect.fromLTRB(l, t, r, b),
          classId: bestId,
          score: best,
        ));
      }

      // NMS (class-wise)
      final nms = _nms(raw, iouThreshold);

      // Map 640x640 coords to preview coords (because we resized with warp)
      final sx = previewW / inputSize;
      final sy = previewH / inputSize;

      return nms.map((d) {
        final bb = Rect.fromLTRB(
          d.box640.left * sx,
          d.box640.top * sy,
          d.box640.right * sx,
          d.box640.bottom * sy,
        );
        return Detection(
          box: bb,
          classId: d.classId,
          label: _labels[d.classId],
          score: d.score,
        );
      }).toList();
    } finally {
      _busy = false;
    }
  }

  // ---------- Helpers ----------

  img.Image _cameraImageToImage(CameraImage cameraImage) {
    // Assumes YUV420
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final img.Image image = img.Image(width: width, height: height);

    final planeY = cameraImage.planes[0];
    final planeU = cameraImage.planes[1];
    final planeV = cameraImage.planes[2];

    final int bytesPerRowY = planeY.bytesPerRow;
    final int bytesPerRowU = planeU.bytesPerRow;
    final int bytesPerPixelU = planeU.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      final int rowY = y * bytesPerRowY;
      final int rowUV = (y >> 1) * bytesPerRowU;

      for (int x = 0; x < width; x++) {
        final int yIndex = rowY + x;
        final int uvIndex = rowUV + (x >> 1) * bytesPerPixelU;

        final int Y = planeY.bytes[yIndex];
        final int U = planeU.bytes[uvIndex];
        final int V = planeV.bytes[uvIndex];

        int r = (Y + (1.370705 * (V - 128))).round();
        int g = (Y - (0.337633 * (U - 128)) - (0.698001 * (V - 128))).round();
        int b = (Y + (1.732446 * (U - 128))).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }

  List<List<List<List<double>>>> _imageToFloat32(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(
          inputSize,
          (_) => List.filled(3, 0.0),
        ),
      ),
    );

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = image.getPixel(x, y);
        input[0][y][x][0] = p.r / 255.0;
        input[0][y][x][1] = p.g / 255.0;
        input[0][y][x][2] = p.b / 255.0;
      }
    }
    return input;
  }

  List<_RawDet> _nms(List<_RawDet> dets, double iouThr) {
    // Sort by score desc
    dets.sort((a, b) => b.score.compareTo(a.score));

    final kept = <_RawDet>[];
    final used = List.filled(dets.length, false);

    for (int i = 0; i < dets.length; i++) {
      if (used[i]) continue;
      final a = dets[i];
      kept.add(a);

      for (int j = i + 1; j < dets.length; j++) {
        if (used[j]) continue;
        final b = dets[j];

        // class-wise NMS
        if (a.classId != b.classId) continue;

        final iou = _iou(a.box640, b.box640);
        if (iou > iouThr) used[j] = true;
      }
    }

    return kept;
  }

  double _iou(Rect a, Rect b) {
    final left = max(a.left, b.left);
    final top = max(a.top, b.top);
    final right = min(a.right, b.right);
    final bottom = min(a.bottom, b.bottom);

    final w = max(0.0, right - left);
    final h = max(0.0, bottom - top);
    final inter = w * h;

    final areaA = (a.width) * (a.height);
    final areaB = (b.width) * (b.height);
    final union = areaA + areaB - inter;

    if (union <= 0) return 0.0;
    return inter / union;
  }
}

class _RawDet {
  final Rect box640;
  final int classId;
  final double score;

  _RawDet({required this.box640, required this.classId, required this.score});
}