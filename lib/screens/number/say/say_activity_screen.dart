import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Progress;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/number_api_service.dart';
import 'package:ganithamithura/services/learning_flow_manager.dart';
import 'package:ganithamithura/services/tts_service.dart';

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
  final _apiService = NumApiService.instance;
  final _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _speechAvailable = false;
  String _recognizedText = '';
  bool? _result;
  late AnimationController _micAnimationController;
  String? _statusMessage;
  Color? _statusColor;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Delay initialization to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSpeech();
      // Pronounce the number aloud so the student knows what to say
      Future.delayed(const Duration(milliseconds: 800), () {
        _pronounceNumber();
      });
    });
  }

  /// Speak the number aloud using TTS so the student can hear the pronunciation
  Future<void> _pronounceNumber() async {
    final word = NumberWords.getWord(widget.currentNumber);
    await TTSService.instance.speak(
        'The number is ${widget.currentNumber}. Say: $word');
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    // Properly cleanup speech service
    _speech.cancel(); // Cancel any ongoing recognition
    _speech.stop(); // Stop the service
    super.dispose();
  }

  void _showErrorSnackbar(String title, String message, Color backgroundColor) {
    if (!mounted) return;

    // Update state to show error in UI
    setState(() {
      _statusMessage = message;
      _statusColor = backgroundColor;
    });

    // Also try to show snackbar
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(message),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Error showing snackbar: $e');
    }

    // Clear status message after delay
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
          _statusColor = null;
        });
      }
    });
  }

  Future<void> _initSpeech() async {
    // Ensure any previous session is cleaned up first
    try {
      await _speech.cancel();
      await _speech.stop();
    } catch (e) {
      debugPrint('Speech cleanup on init: $e');
    }

    // Request microphone permission
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');

          // Always update the field — even if not mounted the mic button
          // must not stay stuck in the green/listening state.
          _isListening = false;
          if (!mounted) return;
          setState(() {});

          // Store error to show in UI instead of immediate snackbar
          String title = 'Error';
          String message = 'Please try again';

          if (error.errorMsg == 'error_no_match') {
            title = 'Could not understand';
            message =
                'Please speak clearly and say "${NumberWords.getWord(widget.currentNumber)}"';
          } else if (error.errorMsg == 'error_network') {
            title = 'Network Error';
            message = 'Please check your internet connection';
          } else {
            title = 'Recognition Error';
            message = 'Speech recognition failed. Please try again.';
          }

          // Show error after a delay to ensure context is ready
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _showErrorSnackbar(title, message, Color(AppColors.errorColor));
            }
          });
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');

          if (status == 'done' || status == 'notListening') {
            // Always update the field so the button reflects reality,
            // even when mounted happens to be false at this instant.
            _isListening = false;
            if (!mounted) return;
            setState(() {});

            // When speech recognition finishes, check the result if we have text
            if (status == 'done' && _recognizedText.isNotEmpty && _result == null) {
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) {
                  _checkResult();
                }
              });
            }
          }
        },
      );

      if (mounted) {
        setState(() {});
      }
    } else {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showErrorSnackbar(
              'Permission Required',
              'Microphone permission is needed for this activity',
              Color(AppColors.errorColor),
            );
          }
        });
      }
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
            SingleChildScrollView(
              child: Padding(
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

                    const SizedBox(height: 16),

                    // Hear-it-again button so the student can re-listen to the pronunciation
                    OutlinedButton.icon(
                      onPressed: _pronounceNumber,
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Hear it again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(AppColors.numberColor),
                        side: BorderSide(color: Color(AppColors.numberColor)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Microphone button
                    _buildMicrophoneButton(),

                    const SizedBox(height: 32),

                    // Status text
                    if (_isListening || _speech.isListening)
                      const Text(
                        'Listening...',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
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

                    // Status/Error message display
                    if (_statusMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _statusColor ?? Color(AppColors.errorColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_statusMessage != null) const SizedBox(height: 16),

                    // Instructions card
                    if (!_speechAvailable)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppConstants.standardPadding,
                          ),
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
                          padding: const EdgeInsets.all(
                            AppConstants.standardPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Color(AppColors.infoColor),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'How to play:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '1. Tap the microphone button\n'
                                '2. Say "${NumberWords.getWord(widget.currentNumber)}" clearly\n'
                                '3. Speak at a normal volume\n'
                                '4. Avoid background noise',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Result overlay
            if (_result != null)
              _result!
                  ? SuccessAnimation(
                      message: 'Great job! Perfect pronunciation!',
                      onComplete: _onSuccess,
                    )
                  : FailureAnimation(
                      message: 'Try again! Listen carefully and repeat.',
                      onRetry: _resetActivity,
                      onGoBack: _goBackToLearning,
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    // Use the plugin's own isListening as the authoritative source of truth.
    // _isListening is only an optimistic flag; async native callbacks may
    // arrive between frames and leave it stale.
    final isActive = _isListening || _speech.isListening;
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
              color: isActive
                  ? Color(
                      AppColors.successColor,
                    ).withOpacity(0.2 + (_micAnimationController.value * 0.3))
                  : _speechAvailable
                  ? Color(AppColors.numberColor).withOpacity(0.2)
                  : Color(AppColors.disabledColor).withOpacity(0.2),
              border: Border.all(
                color: isActive
                    ? Color(AppColors.successColor)
                    : _speechAvailable
                    ? Color(AppColors.numberColor)
                    : Color(AppColors.disabledColor),
                width: 4,
              ),
            ),
            child: Icon(
              isActive ? Icons.mic : Icons.mic_none,
              size: 60,
              color: isActive
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
      // Provide haptic feedback when stopping microphone
      HapticFeedback.heavyImpact();
      
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      
      // Check result if we have recognized text
      if (_recognizedText.isNotEmpty && _result == null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _checkResult();
          }
        });
      }
    } else {
      setState(() {
        _recognizedText = '';
        _result = null;
      });
      
      // Provide haptic feedback when starting microphone
      HapticFeedback.heavyImpact();
      
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(milliseconds: 2000),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );

      setState(() {
        _isListening = true;
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _recognizedText = result.recognizedWords.toLowerCase();
      _isListening = false;
    });

    if (result.finalResult) {
      _checkResult();
    }
  }

  void _checkResult() {
    final targetWord = NumberWords.getWord(widget.currentNumber).toLowerCase();

    // Normalize: speech engines often return digits ("7") instead of words
    // ("seven"). Convert digit strings to their word equivalent before comparing.
    String recognizedWord = _recognizedText.toLowerCase().trim();
    final asInt = int.tryParse(recognizedWord);
    if (asInt != null) {
      final asWord = NumberWords.getWord(asInt);
      if (asWord.isNotEmpty) recognizedWord = asWord;
    }

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

      // Submit to backend (non-blocking with proper error handling)
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
              debugPrint('Score submission timed out - will retry later');
              return <String, dynamic>{'status': 'timeout'};
            },
          )
          .catchError((e) {
            debugPrint('Error submitting score: $e');
            return <String, dynamic>{'status': 'error', 'error': e.toString()};
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

    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

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
      _recognizedText = '';
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
