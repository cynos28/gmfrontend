import 'dart:ui';
import 'package:flutter/material.dart';

Widget buildWordChip(String name, {bool isFeedback = false}) {
  return Container(
    width: 100,
    height: 35,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: const Color(0xFF36D399), width: 1.0),
    ),
    alignment: Alignment.center,
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

class AnswerQuestionsGameCard extends StatefulWidget {
  final int cardIndex;
  final String imagePath;
  final Function(int, String) onShapeDropped;
  final String? droppedShape;

  const AnswerQuestionsGameCard({
    Key? key,
    required this.cardIndex,
    required this.imagePath,
    required this.onShapeDropped,
    this.droppedShape,
  }) : super(key: key);

  @override
  State<AnswerQuestionsGameCard> createState() => _AnswerQuestionsGameCardState();
}

class _AnswerQuestionsGameCardState extends State<AnswerQuestionsGameCard> {
  @override
  Widget build(BuildContext context) {
    bool isDropped = widget.droppedShape != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Question Image Container
        Container(
          width: 146,
          height: 110, // Reduced from 131 to save space
          decoration: BoxDecoration(
            color: const Color(0xFFEFF0F1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.contain, 
              width: 80, // Reduced from 100
              height: 80, // Reduced from 100
            ),
          ),
        ),
        const SizedBox(height: 25), // Reduced from 30
        
        // The Drop Area (DragTarget)
        DragTarget<String>(
          onAcceptWithDetails: (data) {
            widget.onShapeDropped(widget.cardIndex, data.data);
          },
          builder: (BuildContext context, List<String?> candidateData, List rejectedData) {
            return CustomPaint(
              painter: _DashedBorderPainter(
                color: Colors.black.withOpacity(0.2),
                strokeWidth: 1.0,
                gap: 10.0,
                dash: 10.0,
                borderRadius: 15.0,
              ),
              child: Container(
                width: 260, // Reduced from 269
                height: 90, // Reduced from 113 to save space
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: isDropped
                      ? buildWordChip(widget.droppedShape!)
                      : const Text(
                          "Drop here",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class AnswerQuestionsWordPool extends StatelessWidget {
  final List<String> shapeNames;

  const AnswerQuestionsWordPool({
    Key? key,
    required this.shapeNames,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: shapeNames.map((name) {
          return Draggable<String>(
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
