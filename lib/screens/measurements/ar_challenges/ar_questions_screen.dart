/// AR Questions Screen - Display and answer personalized questions
/// 
/// Shows contextual questions generated based on the student's actual measurement

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/models/ar_measurement.dart';
import 'package:ganithamithura/services/unit_progress_service.dart';
import 'package:ganithamithura/services/api/contextual_question_service.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/services/user_service.dart';
import 'package:ganithamithura/widgets/cute_character.dart';

class ARQuestionsScreen extends StatefulWidget {
  const ARQuestionsScreen({Key? key}) : super(key: key);

  @override
  State<ARQuestionsScreen> createState() => _ARQuestionsScreenState();
}

class _ARQuestionsScreenState extends State<ARQuestionsScreen> with SingleTickerProviderStateMixin {
  final UnitProgressService _progressService = UnitProgressService.instance;
  final ContextualQuestionService _questionService = ContextualQuestionService();
  
  late AnimationController _characterController;
  late Animation<double> _bounceAnimation;
  
  late ARMeasurement _measurement;
  late MeasurementType _measurementType;
  late MeasurementContext _measurementContext;
  
  // Adaptive mode
  bool _useAdaptiveMode = true;
  int _questionsAnswered = 0;
  final int _totalQuestions = 10;
  double _studentAbility = 0.0;
  int _currentDifficulty = 3;
  
  // Current question
  ContextualQuestion? _currentQuestion;
  bool _isLoadingQuestion = false;
  
  // Generate a unique student ID for this session to test fresh adaptive behavior
  late final String _studentId = 'student_test_${DateTime.now().millisecondsSinceEpoch}';
  
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _showFeedback = false;
  bool _isCorrect = false;
  int _correctCount = 0;
  List<bool> _hintsRevealed = [];
  
  @override
  void initState() {
    super.initState();
    
    _characterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _bounceAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _characterController, curve: Curves.easeInOut),
    );
    
    final args = Get.arguments as Map<String, dynamic>;
    _measurement = args['measurement'] as ARMeasurement;
    _measurementType = args['measurementType'] as MeasurementType;
    _measurementContext = _measurement.context!;
    
    print('📝 Measurement Questions Mode: ${_useAdaptiveMode ? "Adaptive" : "Fixed"}');
    
    if (_useAdaptiveMode) {
      _loadNextAdaptiveQuestion();
    } else {
      // Use pre-generated questions
      _currentQuestion = _measurement.questions[0];
      _hintsRevealed = List.filled(_currentQuestion!.hints.length, false);
    }
  }
  
  ContextualQuestion get currentQuestion => _currentQuestion ?? _measurement.questions[_currentQuestionIndex];
  
  bool get isLastQuestion => _questionsAnswered >= _totalQuestions - 1;
  
  Future<void> _loadNextAdaptiveQuestion() async {
    setState(() {
      _isLoadingQuestion = true;
      _selectedAnswer = null;
      _showFeedback = false;
    });
    
    try {
      final grade = await UserService.getGrade();
      final response = await _questionService.getAdaptiveMeasurementQuestion(
        measurementContext: _measurementContext,
        studentId: _studentId, // Use session-unique student ID
        grade: grade,
      );
      
      setState(() {
        _currentQuestion = response['question'] as ContextualQuestion;
        _studentAbility = response['student_ability'] as double;
        _currentDifficulty = response['target_difficulty'] as int;
        _hintsRevealed = List.filled(_currentQuestion!.hints.length, false);
        _isLoadingQuestion = false;
      });
      
      print('🎯 Loaded question (Difficulty: $_currentDifficulty, Ability: ${_studentAbility.toStringAsFixed(2)})');
      
    } catch (e) {
      print('❌ Error loading adaptive question: $e');
      setState(() {
        _isLoadingQuestion = false;
      });
      
      // Don't show snackbar during init - will cause overlay error
      // User will see loading failed in UI
    }
  }
  
  Color get _primaryColor {
    switch (_measurementType) {
      case MeasurementType.length:
        return const Color(0xFF4285F4); // Blue
      case MeasurementType.capacity:
        return const Color(0xFF00BCD4); // Cyan
      case MeasurementType.weight:
        return const Color(0xFFFF9500); // Orange
      case MeasurementType.area:
        return const Color(0xFF4CAF50); // Green
    }
  }
  
  Color get _pastelBackground {
    switch (_measurementType) {
      case MeasurementType.length:
        return const Color(0xFFE8F4FF); // Soft blue
      case MeasurementType.capacity:
        return const Color(0xFFE0F7FA); // Soft cyan
      case MeasurementType.weight:
        return const Color(0xFFFFF3E0); // Soft orange
      case MeasurementType.area:
        return const Color(0xFFE8F5E9); // Soft green
    }
  }
  
  Color get _borderColor {
    switch (_measurementType) {
      case MeasurementType.length:
        return const Color(0xFF4285F4); // Blue
      case MeasurementType.capacity:
        return const Color(0xFF00BCD4); // Cyan
      case MeasurementType.weight:
        return const Color(0xFFFF9500); // Orange
      case MeasurementType.area:
        return const Color(0xFF4CAF50); // Green
    }
  }
  
  void _checkAnswer() async {
    if (_selectedAnswer == null) {
      // Don't show snackbar - just return silently or show inline error
      return;
    }
    
    if (_useAdaptiveMode) {
      // Submit to adaptive endpoint
      try {
        final grade = await UserService.getGrade();
        final response = await _questionService.submitMeasurementAnswer(
          studentId: _studentId, // Use consistent student ID
          questionId: _currentQuestion!.questionId,
          answer: _selectedAnswer!,
          measurementType: _measurementType.name,
          grade: grade,
        );
        
        final isCorrect = response['is_correct'] as bool;
        final oldAbility = response['old_ability'] as double;
        final newAbility = response['new_ability'] as double;
        final abilityChange = response['ability_change'] as double;
        
        setState(() {
          _isCorrect = isCorrect;
          _showFeedback = true;
          _studentAbility = newAbility;
          _currentDifficulty = response['next_difficulty'] as int;
          
          if (isCorrect) {
            _correctCount++;
          }
        });
        
        print('📊 Ability: $oldAbility → $newAbility (${abilityChange >= 0 ? "+" : ""}${abilityChange.toStringAsFixed(2)})');
        print('🎚️ Next difficulty level: $_currentDifficulty');
        
      } catch (e) {
        print('❌ Error submitting answer: $e');
        // Don't show snackbar during widget lifecycle - just log error
        setState(() {
          // Show error in UI instead of snackbar
          _showFeedback = true;
          _isCorrect = false;
        });
      }
    } else {
      // Non-adaptive mode
      setState(() {
        _isCorrect = currentQuestion.isCorrect(_selectedAnswer!);
        _showFeedback = true;
        
        if (_isCorrect) {
          _correctCount++;
        }
      });
    }
    
    // Record progress
    _progressService.recordAnswer(
      unitId: 'ar_${_measurementType.name}',
      isCorrect: _isCorrect,
    );
  }
  
  void _nextQuestion() {
    setState(() {
      _questionsAnswered++;
    });
    
    // Show progress checkpoint after 5 questions
    if (_questionsAnswered == 5 && !isLastQuestion) {
      _showProgressCheckpoint();
      return;
    }
    
    if (isLastQuestion) {
      _showResults();
    } else {
      _continueToNextQuestion();
    }
  }
  
  void _continueToNextQuestion() {
    if (_useAdaptiveMode) {
      // Reset UI state and load next adaptive question
      setState(() {
        _selectedAnswer = null;
        _showFeedback = false;
        _isCorrect = false;
        _currentQuestion = null; // Clear current question
        _hintsRevealed = [];
      });
      _loadNextAdaptiveQuestion();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showFeedback = false;
        _isCorrect = false;
        _hintsRevealed = List.filled(currentQuestion.hints.length, false);
      });
    }
  }
  
  void _showProgressCheckpoint() {
    final accuracy = (_correctCount / 5 * 100).round();
    final IconData icon;
    final String title;
    final String message;
    final Color accentColor;
    
    if (accuracy >= 80) {
      icon = Icons.emoji_events_rounded;
      title = 'Amazing Work!';
      message = 'You got $_correctCount out of 5!\nYou\'re doing fantastic!';
      accentColor = const Color(0xFFFFB800); // Gold
    } else if (accuracy >= 60) {
      icon = Icons.thumb_up_rounded;
      title = 'Great Job!';
      message = 'You got $_correctCount out of 5!\nKeep going!';
      accentColor = const Color(0xFF4CAF50); // Green
    } else {
      icon = Icons.favorite_rounded;
      title = 'Keep Trying!';
      message = 'You got $_correctCount out of 5!\nLet\'s practice more together!';
      accentColor = const Color(0xFF2196F3); // Blue
    }
    
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: accentColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated icon with cute character
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.bounceOut,
                        builder: (context, bounceValue, child) {
                          return Transform.translate(
                            offset: Offset(0, -10 * (1 - bounceValue)),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glowing circle background
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        accentColor.withOpacity(0.3),
                                        accentColor.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                // Main icon circle
                                Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accentColor,
                                      width: 4,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 50,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Title with shimmer effect
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Message
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.textBlack),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Progress card with better visibility
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Progress text
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.show_chart_rounded,
                                  size: 20,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Big progress numbers
                            Text(
                              '5 / 10',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: 0.5),
                                curve: Curves.easeOut,
                                builder: (context, progressValue, child) {
                                  return LinearProgressIndicator(
                                    value: progressValue,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                    minHeight: 12,
                                  );
                                },
                              ),
                            ),
                            
                            if (_useAdaptiveMode) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Level badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.trending_up_rounded,
                                          size: 18,
                                          color: accentColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Lv $_currentDifficulty',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Skill badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.stars_rounded,
                                          size: 18,
                                          color: accentColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_studentAbility.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Ready for more text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 22,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Ready for more?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Buttons
                      Row(
                        children: [
                          // Go Back button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Get.back();
                                Get.back();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: const Color(AppColors.textBlack),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_rounded, size: 22),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Back',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Continue button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Get.back();
                                _continueToNextQuestion();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 8,
                                shadowColor: accentColor.withOpacity(0.5),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.rocket_launch_rounded, size: 24),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Let\'s Go!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  void _showResults() {
    final accuracy = (_correctCount / _measurement.questions.length * 100).round();
    final Color accentColor;
    
    if (accuracy >= 80) {
      accentColor = const Color(0xFFFFB800); // Gold
    } else if (accuracy >= 60) {
      accentColor = const Color(0xFF4CAF50); // Green
    } else {
      accentColor = const Color(0xFF2196F3); // Blue
    }
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: accentColor,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor,
                    width: 3,
                  ),
                ),
                child: Icon(
                  accuracy >= 80 ? Icons.emoji_events_rounded : accuracy >= 60 ? Icons.thumb_up_rounded : Icons.favorite_rounded,
                  color: accentColor,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                accuracy >= 80 ? 'Amazing Work!' : accuracy >= 60 ? 'Great Job!' : 'Keep Trying!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You got $_correctCount out of ${_measurement.questions.length} correct',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(AppColors.textBlack).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor, width: 3),
                ),
                child: Text(
                  '$accuracy% Accuracy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Full-width buttons stacked for better UX
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Back to measurement screen to try again
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                    shadowColor: accentColor.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Back to measurement screen
                    Get.back(); // Back to home
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade400, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    backgroundColor: Colors.grey.shade100,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  void _revealHint(int index) {
    setState(() {
      _hintsRevealed[index] = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Show loading state if question isn't loaded yet (adaptive mode)
    if (_isLoadingQuestion || (_useAdaptiveMode && _currentQuestion == null)) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(AppColors.textBlack)),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Loading Question...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.textBlack),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: _pastelBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _borderColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: _borderColor, size: 24),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        title: Column(
          key: ValueKey('ability_$_studentAbility'),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _borderColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: _borderColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _useAdaptiveMode ? 'Practice Time' : 'Let\'s Learn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _borderColor,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_useAdaptiveMode)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _borderColor.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _borderColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: _borderColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lv $_currentDifficulty',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _borderColor,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 2,
                      height: 14,
                      color: _borderColor.withOpacity(0.3),
                    ),
                    Icon(
                      Icons.stars_rounded,
                      size: 16,
                      color: _borderColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_studentAbility.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _borderColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Measurement Context Card
                    _buildContextCard(),
                    const SizedBox(height: 20),
                    
                    // Question Card
                    _buildQuestionCard(),
                    const SizedBox(height: 20),
                    
                    // Options (if MCQ)
                    if (currentQuestion.questionType == 'mcq')
                      _buildMCQOptions(),
                    
                    // Hints
                    if (currentQuestion.hints.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildHintsSection(),
                    ],
                    
                    // Feedback
                    if (_showFeedback) ...[
                      const SizedBox(height: 20),
                      _buildFeedback(),
                    ],
                  ],
                ),
              ),
            ),
            
            // Bottom button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressBar() {
    final progress = _useAdaptiveMode
        ? (_questionsAnswered / _totalQuestions)
        : ((_currentQuestionIndex + 1) / _measurement.questions.length);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _borderColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.quiz_rounded,
                    size: 20,
                    color: _borderColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Question ${_questionsAnswered + 1} of ${_useAdaptiveMode ? _totalQuestions : _measurement.questions.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _borderColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_correctCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _borderColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_borderColor),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContextCard() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: CuteCard(
            borderColor: _borderColor,
            child: Row(
              children: [
                // Cute character
                CuteCharacter(
                  size: 70,
                  color: _borderColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _measurementType.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Your ${_measurement.objectName}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(AppColors.textBlack),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _borderColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _measurement.measurementString,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _borderColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQuestionCard() {
    return CuteCard(
      borderColor: _borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _borderColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: _borderColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Question',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _borderColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _borderColor.withOpacity(0.8),
                      _borderColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(currentQuestion.difficultyLevel, (index) {
                    return const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _borderColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              currentQuestion.questionText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textBlack),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMCQOptions() {
    final options = currentQuestion.options ?? [];
    final optionLabels = ['A', 'B', 'C', 'D'];
    
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedAnswer == option;
        final isCorrectAnswer = option == currentQuestion.correctAnswer;
        
        Color buttonColor;
        Color textColor;
        Widget? trailingIcon;
        
        if (_showFeedback) {
          if (isCorrectAnswer) {
            buttonColor = Colors.green;
            textColor = Colors.white;
            trailingIcon = Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
            );
          } else if (isSelected && !_isCorrect) {
            buttonColor = Colors.red;
            textColor = Colors.white;
            trailingIcon = Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
            );
          } else {
            buttonColor = Colors.grey.shade300;
            textColor = const Color(AppColors.textBlack).withOpacity(0.5);
          }
        } else {
          buttonColor = isSelected ? _borderColor : Colors.white;
          textColor = isSelected ? Colors.white : const Color(AppColors.textBlack);
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTap: _showFeedback ? null : () {
              setState(() {
                _selectedAnswer = option;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected && !_showFeedback ? Colors.white : buttonColor,
                  width: 3,
                ),
                boxShadow: [
                  if (isSelected && !_showFeedback)
                    BoxShadow(
                      color: buttonColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected || _showFeedback
                          ? Colors.white.withOpacity(0.3)
                          : _borderColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected || _showFeedback
                            ? Colors.white.withOpacity(0.5)
                            : _borderColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        optionLabels[index % optionLabels.length],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isSelected || _showFeedback
                              ? Colors.white
                              : _borderColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 12),
                    trailingIcon,
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildHintsSection() {
    // Safety check for hints
    if (currentQuestion.hints.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD93D).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFFFFD93D),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Hints',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(AppColors.textBlack),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...currentQuestion.hints.asMap().entries.map((entry) {
          final index = entry.key;
          final hint = entry.value;
          final isRevealed = _hintsRevealed[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _revealHint(index),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isRevealed
                        ? [const Color(0xFFFFD93D).withOpacity(0.3), const Color(0xFFFFA938).withOpacity(0.3)]
                        : [Colors.white, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isRevealed ? const Color(0xFFFFD93D) : Colors.grey.shade300,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isRevealed ? const Color(0xFFFFD93D) : Colors.grey).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isRevealed
                            ? const Color(0xFFFFD93D)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRevealed ? Icons.lightbulb_rounded : Icons.lock_rounded,
                        color: isRevealed ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isRevealed ? hint : 'Tap to see Hint ${index + 1}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isRevealed ? FontWeight.w600 : FontWeight.w700,
                          color: const Color(AppColors.textBlack),
                        ),
                      ),
                    ),
                    if (!isRevealed)
                      Icon(
                        Icons.touch_app_rounded,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildFeedback() {
    final feedbackColor = _isCorrect ? Colors.green : Colors.orange;
    final icon = _isCorrect ? Icons.celebration_rounded : Icons.refresh_rounded;
    final title = _isCorrect ? 'Great Job!' : 'Try Again!';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            feedbackColor.withOpacity(0.15),
            feedbackColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: feedbackColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: feedbackColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feedbackColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: feedbackColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          if (currentQuestion.explanation != null && currentQuestion.explanation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Color(AppColors.textBlack),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentQuestion.explanation!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(AppColors.textBlack),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBottomButton() {
    final bool isDisabled = !_showFeedback && _selectedAnswer == null;
    
    String buttonText;
    IconData buttonIcon;
    
    if (_showFeedback) {
      if (isLastQuestion) {
        buttonText = 'View Results';
        buttonIcon = Icons.emoji_events_rounded;
      } else {
        buttonText = 'Next Question';
        buttonIcon = Icons.arrow_forward_rounded;
      }
    } else {
      buttonText = 'Check Answer';
      buttonIcon = Icons.check_circle_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _borderColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: isDisabled ? null : (_showFeedback ? _nextQuestion : _checkAnswer),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled ? Colors.grey.shade300 : _borderColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: isDisabled ? 0 : 8,
              shadowColor: _borderColor.withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  buttonIcon,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _characterController.dispose();
    super.dispose();
  }
}
