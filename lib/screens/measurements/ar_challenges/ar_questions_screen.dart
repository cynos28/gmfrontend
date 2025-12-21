/// AR Questions Screen - Display and answer personalized questions
/// 
/// Shows contextual questions generated based on the student's actual measurement

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/models/ar_measurement.dart';
import 'package:ganithamithura/services/unit_progress_service.dart';
import 'package:ganithamithura/utils/constants.dart';

class ARQuestionsScreen extends StatefulWidget {
  const ARQuestionsScreen({Key? key}) : super(key: key);

  @override
  State<ARQuestionsScreen> createState() => _ARQuestionsScreenState();
}

class _ARQuestionsScreenState extends State<ARQuestionsScreen> {
  final UnitProgressService _progressService = UnitProgressService.instance;
  
  late ARMeasurement _measurement;
  late MeasurementType _measurementType;
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
    
    // Initialize hints revealed array
    _hintsRevealed = List.filled(currentQuestion.hints.length, false);
    
    print('📝 Showing ${_measurement.questions.length} questions');
    print('   Object: ${_measurement.objectName}');
    print('   Measurement: ${_measurement.measurementString}');
  }
  
  ContextualQuestion get currentQuestion => _measurement.questions[_currentQuestionIndex];
  
  bool get isLastQuestion => _currentQuestionIndex >= _measurement.questions.length - 1;
  
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
  
  void _checkAnswer() {
    if (_selectedAnswer == null) {
      Get.snackbar(
        'Select an Answer',
        'Please select an answer before submitting',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    setState(() {
      _isCorrect = currentQuestion.isCorrect(_selectedAnswer!);
      _showFeedback = true;
      
      if (_isCorrect) {
        _correctCount++;
      }
    });
    
    // Record progress
    _progressService.recordAnswer(
      unitId: 'ar_${_measurementType.name}',
      isCorrect: _isCorrect,
    );
  }
  
  void _nextQuestion() {
    if (isLastQuestion) {
      _showResults();
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back(); // Close dialog
                        Get.back(); // Back to measurement screen
                        Get.back(); // Back to home
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: _borderColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Close dialog
                        Get.back(); // Back to measurement screen to try again
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _borderColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(AppColors.textBlack)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Question ${_currentQuestionIndex + 1} of ${_measurement.questions.length}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textBlack),
          ),
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
    final progress = (_currentQuestionIndex + 1) / _measurement.questions.length;
    
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
        child: ElevatedButton(
          onPressed: _showFeedback ? _nextQuestion : _checkAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: _borderColor,
            foregroundColor: Colors.white,
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
