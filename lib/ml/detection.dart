import 'dart:ui' show Rect;

class Detection {
  final Rect box; // original image coordinates
  final int classId;
  final String label;
  final double score;

  Detection({
    required this.box,
    required this.classId,
    required this.label,
    required this.score,
  });
}