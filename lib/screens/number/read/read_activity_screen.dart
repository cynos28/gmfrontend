import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Progress;
import 'dart:math';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/api_service.dart';
import 'package:ganithamithura/screens/number/say/say_activity_screen.dart';

/// ReadActivityScreen - Read and recognize numbers
/// Mode 1: Show digit → select correct word
/// Mode 2: Show word → select correct digit
class ReadActivityScreen extends StatefulWidget {
  final Activity activity;
  final List<Activity> allActivities;
  final int currentNumber;
  final LearningLevel level;
  
  const ReadActivityScreen({
    super.key,
    required this.activity,
    required this.allActivities,
    required this.currentNumber,
    required this.level,
  });
  
  @override
  State<ReadActivityScreen> createState() => _ReadActivityScreenState();
}

class _ReadActivityScreenState extends State<ReadActivityScreen> {
  final _storageService = StorageService.instance;
  final _apiService = ApiService.instance;
  final _random = Random();
  
  late bool _isMode1; // true = digit→word, false = word→digit
  late List<String> _options;
  late String _correctAnswer;
  String? _selectedAnswer;
  bool _isChecking = false;
  bool? _result;
  
  @override
  void initState() {
    super.initState();
    _setupQuestion();
  }
  
  void _setupQuestion() {
    // Randomly choose mode
    _isMode1 = _random.nextBool();
    
    // Get correct answer
    _correctAnswer = _isMode1
        ? NumberWords.getWord(widget.currentNumber)
        : '${widget.currentNumber}';
    
    // Generate options
    _options = _generateOptions();
    _options.shuffle(_random);
  }
  
  List<String> _generateOptions() {
    final options = <String>[_correctAnswer];
    final usedNumbers = <int>{widget.currentNumber};
    
    // Generate 3 random wrong options
    while (options.length < 4) {
      final randomNum = _random.nextInt(10) + 1; // 1-10
      
      if (!usedNumbers.contains(randomNum)) {
        usedNumbers.add(randomNum);
        
        final option = _isMode1
            ? NumberWords.getWord(randomNum)
            : '$randomNum';
        
        if (!options.contains(option)) {
          options.add(option);
        }
      }
    }
    
    return options;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Read Activity'),
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
                  Text(
                    _isMode1 
                        ? 'Which word matches this number?'
                        : 'Which number matches this word?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Question display
                  _buildQuestionDisplay(),
                  
                  const SizedBox(height: 48),
                  
                  // Options
                  ...List.generate(
                    _options.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOptionButton(_options[index]),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit button
                  ActionButton(
                    text: 'Check Answer',
                    icon: Icons.check,
                    isEnabled: _selectedAnswer != null && !_isChecking,
                    onPressed: _checkAnswer,
                  ),
                ],
              ),
            ),
            
            // Result overlay
            if (_result != null)
              _result!
                  ? SuccessAnimation(
                      message: 'Correct!',
                      onComplete: _onSuccess,
                    )
                  : FailureAnimation(
                      message: 'Not quite right!',
                      onRetry: _resetQuestion,
                    ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuestionDisplay() {
    final displayText = _isMode1
        ? '${widget.currentNumber}'
        : NumberWords.getWord(widget.currentNumber);
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Color(AppColors.numberColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        border: Border.all(
          color: Color(AppColors.numberColor),
          width: 3,
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: _isMode1 ? 120 : 48,
          fontWeight: FontWeight.bold,
          color: Color(AppColors.numberColor),
        ),
      ),
    );
  }
  
  Widget _buildOptionButton(String option) {
    final isSelected = _selectedAnswer == option;
    
    return GestureDetector(
      onTap: () {
        if (!_isChecking) {
          setState(() {
            _selectedAnswer = option;
          });
        }
      },
      child: AnimatedContainer(
        duration: AppConstants.shortAnimationDuration,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(AppColors.numberColor)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          border: Border.all(
            color: Color(AppColors.numberColor),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(AppColors.numberColor).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            option,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _checkAnswer() async {
    setState(() {
      _isChecking = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final isCorrect = _selectedAnswer == _correctAnswer;
    
    if (isCorrect) {
      // Save progress
      final progress = Progress(
        activityId: widget.activity.id,
        score: 100,
        isCompleted: true,
        completedAt: DateTime.now(),
        additionalData: {
          'mode': _isMode1 ? 'digit_to_word' : 'word_to_digit',
          'attempts': 1,
        },
      );
      
      await _storageService.saveCompletedActivity(progress);
      
      // Submit to backend
      _apiService.submitActivityScore(
        activityId: widget.activity.id,
        score: 100,
        isCompleted: true,
        additionalData: progress.additionalData,
      ).catchError((e) {
        debugPrint('Error submitting score: $e');
        return <String, dynamic>{};
      });
    }
    
    setState(() {
      _isChecking = false;
      _result = isCorrect;
    });
  }
  
  void _resetQuestion() {
    setState(() {
      _selectedAnswer = null;
      _result = null;
      _setupQuestion();
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
      
      // Navigate to Say activity
      Get.off(() => SayActivityScreen(
        activity: nextActivity,
        allActivities: widget.allActivities,
        currentNumber: widget.currentNumber,
        level: widget.level,
      ));
    }
  }
}
