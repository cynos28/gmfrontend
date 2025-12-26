import 'dart:io';
import 'dart:math' as math;
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

  late final List<int> _outShape; // [1, C, N] or [1, N, C]
  late final bool _channelsFirst; // true: [1,C,N], false: [1,N,C]
  late final int _ch; // C
  late final int _n;  // N

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
    final inShape = inT.shape; // [1,H,W,3]

    if (inT.type != TensorType.float32) {
      throw StateError('Expected float32 input, got ${inT.type}');
    }
    if (inShape.length != 4 || inShape[0] != 1 || inShape[3] != 3) {
      throw StateError('Unsupported input shape: $inShape');
    }

    _inH = inShape[1];
    _inW = inShape[2];

    final labelsRaw = await rootBundle.loadString(labelsAsset);
    _labels = labelsRaw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final outT = _interpreter.getOutputTensor(0);
    if (outT.type != TensorType.float32) {
      throw StateError('Expected float32 output, got ${outT.type}');
    }

    _outShape = outT.shape; // [1,C,N] or [1,N,C]
    if (_outShape.length != 3 || _outShape[0] != 1) {
      throw StateError('Unsupported output shape: $_outShape');
    }

    final a = _outShape[1];
    final b = _outShape[2];
    final nc = _labels.length;

    // YOLO head usually C = 4+nc OR 5+nc
    final channelsFirstCandidate = (a == 4 + nc) || (a == 5 + nc);
    final channelsLastCandidate = (b == 4 + nc) || (b == 5 + nc);

    if (!channelsFirstCandidate && !channelsLastCandidate) {
      throw StateError(
        'Output shape $_outShape does not match YOLO layout for nc=$nc',
      );
    }

    _channelsFirst = channelsFirstCandidate;
    _ch = _channelsFirst ? a : b;
    _n = _channelsFirst ? b : a;

    _loaded = true;

    debugPrint('✅ YOLO loaded');
    debugPrint('   input : $inShape type=${inT.type}');
    debugPrint('   output: $_outShape type=${outT.type}');
    debugPrint('   labels: ${_labels.length}');
    debugPrint('   layout: ${_channelsFirst ? "[1,C,N]" : "[1,N,C]"}  C=$_ch N=$_n');
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

    final original = img.bakeOrientation(decoded);
    final origW = original.width.toDouble();
    final origH = original.height.toDouble();

    final lb = _letterbox(original, _inW, _inH);
    final inputImage = lb.image;

    // ✅ Build REAL 4D input: [1][H][W][3]
    final input = List.generate(
      1,
      (_) => List.generate(
        _inH,
        (y) => List.generate(
          _inW,
          (x) {
            final p = inputImage.getPixel(x, y);
            return <double>[
              p.r.toDouble() / 255.0,
              p.g.toDouble() / 255.0,
              p.b.toDouble() / 255.0,
            ];
          },
          growable: false,
        ),
        growable: false,
      ),
      growable: false,
    );

    // ✅ Build REAL output 3D with correct shape
    final out = List.generate(
      _outShape[0], // should be 1
      (_) => List.generate(
        _outShape[1],
        (_) => List<double>.filled(_outShape[2], 0.0),
        growable: false,
      ),
      growable: false,
    );

    _interpreter.run(input, out);

    final raw = _decodeFrom3D(
      out,
      confThreshold: confThreshold,
    );

    debugPrint('🔍 Raw detections: ${raw.length}');
    for (int i = 0; i < math.min(3, raw.length); i++) {
      final d = raw[i];
      final label = (d.classId >= 0 && d.classId < _labels.length) ? _labels[d.classId] : 'unknown';
      debugPrint('📊 Detection $i: $label (${d.classId}) conf=${d.score.toStringAsFixed(3)} box=${d.box}');
    }

    if (raw.isEmpty) return const [];
    raw.sort((a, b) => b.score.compareTo(a.score));
    if (raw.length > maxRaw) raw.removeRange(maxRaw, raw.length);

    final kept = _nms(raw, iouThreshold);

    debugPrint('🎯 After NMS: ${kept.length} detections');
    for (int i = 0; i < kept.length; i++) {
      final d = kept[i];
      final label = (d.classId >= 0 && d.classId < _labels.length) ? _labels[d.classId] : 'unknown';
      debugPrint('✨ Final $i: $label conf=${d.score.toStringAsFixed(3)}');
    }

    final results = <Detection>[];
    for (final d in kept) {
      final mapped = _undoLetterbox(d.box, lb, origW, origH);
      if (mapped.width <= 1 || mapped.height <= 1) continue;

      final label = (d.classId >= 0 && d.classId < _labels.length)
          ? _labels[d.classId]
          : 'class_${d.classId}';

      results.add(
        Detection(
          box: mapped,
          classId: d.classId,
          label: label,
          score: d.score,
        ),
      );
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  // ---------------- Decode ----------------

  List<_RawDet> _decodeFrom3D(
    List<List<List<double>>> out, {
    required double confThreshold,
  }) {
    final nc = _labels.length;

    final hasObj = (_ch == 5 + nc);
    final clsStart = hasObj ? 5 : 4;

    double getAt(int c, int i) {
      return _channelsFirst ? out[0][c][i] : out[0][i][c];
    }

    // Detect logits vs probabilities
    bool looksLikeLogits = false;
    for (int k = 0; k < math.min(200, _n); k++) {
      final v = getAt(clsStart, k);
      if (v < 0.0 || v > 1.0) {
        looksLikeLogits = true;
        break;
      }
    }
    double sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

    final raw = <_RawDet>[];

    for (int i = 0; i < _n; i++) {
      double x = getAt(0, i);
      double y = getAt(1, i);
      double w = getAt(2, i);
      double h = getAt(3, i);

      double obj = hasObj ? getAt(4, i) : 1.0;
      if (hasObj && looksLikeLogits) obj = sigmoid(obj);

      double best = -1e9;
      int bestId = -1;

      for (int c = 0; c < nc; c++) {
        double s = getAt(clsStart + c, i);
        if (looksLikeLogits) s = sigmoid(s);
        if (s > best) {
          best = s;
          bestId = c;
        }
      }

      final conf = obj * best;
      if (i < 5) { // Debug first few predictions
        debugPrint('🧮 Pred[$i]: obj=$obj, best=$best, conf=$conf, class=$bestId, thresh=$confThreshold');
      }
      if (bestId < 0 || conf < confThreshold) continue;

      // normalized or pixel coords
      final looksNormalized =
          x >= 0 && x <= 1.5 && y >= 0 && y <= 1.5 && w >= 0 && w <= 1.5 && h >= 0 && h <= 1.5;

      if (looksNormalized) {
        x *= _inW.toDouble();
        w *= _inW.toDouble();
        y *= _inH.toDouble();
        h *= _inH.toDouble();
      }

      final left = x - w / 2;
      final top = y - h / 2;
      final right = x + w / 2;
      final bottom = y + h / 2;

      final l = left.clamp(0.0, _inW.toDouble());
      final t = top.clamp(0.0, _inH.toDouble());
      final r = right.clamp(0.0, _inW.toDouble());
      final b = bottom.clamp(0.0, _inH.toDouble());

      if (r <= l || b <= t) continue;

      raw.add(_RawDet(
        box: Rect.fromLTRB(l, t, r, b),
        classId: bestId,
        score: conf,
      ));
    }

    return raw;
  }

  // ---------------- NMS ----------------

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
    final left = math.max(a.left, b.left);
    final top = math.max(a.top, b.top);
    final right = math.min(a.right, b.right);
    final bottom = math.min(a.bottom, b.bottom);

    final w = math.max(0.0, right - left);
    final h = math.max(0.0, bottom - top);
    final inter = w * h;

    final union = a.width * a.height + b.width * b.height - inter;
    if (union <= 0) return 0.0;
    return inter / union;
  }

  // ---------------- Letterbox ----------------

  _LetterboxResult _letterbox(img.Image src, int dstW, int dstH) {
    final srcW = src.width.toDouble();
    final srcH = src.height.toDouble();

    final scale = math.min(dstW / srcW, dstH / srcH);
    final newW = (srcW * scale).round();
    final newH = (srcH * scale).round();

    final resized = img.copyResize(src, width: newW, height: newH);

    final canvas = img.Image(width: dstW, height: dstH);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));

    final padX = ((dstW - newW) / 2).round();
    final padY = ((dstH - newH) / 2).round();

    img.compositeImage(canvas, resized, dstX: padX, dstY: padY);

    return _LetterboxResult(
      image: canvas,
      scale: scale,
      padX: padX,
      padY: padY,
      newW: newW,
      newH: newH,
    );
  }

  Rect _undoLetterbox(
    Rect boxInInput,
    _LetterboxResult lb,
    double origW,
    double origH,
  ) {
    final l = (boxInInput.left - lb.padX) / lb.scale;
    final t = (boxInInput.top - lb.padY) / lb.scale;
    final r = (boxInInput.right - lb.padX) / lb.scale;
    final b = (boxInInput.bottom - lb.padY) / lb.scale;

    return Rect.fromLTRB(
      l.clamp(0.0, origW),
      t.clamp(0.0, origH),
      r.clamp(0.0, origW),
      b.clamp(0.0, origH),
    );
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

class _LetterboxResult {
  final img.Image image;
  final double scale;
  final int padX;
  final int padY;
  final int newW;
  final int newH;

  _LetterboxResult({
    required this.image,
    required this.scale,
    required this.padX,
    required this.padY,
    required this.newW,
    required this.newH,
  });
}