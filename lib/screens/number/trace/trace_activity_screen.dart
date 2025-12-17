import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Progress;
import 'dart:ui' as ui;
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/api_service.dart';
import 'package:ganithamithura/screens/number/read/read_activity_screen.dart';

/// TraceActivityScreen - Trace numbers with drawing canvas
class TraceActivityScreen extends StatefulWidget {
  final Activity activity;
  final List<Activity> allActivities;
  final int currentNumber;
  final LearningLevel level;
  
  const TraceActivityScreen({
    super.key,
    required this.activity,
    required this.allActivities,
    required this.currentNumber,
    required this.level,
  });
  
  @override
  State<TraceActivityScreen> createState() => _TraceActivityScreenState();
}

class _TraceActivityScreenState extends State<TraceActivityScreen> {
  final List<Offset> _points = [];
  final _storageService = StorageService.instance;
  final _apiService = ApiService.instance;
  
  bool _isChecking = false;
  bool? _result;
  
  // Target area bounds (simplified for demonstration)
  late Rect _targetBounds;
  Set<Offset> _coveredPoints = {};
  
  @override
  void initState() {
    super.initState();
    // Initialize target bounds (centered number area)
    _targetBounds = const Rect.fromLTWH(50, 100, 300, 400);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text('Trace ${widget.currentNumber}'),
        backgroundColor: Color(AppColors.numberColor),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearDrawing,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(AppConstants.standardPadding),
              color: Color(AppColors.numberColor).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Color(AppColors.numberColor),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Trace the number with your finger',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Drawing canvas
            Expanded(
              child: Stack(
                children: [
                  // Background with dotted number outline
                  Center(
                    child: _buildDottedNumberOutline(),
                  ),
                  
                  // Drawing canvas
                  GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: _DrawingPainter(_points),
                      size: Size.infinite,
                    ),
                  ),
                  
                  // Result overlay
                  if (_result != null)
                    _result!
                        ? SuccessAnimation(
                            message: 'Perfect!',
                            onComplete: _onSuccess,
                          )
                        : FailureAnimation(
                            message: 'Try tracing more carefully',
                            onRetry: _clearDrawing,
                          ),
                ],
              ),
            ),
            
            // Check button
            Container(
              padding: const EdgeInsets.all(AppConstants.standardPadding),
              child: Column(
                children: [
                  // Coverage indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Coverage: ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${(_getCoverage() * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getCoverageColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ActionButton(
                    text: 'Check My Trace',
                    icon: Icons.check_circle,
                    isEnabled: !_isChecking && _points.length > 10,
                    onPressed: _checkTrace,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDottedNumberOutline() {
    // TODO: Phase 2 - Load actual dotted SVG/PNG assets
    // For now, show large number
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(
          color: Color(AppColors.numberColor).withOpacity(0.3),
          width: 4,
          style: BorderStyle.none, // We'll use CustomPaint for dots
        ),
      ),
      child: CustomPaint(
        painter: _DottedNumberPainter(widget.currentNumber),
        child: SizedBox(
          width: 300,
          height: 400,
        ),
      ),
    );
  }
  
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _points.add(details.localPosition);
      _updateCoverage(details.localPosition);
    });
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _points.add(details.localPosition);
      _updateCoverage(details.localPosition);
    });
  }
  
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _points.add(Offset.infinite); // Marker for stroke end
    });
  }
  
  void _updateCoverage(Offset point) {
    // Simplified coverage tracking - add to covered points
    _coveredPoints.add(Offset(
      (point.dx / 10).floor() * 10.0,
      (point.dy / 10).floor() * 10.0,
    ));
  }
  
  double _getCoverage() {
    // Simplified coverage calculation
    // In real implementation, compare with target path
    if (_points.isEmpty) return 0.0;
    
    final coverage = _coveredPoints.length / 500; // Approximate target points
    return coverage.clamp(0.0, 1.0);
  }
  
  Color _getCoverageColor() {
    final coverage = _getCoverage();
    if (coverage >= AppConstants.traceSuccessThreshold) {
      return Color(AppColors.successColor);
    } else if (coverage >= 0.5) {
      return Color(AppColors.warningColor);
    }
    return Color(AppColors.errorColor);
  }
  
  void _clearDrawing() {
    setState(() {
      _points.clear();
      _coveredPoints.clear();
      _result = null;
    });
  }
  
  Future<void> _checkTrace() async {
    setState(() {
      _isChecking = true;
    });
    
    // Calculate coverage
    final coverage = _getCoverage();
    final passed = coverage >= AppConstants.traceSuccessThreshold;
    
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (passed) {
      // Save progress
      final progress = Progress(
        activityId: widget.activity.id,
        score: (coverage * 100).toInt(),
        isCompleted: true,
        completedAt: DateTime.now(),
        additionalData: {
          'coverage': coverage,
          'points': _points.length,
        },
      );
      
      await _storageService.saveCompletedActivity(progress);
      
      // Submit to backend (non-blocking)
      _apiService.submitActivityScore(
        activityId: widget.activity.id,
        score: progress.score,
        isCompleted: true,
        additionalData: progress.additionalData,
      ).catchError((e) {
        debugPrint('Error submitting score: $e');
      });
    }
    
    setState(() {
      _isChecking = false;
      _result = passed;
    });
  }
  
  void _onSuccess() {
    // Navigate to next activity
    final numberActivities = widget.allActivities
        .where((a) => a.number == widget.currentNumber)
        .toList();
    
    numberActivities.sort((a, b) => a.order.compareTo(b.order));
    
    final currentIndex = numberActivities.indexWhere((a) => a.id == widget.activity.id);
    
    if (currentIndex >= 0 && currentIndex < numberActivities.length - 1) {
      final nextActivity = numberActivities[currentIndex + 1];
      
      // Navigate to Read activity
      Get.off(() => ReadActivityScreen(
        activity: nextActivity,
        allActivities: widget.allActivities,
        currentNumber: widget.currentNumber,
        level: widget.level,
      ));
    }
  }
}

/// CustomPainter for drawing strokes
class _DrawingPainter extends CustomPainter {
  final List<Offset> points;
  
  _DrawingPainter(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(AppColors.numberColor)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}

/// CustomPainter for dotted number outline
class _DottedNumberPainter extends CustomPainter {
  final int number;
  
  _DottedNumberPainter(this.number);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(AppColors.numberColor).withOpacity(0.3)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    // Draw dotted outline of number
    // TODO: Phase 2 - Use actual number paths from assets
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          fontSize: 280,
          fontWeight: FontWeight.bold,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, 
             (size.height - textPainter.height) / 2),
    );
  }
  
  @override
  bool shouldRepaint(covariant _DottedNumberPainter oldDelegate) {
    return oldDelegate.number != number;
  }
}
