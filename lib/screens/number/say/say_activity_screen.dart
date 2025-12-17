import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Progress;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/api_service.dart';
import 'package:ganithamithura/screens/number/object_detection/object_detection_activity_screen.dart';

/// SayActivityScreen - Voice recognition activity
class SayActivityScreen extends StatefulWidget {
  final Activity activity;
  final List<Activity> allActivities;
  final int currentNumber;
  final LearningLevel level;
  
  const SayActivityScreen({
    super.key,
    required this.activity,
    required this.allActivities,
    required this.currentNumber,
    required this.level,
  });
  
  @override
  State<SayActivityScreen> createState() => _SayActivityScreenState();
}

class _SayActivityScreenState extends State<SayActivityScreen>
    with SingleTickerProviderStateMixin {
  final _storageService = StorageService.instance;
  final _apiService = ApiService.instance;
  final _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _speechAvailable = false;
  String _recognizedText = '';
  bool? _result;
  late AnimationController _micAnimationController;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _micAnimationController.dispose();
    _speech.stop();
    super.dispose();
  }
  
  Future<void> _initSpeech() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    
    if (status.isGranted) {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          setState(() {
            _isListening = false;
          });
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      
      setState(() {});
    } else {
      Get.snackbar(
        'Permission Required',
        'Microphone permission is needed for this activity',
        backgroundColor: Color(AppColors.errorColor),
        colorText: Colors.white,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Say Activity'),
        backgroundColor: Color(AppColors.numberColor),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.standardPadding * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Instructions
                  const Text(
                    'Say the number aloud',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Number display
                  NumberDisplay(
                    number: widget.currentNumber,
                    word: NumberWords.getWord(widget.currentNumber),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Microphone button
                  _buildMicrophoneButton(),
                  
                  const SizedBox(height: 32),
                  
                  // Status text
                  if (_isListening)
                    const Text(
                      'Listening...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    )
                  else if (_recognizedText.isNotEmpty)
                    Column(
                      children: [
                        const Text(
                          'You said:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recognizedText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(AppColors.numberColor),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Instructions card
                  if (!_speechAvailable)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.standardPadding),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Color(AppColors.errorColor),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Speech recognition not available. Please check permissions.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.standardPadding),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(AppColors.infoColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tap the microphone and say "${NumberWords.getWord(widget.currentNumber)}"',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Result overlay
            if (_result != null)
              _result!
                  ? SuccessAnimation(
                      message: 'Perfect pronunciation!',
                      onComplete: _onSuccess,
                    )
                  : FailureAnimation(
                      message: 'Try saying it again',
                      onRetry: _resetActivity,
                    ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onTap: _speechAvailable ? _toggleListening : null,
      child: AnimatedBuilder(
        animation: _micAnimationController,
        builder: (context, child) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening
                  ? Color(AppColors.successColor)
                      .withOpacity(0.2 + (_micAnimationController.value * 0.3))
                  : _speechAvailable
                      ? Color(AppColors.numberColor).withOpacity(0.2)
                      : Color(AppColors.disabledColor).withOpacity(0.2),
              border: Border.all(
                color: _isListening
                    ? Color(AppColors.successColor)
                    : _speechAvailable
                        ? Color(AppColors.numberColor)
                        : Color(AppColors.disabledColor),
                width: 4,
              ),
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 60,
              color: _isListening
                  ? Color(AppColors.successColor)
                  : _speechAvailable
                      ? Color(AppColors.numberColor)
                      : Color(AppColors.disabledColor),
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _recognizedText = '';
        _result = null;
      });
      
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
      );
      
      setState(() {
        _isListening = true;
      });
    }
  }
  
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _recognizedText = result.recognizedWords.toLowerCase();
    });
    
    if (result.finalResult) {
      _checkResult();
    }
  }
  
  void _checkResult() {
    final targetWord = NumberWords.getWord(widget.currentNumber).toLowerCase();
    final recognizedWord = _recognizedText.toLowerCase();
    
    // Check similarity
    final similarity = _calculateSimilarity(targetWord, recognizedWord);
    final passed = similarity >= AppConstants.speechRecognitionThreshold;
    
    if (passed) {
      // Save progress
      final progress = Progress(
        activityId: widget.activity.id,
        score: (similarity * 100).toInt(),
        isCompleted: true,
        completedAt: DateTime.now(),
        additionalData: {
          'recognized': _recognizedText,
          'target': targetWord,
          'similarity': similarity,
        },
      );
      
      _storageService.saveCompletedActivity(progress);
      
      // Submit to backend
      _apiService.submitActivityScore(
        activityId: widget.activity.id,
        score: progress.score,
        isCompleted: true,
        additionalData: progress.additionalData,
      ).catchError((e) {
        debugPrint('Error submitting score: $e');
        return <String, dynamic>{};
      });
    }
    
    setState(() {
      _result = passed;
    });
  }
  
  /// Calculate string similarity (Levenshtein distance based)
  double _calculateSimilarity(String s1, String s2) {
    // Simple similarity check - exact match or contains
    if (s1 == s2) return 1.0;
    if (s2.contains(s1) || s1.contains(s2)) return 0.85;
    
    // Levenshtein distance
    final len1 = s1.length;
    final len2 = s2.length;
    
    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );
    
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    final distance = matrix[len1][len2];
    final maxLen = len1 > len2 ? len1 : len2;
    
    return 1.0 - (distance / maxLen);
  }
  
  void _resetActivity() {
    setState(() {
      _recognizedText = '';
      _result = null;
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
      
      // Navigate to Object Detection activity
      Get.off(() => ObjectDetectionActivityScreen(
        activity: nextActivity,
        allActivities: widget.allActivities,
        currentNumber: widget.currentNumber,
        level: widget.level,
      ));
    }
  }
}
