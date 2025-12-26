import 'dart:io';
import 'dart:math';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'detection.dart';

class YoloDetectorFile {
  late final Interpreter _interpreter;
  late final List<String> _labels;

  late final int _inH;
  late final int _inW;
  late final TensorType _inType;

  late final List<int> _outShape; // e.g. [1, 24, 8400]
  late final TensorType _outType;

  bool _loaded = false;

  Future<void> load({
    String modelAsset = 'assets/models/classroom.tflite',
    String labelsAsset = 'assets/labels/classes.txt',
    int threads = 4,
  }) async {
    final opts = InterpreterOptions()
      ..threads = threads
      ..useNnApiForAndroid = false;

    _interpreter = await Interpreter.fromAsset(modelAsset, options: opts);
    _interpreter.allocateTensors();

    final inT = _interpreter.getInputTensor(0);
    _inType = inT.type;

    final inShape = inT.shape; // usually [1, H, W, 3]
    if (inShape.length == 4) {
      _inH = inShape[1];
      _inW = inShape[2];
    } else if (inShape.length == 3) {
      _inH = inShape[0];
      _inW = inShape[1];
    } else {
      throw StateError('Unsupported input shape: $inShape');
    }

    final outT = _interpreter.getOutputTensor(0);
    _outShape = outT.shape; // e.g. [1, 24, 8400]
    _outType = outT.type;

    final labelsRaw = await rootBundle.loadString(labelsAsset);
    _labels = labelsRaw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    _loaded = true;

    debugPrint('✅ YOLO loaded');
    debugPrint('   input: ${inT.shape} type=$_inType');
    debugPrint('   output: $_outShape type=$_outType');
    debugPrint('   labels: ${_labels.length}');

    // Helpful warning for your specific output [1, 24, 8400]
    if (_outShape.length == 3 && _outShape[1] == 24) {
      final maybeNcNoObj = 24 - 4; // 20
      final maybeNcWithObj = 24 - 5; // 19
      if (_labels.length != maybeNcNoObj && _labels.length != maybeNcWithObj) {
        debugPrint(
          '⚠️ labels count looks wrong for output channels=24. '
          'Expected 19 (with objectness) or 20 (no objectness), '
          'but got ${_labels.length}.',
        );
      }
    }
  }

  void close() {
    if (_loaded) _interpreter.close();
  }

  Future<List<Detection>> detectFile(
    String imagePath, {
    double confThreshold = 0.35,
    double iouThreshold = 0.45,
    int maxRaw = 300,
  }) async {
    if (!_loaded) return const [];

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return const [];

    // Fix camera EXIF rotation
    final original = img.bakeOrientation(decoded);

    final origW = original.width.toDouble();
    final origH = original.height.toDouble();

    final resized = img.copyResize(original, width: _inW, height: _inH);

    if (_inType != TensorType.float32 && _inType != TensorType.uint8) {
      throw StateError('Unsupported input type: $_inType');
    }
    if (_outType != TensorType.float32) {
      throw StateError('Unsupported output type: $_outType (expected float32)');
    }

    // Build 4D input: [1][H][W][3]
    final input = List.generate(
      1,
      (_) => List.generate(
        _inH,
        (_) => List.generate(
          _inW,
          (_) => List<double>.filled(3, 0.0),
          growable: false,
        ),
        growable: false,
      ),
      growable: false,
    );

    for (int y = 0; y < _inH; y++) {
      for (int x = 0; x < _inW; x++) {
        final p = resized.getPixel(x, y);
        if (_inType == TensorType.uint8) {
          // Even though list is double, we store 0..255 here for uint8 models.
          input[0][y][x][0] = p.r.toDouble();
          input[0][y][x][1] = p.g.toDouble();
          input[0][y][x][2] = p.b.toDouble();
        } else {
          // float32 models expect 0..1
          input[0][y][x][0] = p.r.toDouble() / 255.0;
          input[0][y][x][1] = p.g.toDouble() / 255.0;
          input[0][y][x][2] = p.b.toDouble() / 255.0;
        }
      }
    }

    // Build output as proper 3D list: outShape like [1][24][8400]
    final out = List.generate(
      _outShape[0],
      (_) => List.generate(
        _outShape[1],
        (_) => List<double>.filled(_outShape[2], 0.0),
        growable: false,
      ),
      growable: false,
    );

    // Run
    _interpreter.run(input, out);

    // Decode
    final raw = _decodeYoloFrom3D(
      out,
      outShape: _outShape,
      confThreshold: confThreshold,
    );

    if (raw.isEmpty) return const [];

    raw.sort((a, b) => b.score.compareTo(a.score));
    if (raw.length > maxRaw) raw.removeRange(maxRaw, raw.length);

    final kept = _nms(raw, iouThreshold);

    // Map input coords -> original coords
    final sx = origW / _inW;
    final sy = origH / _inH;

    return kept.map((d) {
      final bb = Rect.fromLTRB(
        d.box.left * sx,
        d.box.top * sy,
        d.box.right * sx,
        d.box.bottom * sy,
      );

      final label = (d.classId >= 0 && d.classId < _labels.length)
          ? _labels[d.classId]
          : 'class_${d.classId}';

      return Detection(
        box: bb,
        classId: d.classId,
        label: label,
        score: d.score,
      );
    }).toList();
  }

  // Supports output shapes:
  // [1, C, N] (channels-first) like [1, 24, 8400]
  // [1, N, C] (channels-last)
  List<_RawDet> _decodeYoloFrom3D(
    List<List<List<double>>> out, {
    required List<int> outShape,
    required double confThreshold,
  }) {
    if (outShape.length != 3) return const [];

    final a = outShape[1];
    final b = outShape[2];
    final nc = _labels.length;

    final channelsFirstCandidate = (a == 4 + nc) || (a == 5 + nc);
    final channelsLastCandidate = (b == 4 + nc) || (b == 5 + nc);

    final channelsFirst = channelsFirstCandidate;
    final channelsLast = !channelsFirstCandidate && channelsLastCandidate;

    if (!channelsFirst && !channelsLast) return const [];

    final ch = channelsFirst ? a : b;
    final hasObj = (ch == 5 + nc);
    final clsStart = hasObj ? 5 : 4;

    final numPred = channelsFirst ? b : a;

    double getAt(int c, int i) {
      // out[batch][channel][pred] for channels-first
      // out[batch][pred][channel] for channels-last
      return channelsFirst ? out[0][c][i] : out[0][i][c];
    }

    final raw = <_RawDet>[];

    for (int i = 0; i < numPred; i++) {
      final x = getAt(0, i);
      final y = getAt(1, i);
      final w = getAt(2, i);
      final h = getAt(3, i);

      final obj = hasObj ? getAt(4, i) : 1.0;

      double bestCls = 0.0;
      int bestId = -1;
      for (int c = 0; c < nc; c++) {
        final s = getAt(clsStart + c, i);
        if (s > bestCls) {
          bestCls = s;
          bestId = c;
        }
      }

      final conf = obj * bestCls;
      if (bestId < 0 || conf < confThreshold) continue;

      // Decide whether coords are normalized
      final normalized =
          x >= 0 && x <= 1.2 && y >= 0 && y <= 1.2 && w >= 0 && w <= 1.2 && h >= 0 && h <= 1.2;

      final sx = normalized ? _inW.toDouble() : 1.0;
      final sy = normalized ? _inH.toDouble() : 1.0;

      final cx = x * sx;
      final cy = y * sy;
      final bw = w * sx;
      final bh = h * sy;

      final left = cx - bw / 2;
      final top = cy - bh / 2;
      final right = cx + bw / 2;
      final bottom = cy + bh / 2;

      final l = left.clamp(0.0, _inW.toDouble());
      final t = top.clamp(0.0, _inH.toDouble());
      final r = right.clamp(0.0, _inW.toDouble());
      final btm = bottom.clamp(0.0, _inH.toDouble());

      if (r <= l || btm <= t) continue;

      raw.add(
        _RawDet(
          box: Rect.fromLTRB(l, t, r, btm),
          classId: bestId,
          score: conf,
        ),
      );
    }

    return raw;
  }

  List<_RawDet> _nms(List<_RawDet> dets, double iouThr) {
    final kept = <_RawDet>[];
    final used = List<bool>.filled(dets.length, false);

    for (int i = 0; i < dets.length; i++) {
      if (used[i]) continue;
      final a = dets[i];
      kept.add(a);

      for (int j = i + 1; j < dets.length; j++) {
        if (used[j]) continue;
        final b = dets[j];
        if (a.classId != b.classId) continue;
        if (_iou(a.box, b.box) > iouThr) used[j] = true;
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

    final union = a.width * a.height + b.width * b.height - inter;
    if (union <= 0) return 0.0;
    return inter / union;
  }
}

class _RawDet {
  final Rect box;
  final int classId;
  final double score;

  _RawDet({
    required this.box,
    required this.classId,
    required this.score,
  });
}