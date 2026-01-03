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

class ARQuestionsScreen extends StatefulWidget {
  const ARQuestionsScreen({Key? key}) : super(key: key);

  @override
  State<ARQuestionsScreen> createState() => _ARQuestionsScreenState();
}

class _ARQuestionsScreenState extends State<ARQuestionsScreen> {
  final UnitProgressService _progressService = UnitProgressService.instance;
  final ContextualQuestionService _questionService = ContextualQuestionService();
  
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
        return const Color(AppColors.numberColor);
      case MeasurementType.capacity:
        return const Color(AppColors.symbolColor);
      case MeasurementType.weight:
        return const Color(AppColors.shapeColor);
      case MeasurementType.area:
        return const Color(AppColors.measurementColor);
    }
  }
  
  Color get _borderColor {
    switch (_measurementType) {
      case MeasurementType.length:
        return const Color(AppColors.numberBorder);
      case MeasurementType.capacity:
        return const Color(AppColors.symbolBorder);
      case MeasurementType.weight:
        return const Color(AppColors.shapeBorder);
      case MeasurementType.area:
        return const Color(AppColors.measurementBorder);
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
    final String emoji;
    final String title;
    final String message;
    final Color accentColor;
    
    if (accuracy >= 80) {
      emoji = '🌟';
      title = 'Amazing Work!';
      message = 'You got $_correctCount out of 5 correct! You\'re doing fantastic!';
      accentColor = Colors.amber;
    } else if (accuracy >= 60) {
      emoji = '🎉';
      title = 'Great Job!';
      message = 'You got $_correctCount out of 5 correct! Keep going!';
      accentColor = Colors.green;
    } else {
      emoji = '💪';
      title = 'Keep Trying!';
      message = 'You got $_correctCount out of 5! Let\'s practice more together!';
      accentColor = Colors.blue;
    }
    
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent dismissing by tapping outside
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 80),
                ),
                
                const SizedBox(height: 16),
                
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(AppColors.textBlack),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '📊 Progress: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            '5 / 10 Questions',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(AppColors.textBlack),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.5,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      if (_useAdaptiveMode) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '⭐ Level $_currentDifficulty',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '| Skill: ${_studentAbility.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(AppColors.textBlack),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Question prompt
                Text(
                  '🤔 Ready for more questions?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // Go Back button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back(); // Close dialog
                          Get.back(); // Return to previous screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: const Color(AppColors.textBlack),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, size: 24),
                            SizedBox(height: 4),
                            Text(
                              'Go Back',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Continue button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back(); // Close dialog
                          _continueToNextQuestion();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.rocket_launch, size: 28),
                            SizedBox(height: 4),
                            Text(
                              'Let\'s Go!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
        ),
      ),
      barrierDismissible: false, // Must click a button
    );
  }
  
  void _showResults() {
    final accuracy = (_correctCount / _measurement.questions.length * 100).round();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  accuracy >= 70 ? Icons.emoji_events : Icons.thumb_up,
                  color: _borderColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Great Job!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textBlack),
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor, width: 1.5),
                ),
                child: Text(
                  '$accuracy% Accuracy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _borderColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Full-width buttons stacked for better UX
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Back to measurement screen to try again
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _borderColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Back to measurement screen
                    Get.back(); // Back to home
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: _borderColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(AppColors.textBlack)),
          onPressed: () => Get.back(),
        ),
        title: Column(
          key: ValueKey('ability_$_studentAbility'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _useAdaptiveMode
                  ? 'Adaptive Practice'
                  : 'Question ${_currentQuestionIndex + 1} of ${_measurement.questions.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.textBlack),
              ),
            ),
            if (_useAdaptiveMode)
              Text(
                'Level $_currentDifficulty • Ability: ${_studentAbility.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(AppColors.textBlack).withOpacity(0.6),
                ),
              ),
          ],
        ),
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
      height: 4,
      color: Colors.white,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(_borderColor),
      ),
    );
  }
  
  Widget _buildContextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            _measurementType.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your ${_measurement.objectName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textBlack),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _measurement.measurementString,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _borderColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Difficulty: ${currentQuestion.difficultyLevel}/5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _borderColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentQuestion.questionText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.textBlack),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMCQOptions() {
    final options = currentQuestion.options ?? [];
    
    return Column(
      children: options.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrectAnswer = option == currentQuestion.correctAnswer;
        
        Color borderColor;
        Color bgColor;
        
        if (_showFeedback) {
          if (isCorrectAnswer) {
            borderColor = Colors.green;
            bgColor = Colors.green.withOpacity(0.1);
          } else if (isSelected && !_isCorrect) {
            borderColor = Colors.red;
            bgColor = Colors.red.withOpacity(0.1);
          } else {
            borderColor = _borderColor.withOpacity(0.3);
            bgColor = Colors.white;
          }
        } else {
          borderColor = isSelected ? _borderColor : _borderColor.withOpacity(0.3);
          bgColor = isSelected ? _primaryColor.withOpacity(0.1) : Colors.white;
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: _showFeedback ? null : () {
              setState(() {
                _selectedAnswer = option;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || (_showFeedback && isCorrectAnswer) ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: const Color(AppColors.textBlack),
                      ),
                    ),
                  ),
                  if (_showFeedback && isCorrectAnswer)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  if (_showFeedback && isSelected && !_isCorrect)
                    const Icon(Icons.cancel, color: Colors.red, size: 24),
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
        const Text(
          'Need a hint?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textBlack),
          ),
        ),
        const SizedBox(height: 12),
        ...currentQuestion.hints.asMap().entries.map((entry) {
          final index = entry.key;
          final hint = entry.value;
          final isRevealed = _hintsRevealed[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _revealHint(index),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRevealed ? const Color(AppColors.infoColor).withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(AppColors.infoColor).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isRevealed ? Icons.lightbulb : Icons.lightbulb_outline,
                      color: const Color(AppColors.infoColor),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isRevealed ? hint : 'Tap to reveal hint ${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(AppColors.textBlack).withOpacity(0.8),
                        ),
                      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _isCorrect ? 'Correct! 🎉' : 'Not quite right',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          if (currentQuestion.explanation != null && currentQuestion.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              currentQuestion.explanation!,
              style: TextStyle(
                fontSize: 14,
                color: const Color(AppColors.textBlack).withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBottomButton() {
    final bool isDisabled = !_showFeedback && _selectedAnswer == null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity, // Full width
          height: 54, // Better touch target
          child: ElevatedButton(
            onPressed: isDisabled ? null : (_showFeedback ? _nextQuestion : _checkAnswer),
            style: ElevatedButton.styleFrom(
              backgroundColor: _borderColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _borderColor.withOpacity(0.4),
              disabledForegroundColor: Colors.white.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _showFeedback
                  ? (isLastQuestion ? 'View Results' : 'Next Question')
                  : 'Submit Answer',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
