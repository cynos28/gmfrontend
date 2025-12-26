import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';
import 'package:ganithamithura/ml/detection.dart';

class SsdDetectorFromFile {
  late final Interpreter _interpreter;
  late final List<String> _labels;

  late final int _inH;
  late final int _inW;
  late final TensorType _inType;
  late final QuantizationParams _q;

  Future<void> load({
    String modelAsset = 'assets/models/classroom.tflite',
    String labelsAsset = 'assets/labels/classes.txt',
    int threads = 4,
  }) async {
    final opts = InterpreterOptions()..threads = threads;
    _interpreter = await Interpreter.fromAsset(modelAsset, options: opts);

    final inT = _interpreter.getInputTensor(0);
    _inH = inT.shape[1];
    _inW = inT.shape[2];
    _inType = inT.type;
    _q = inT.params;

    final labelsRaw = await rootBundle.loadString(labelsAsset);
    _labels = labelsRaw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void close() => _interpreter.close();

  Future<List<Detection>> detectFile(
    String imagePath, {
    double scoreThreshold = 0.35,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return const [];

    // resize to model input
    final resized = img.copyResize(decoded, width: _inW, height: _inH);

    final Object input = (_inType == TensorType.uint8)
        ? _imageToUint8(resized)
        : _imageToFloat32(resized);

    // SSD outputs
    final out0 = _interpreter.getOutputTensor(0);
    final n = out0.shape[1];

    final boxes = Float32List(n * 4);
    final classes = Float32List(n);
    final scores = Float32List(n);
    final num = Float32List(1);

    final outputs = <int, Object>{
      0: boxes.reshape([1, n, 4]),
      1: classes.reshape([1, n]),
      2: scores.reshape([1, n]),
      3: num,
    };

    _interpreter.runForMultipleInputs([input], outputs);

    final count = num[0].round().clamp(0, n);

    final dets = <Detection>[];
    for (int i = 0; i < count; i++) {
      final s = scores[i];
      if (s < scoreThreshold) continue;

      final classId = classes[i].round();
      final label = (classId >= 0 && classId < _labels.length)
          ? _labels[classId]
          : 'class_$classId';

      // normalized: ymin, xmin, ymax, xmax
      final ymin = boxes[i * 4 + 0].clamp(0.0, 1.0);
      final xmin = boxes[i * 4 + 1].clamp(0.0, 1.0);
      final ymax = boxes[i * 4 + 2].clamp(0.0, 1.0);
      final xmax = boxes[i * 4 + 3].clamp(0.0, 1.0);

      // map to original image size (decoded)
      final left = xmin * decoded.width;
      final top = ymin * decoded.height;
      final right = xmax * decoded.width;
      final bottom = ymax * decoded.height;

      dets.add(
        Detection(
          box: Rect.fromLTRB(left, top, right, bottom),
          classId: classId,
          label: label,
          score: s,
        ),
      );
    }

    return dets;
  }

  Uint8List _imageToUint8(img.Image im) {
    final out = Uint8List(_inH * _inW * 3);
    int i = 0;
    for (int y = 0; y < _inH; y++) {
      for (int x = 0; x < _inW; x++) {
        final p = im.getPixel(x, y);
        out[i++] = _quantize(p.r.toDouble());
        out[i++] = _quantize(p.g.toDouble());
        out[i++] = _quantize(p.b.toDouble());
      }
    }
    return out;
  }

  Float32List _imageToFloat32(img.Image im) {
    final out = Float32List(_inH * _inW * 3);
    int i = 0;
    for (int y = 0; y < _inH; y++) {
      for (int x = 0; x < _inW; x++) {
        final p = im.getPixel(x, y);
        out[i++] = p.r / 255.0;
        out[i++] = p.g / 255.0;
        out[i++] = p.b / 255.0;
      }
    }
    return out;
  }

  int _quantize(double v255) {
    final scale = _q.scale == 0 ? (1 / 255.0) : _q.scale;
    final zp = _q.zeroPoint;
    final q = (v255 / scale + zp).round();
    return q.clamp(0, 255);
  }
}

extension _Reshape on Float32List {
  List reshape(List<int> shape) => this;
}