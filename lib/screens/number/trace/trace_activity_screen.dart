import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart' hide Progress;
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/number_api_service.dart';
import 'package:ganithamithura/services/learning_flow_manager.dart';

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
  final _apiService = NumApiService.instance;

  bool _isChecking = false;
  bool? _result;
  String? _feedbackMessage;

  // Canvas key for capturing image
  final GlobalKey _canvasKey = GlobalKey();

  // Key for the number outline widget (used to restrict drawing area in learning mode)
  final GlobalKey _outlineKey = GlobalKey();

  @override
  void initState() {
    super.initState();
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _clearDrawing),
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
                  Icon(Icons.touch_app, color: Color(AppColors.numberColor)),
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
                      child: Center(
                        child: Container(
                          width: 350,
                          height: 350,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color:
                                  Color(AppColors.numberIcon).withOpacity(0.3),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(AppColors.numberIcon)
                                    .withOpacity(0.15),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Stack(
                              children: [
                                // Background with dotted number outline
                                Center(child: _buildDottedNumberOutline()),

                                // Drawing canvas
                                GestureDetector(
                                  onPanStart: _onPanStart,
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: _onPanEnd,
                                  child: RepaintBoundary(
                                    key: _canvasKey,
                                    child: CustomPaint(
                                      painter: _DrawingPainter(
                                        _points,
                                        includeBackground: false,
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Check button
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: ActionButton(
                        text: _isChecking ? 'Recognizing...' : 'Check My Digit',
                        icon: _isChecking
                            ? Icons.hourglass_empty
                            : Icons.check_circle,
                        isEnabled: !_isChecking && _points.length > 10,
                        onPressed: _checkTrace,
                      ),
                    ),
                  ],
                ),
                // Result overlay
                if (_result != null)
                  _result!
                      ? SuccessAnimation(
                          message: _feedbackMessage ?? 'Great job!',
                          onComplete: _onSuccess,
                        )
                      : FailureAnimation(
                          message: _feedbackMessage ?? 'Try again!',
                          onRetry: _clearDrawing,
                          onGoBack: _goBackToLearning,
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedNumberOutline() {
    // For now, show large number
    return Container(
      key: _outlineKey,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: CustomPaint(
        painter: _DottedNumberPainter(widget.currentNumber),
        child: SizedBox(width: 300, height: 400),
      ),
    );
  }

  /// Returns true if [globalPos] falls within the number outline widget bounds.
  /// Drawing is always restricted to the outline box in TraceActivityScreen
  /// (learning mode). The progress test uses TraceQuestionWidget instead.
  bool _isWithinOutline(Offset globalPos) {
    final renderBox =
        _outlineKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return true; // Fallback: allow if not ready
    final local = renderBox.globalToLocal(globalPos);
    final size = renderBox.size;
    return local.dx >= 0 &&
        local.dy >= 0 &&
        local.dx <= size.width &&
        local.dy <= size.height;
  }

  void _onPanStart(DragStartDetails details) {
    // Only accept touch points that fall within the number outline area
    if (!_isWithinOutline(details.globalPosition)) return;
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Only accept touch points that fall within the number outline area
    if (!_isWithinOutline(details.globalPosition)) return;
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _points.add(Offset.infinite); // Marker for stroke end
    });
  }

  /// Capture canvas as image
  Future<Uint8List?> _captureCanvasImage() async {
    try {
      // Get the actual render box size
      final RenderBox? renderBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        debugPrint('Error: Could not get render box');
        return null;
      }

      final size = renderBox.size;
      debugPrint('Canvas size: ${size.width} x ${size.height}');

      // Create a custom painter with BLACK background and WHITE strokes for MNIST
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw BLACK background (MNIST expects white digits on black)
      final backgroundPaint = Paint()..color = Colors.black;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        backgroundPaint,
      );

      // Draw strokes in WHITE
      final strokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 28.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != Offset.infinite &&
            _points[i + 1] != Offset.infinite) {
          canvas.drawLine(_points[i], _points[i + 1], strokePaint);
        }
      }

      final picture = recorder.endRecording();

      // Use the actual canvas size for the image
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
      return null;
    }
  }

  void _clearDrawing() {
    setState(() {
      _points.clear();
      _result = null;
    });
  }

  Future<void> _checkTrace() async {
    // Validate that there's actual drawing
    if (_points.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please draw the number ${widget.currentNumber} first'),
          backgroundColor: Color(AppColors.warningColor),
        ),
      );
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      // Add small delay to ensure rendering is complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture canvas as image
      final imageBytes = await _captureCanvasImage();

      if (imageBytes == null) {
        throw Exception('Failed to capture drawing');
      }

      debugPrint('📸 Captured drawing: ${imageBytes.length} bytes');
      debugPrint('📊 Points drawn: ${_points.length}');

      // Recognize digit using ML
      final result = await _apiService.recognizeDigit(
        imageBytes: imageBytes,
        expectedDigit: widget.currentNumber,
        confidenceThreshold: 0.5, // Lower threshold for handwriting
      );

      final passed = result.isCorrect ?? false;

      setState(() {
        _feedbackMessage = result.feedback;
      });

      if (passed) {
        // Save progress
        final progress = Progress(
          activityId: widget.activity.id,
          score: (result.confidence * 100).toInt(),
          isCompleted: true,
          completedAt: DateTime.now(),
          additionalData: {
            'predicted_digit': result.predictedDigit,
            'confidence': result.confidence,
            'expected_digit': widget.currentNumber,
          },
        );

        await _storageService.saveCompletedActivity(progress);

        // Submit to backend (non-blocking)
        _apiService
            .submitActivityScore(
          activityId: widget.activity.id,
          score: progress.score,
          isCompleted: true,
          additionalData: progress.additionalData,
        )
            .timeout(
          Duration(seconds: AppConstants.apiTimeout),
          onTimeout: () {
            debugPrint('Score submission timed out');
            return <String, dynamic>{'status': 'timeout'};
          },
        ).catchError((e) {
          debugPrint('Error submitting score: $e');
          return <String, dynamic>{
            'status': 'error',
            'error': e.toString(),
          };
        });
      }

      setState(() {
        _isChecking = false;
        _result = passed;
      });
    } catch (e) {
      debugPrint('❌ Recognition error: $e');
      setState(() {
        _isChecking = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recognition failed: $e'),
            backgroundColor: Color(AppColors.errorColor),
          ),
        );
      }
    }
  }

  void _onSuccess() async {
    // Use LearningFlowManager to move to next activity
    final learningFlowManager = LearningFlowManager.instance;

    try {
      await learningFlowManager.moveToNextActivity(
        currentActivity: widget.activity,
        currentNumber: widget.currentNumber,
        level: widget.level,
        isTutorial: true,
      );
    } catch (e) {
      debugPrint('❌ Error in moveToNextActivity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completed! Error navigating: $e'),
            backgroundColor: Color(AppColors.errorColor),
          ),
        );
      }
    }
  }

  /// Navigate back to the first activity for this number (learning restart)
  void _goBackToLearning() async {
    setState(() {
      _result = null;
      _points.clear();
    });
    final learningFlowManager = LearningFlowManager.instance;
    try {
      await learningFlowManager.startLearningFromNumber(
        level: widget.level.levelNumber,
        startNumber: widget.currentNumber,
        levelData: widget.level,
        isTutorial: true,
      );
    } catch (e) {
      debugPrint('❌ Error going back to learning: $e');
    }
  }
}

/// CustomPainter for drawing strokes
class _DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final bool includeBackground;

  _DrawingPainter(this.points, {this.includeBackground = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw white background only when capturing
    if (includeBackground) {
      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        backgroundPaint,
      );
    }

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
    return true; // Always repaint when points change
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
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          fontSize: 400,
          fontFamily: 'Staatliches',
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DottedNumberPainter oldDelegate) {
    return oldDelegate.number != number;
  }
}
