import 'dart:ui';
import 'package:flutter/material.dart';

Widget buildWordChip(String name, {bool isFeedback = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: const Color(0xFF36D399), width: 1.5),
    ),
    child: Text(
      name,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D4059),
      ),
    ),
  );
}

class MatchShapesGameCard extends StatefulWidget {
  final int cardIndex;
  final String imagePath;
  final Function(int, String) onShapeDropped;
  final String? droppedShape;

  const MatchShapesGameCard({
    Key? key,
    required this.cardIndex,
    required this.imagePath,
    required this.onShapeDropped,
    this.droppedShape,
  }) : super(key: key);

  @override
  State<MatchShapesGameCard> createState() => _MatchShapesGameCardState();
}

class _MatchShapesGameCardState extends State<MatchShapesGameCard> {
  @override
  Widget build(BuildContext context) {
    bool isDropped = widget.droppedShape != null;

    return CustomPaint(
      painter: _DashedBorderPainter(
        color: Colors.grey.shade400,
        strokeWidth: 1.0,
        gap: 2.0,
        dash: 2.0,
        borderRadius: 16.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(28, 10, 28, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 121,
              height: 75,
              child: Image.asset(
                widget.imagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            if (isDropped)
              buildWordChip(widget.droppedShape!)
            else
              DragTarget<String>(
                onAcceptWithDetails: (data) {
                  widget.onShapeDropped(widget.cardIndex, data.data);
                },
                builder: (BuildContext context, List<String?> candidateData, List rejectedData) {
                  return Container(
                    width: 121,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        "Drop here",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class MatchShapesWordPool extends StatelessWidget {
  final List<String> shapeNames;

  const MatchShapesWordPool({
    Key? key,
    required this.shapeNames,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create pairs of shape names for rows
    List<List<String>> rowsOfShapes = [];
    for (int i = 0; i < shapeNames.length; i += 2) {
      rowsOfShapes.add(shapeNames.sublist(i, i + 2 > shapeNames.length ? shapeNames.length : i + 2));
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 245,
        maxWidth: 245,
        minHeight: 105,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFFFF).withOpacity(1), // Opacity applied here
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rowsOfShapes.map((rowShapes) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0), // Spacing between rows
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the row horizontally
              children: rowShapes.map((name) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0), // Spacing between chips
                  child: Draggable<String>(
                    data: name,
                    feedback: Material(
                      color: Colors.transparent,
                      child: buildWordChip(name, isFeedback: true),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: buildWordChip(name),
                    ),
                    child: buildWordChip(name),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromLTRBR(
      0, 0, size.width, size.height, Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
