import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/unit_models.dart';
import 'package:ganithamithura/services/api/unit_api_service.dart';
import 'package:ganithamithura/services/unit_progress_service.dart';

class QuestionPracticeScreen extends StatefulWidget {
  final Unit unit;

  const QuestionPracticeScreen({
    super.key,
    required this.unit,
  });

  @override
  State<QuestionPracticeScreen> createState() => _QuestionPracticeScreenState();
}

class _QuestionPracticeScreenState extends State<QuestionPracticeScreen> {
  final UnitApiService _apiService = UnitApiService();
  final UnitProgressService _progressService = UnitProgressService.instance;
  
  Question? _currentQuestion;
  int? _selectedAnswer;
  AnswerResponse? _answerFeedback;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showingFeedback = false;
  String? _error;
  DateTime? _questionStartTime;
  
  final List<Question> _questionHistory = [];
  int _currentQuestionIndex = -1;
  
  // Initial assessment tracking
  static const int INITIAL_QUESTIONS_PER_TOPIC = 3;
  static const int TOTAL_INITIAL_QUESTIONS = 12; // 3 questions × 4 topics
  int _answeredQuestionsCount = 0;
  bool _isInitialAssessment = true; // Start with baseline questions

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedAnswer = null;
      _answerFeedback = null;
      _showingFeedback = false;
      _questionStartTime = DateTime.now();
    });

    try {
      Question question;
      
      // Check if still in initial assessment phase
      if (_isInitialAssessment && _answeredQuestionsCount < TOTAL_INITIAL_QUESTIONS) {
        debugPrint('📊 Initial Assessment: Question ${_answeredQuestionsCount + 1}/$TOTAL_INITIAL_QUESTIONS');
        
        // Use mock/seeded questions for initial assessment
        question = await _apiService.getNextQuestion(widget.unit.id);
        
      } else {
        // Switch to adaptive RAG questions after initial assessment
        if (_isInitialAssessment) {
          debugPrint('✅ Initial assessment complete! Switching to adaptive questions...');
          _isInitialAssessment = false;
        }
        
        debugPrint('🎯 Loading adaptive question from RAG service...');
        
        try {
          // Get adaptive question from RAG service
          final ragQuestion = await _apiService.getAdaptiveQuestion(
            unitId: widget.unit.id, // Use full unit_id like "unit_length_1"
          );
          
          // Convert RAG question to Question model
          question = ragQuestion.toQuestion();
          
        } catch (e) {
          // Fallback to mock questions if RAG service is unavailable
          debugPrint('⚠️ RAG service unavailable, using mock data: $e');
          question = await _apiService.getNextQuestion(widget.unit.id);
        }
      }
      
      setState(() {
        _currentQuestion = question;
        _questionHistory.add(question);
        _currentQuestionIndex = _questionHistory.length - 1;
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('❌ Error loading question: $e');
      setState(() {
        _error = 'Failed to load question. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _currentQuestion == null) return;

    setState(() => _isSubmitting = true);

    final timeTaken = DateTime.now().difference(_questionStartTime!).inSeconds;

    try {
      AnswerResponse response;
      
      // Only try adaptive submission if not in initial assessment
      if (!_isInitialAssessment) {
        try {
          final adaptiveFeedback = await _apiService.submitAdaptiveAnswer(
            questionId: _currentQuestion!.questionId,
            answer: _currentQuestion!.options[_selectedAnswer!],
            timeTaken: timeTaken,
          );
          
          // Convert to AnswerResponse
          response = AnswerResponse(
            isCorrect: adaptiveFeedback.isCorrect,
            correctIndex: _currentQuestion!.options.indexOf(adaptiveFeedback.correctAnswer),
            explanation: adaptiveFeedback.explanation,
          );
        } catch (e) {
          debugPrint('Adaptive submission failed, trying regular: $e');
          // Fallback to regular submission
          response = await _apiService.submitAnswer(
            questionId: _currentQuestion!.questionId,
            selectedIndex: _selectedAnswer!,
            unitId: widget.unit.id,
            timeTaken: timeTaken,
          );
        }
      } else {
        // Regular submission for initial assessment
        response = await _apiService.submitAnswer(
          questionId: _currentQuestion!.questionId,
          selectedIndex: _selectedAnswer!,
          unitId: widget.unit.id,
          timeTaken: timeTaken,
        );
      }
      
      // Record progress
      await _progressService.recordAnswer(
        unitId: widget.unit.id,
        isCorrect: response.isCorrect,
      );
      
      // Increment answered questions count
      setState(() {
        _answeredQuestionsCount++;
        _answerFeedback = response;
        _showingFeedback = true;
        _isSubmitting = false;
      });
      
      // Log progress
      if (_isInitialAssessment) {
        debugPrint('📊 Progress: ${_answeredQuestionsCount}/$TOTAL_INITIAL_QUESTIONS initial questions answered');
      }
      debugPrint('✅ Progress recorded: ${response.isCorrect ? "Correct" : "Incorrect"}');
      
    } catch (e) {
      debugPrint('❌ Error submitting answer: $e');
      setState(() {
        _error = 'Failed to submit answer. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _currentQuestion = _questionHistory[_currentQuestionIndex];
        _selectedAnswer = null;
        _answerFeedback = null;
        _showingFeedback = false;
      });
    }
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questionHistory.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentQuestion = _questionHistory[_currentQuestionIndex];
        _selectedAnswer = null;
        _answerFeedback = null;
        _showingFeedback = false;
      });
    } else {
      _loadNextQuestion();
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF2EB872);
      case 'medium':
        return const Color(0xFFFFB800);
      case 'hard':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF6B7FFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: _buildContent(),
            ),
            
            // Navigation buttons
            if (!_isLoading && _currentQuestion != null)
              _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Get.back(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.unit.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textBlack),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isInitialAssessment 
                      ? 'Initial Assessment ${_answeredQuestionsCount}/$TOTAL_INITIAL_QUESTIONS'
                      : 'Adaptive Practice',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(AppColors.subText1),
                  ),
                ),
              ],
            ),
          ),
          if (_currentQuestion != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getDifficultyColor(_currentQuestion!.difficulty)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentQuestion!.difficulty.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _getDifficultyColor(_currentQuestion!.difficulty),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 72,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(AppColors.subText1),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _loadNextQuestion,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.measurementIcon),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuestion == null) {
      return const Center(
        child: Text('No question available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question text
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8CA9FF).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              _currentQuestion!.questionText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.textBlack),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Answer options
          ..._buildAnswerOptions(),
          
          const SizedBox(height: 24),
          
          // Submit button
          if (!_showingFeedback && _selectedAnswer != null)
            _buildSubmitButton(),
          
          // Feedback
          if (_showingFeedback && _answerFeedback != null)
            _buildFeedback(),
        ],
      ),
    );
  }

  List<Widget> _buildAnswerOptions() {
    return List.generate(_currentQuestion!.options.length, (index) {
      final option = _currentQuestion!.options[index];
      final isSelected = _selectedAnswer == index;
      final isCorrect = _answerFeedback?.correctIndex == index;
      final isWrong = _showingFeedback && 
                      _selectedAnswer == index && 
                      !_answerFeedback!.isCorrect;
      
      Color borderColor;
      Color backgroundColor;
      
      if (_showingFeedback) {
        if (isCorrect) {
          borderColor = const Color(0xFF2EB872);
          backgroundColor = const Color(0xFF2EB872).withOpacity(0.15);
        } else if (isWrong) {
          borderColor = const Color(0xFFFF6B6B);
          backgroundColor = const Color(0xFFFF6B6B).withOpacity(0.15);
        } else {
          borderColor = const Color(AppColors.borderLight);
          backgroundColor = Colors.white;
        }
      } else {
        borderColor = isSelected
            ? const Color(0xFF6B7FFF)
            : const Color(AppColors.borderLight);
        backgroundColor = isSelected
            ? const Color(0xFF6B7FFF).withOpacity(0.1)
            : Colors.white;
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GestureDetector(
          onTap: _showingFeedback || _isSubmitting
              ? null
              : () => setState(() => _selectedAnswer = index),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 2.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected && !_showingFeedback
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6B7FFF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Option letter
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: borderColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Option text
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textBlack),
                    ),
                  ),
                ),
                // Check/Cross icon
                if (_showingFeedback && (isCorrect || isWrong))
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: borderColor,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitAnswer,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(AppColors.measurementIcon),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'Submit Answer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  Widget _buildFeedback() {
    final isCorrect = _answerFeedback!.isCorrect;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFF2EB872).withOpacity(0.1)
            : const Color(0xFFFF6B6B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF2EB872)
              : const Color(0xFFFF6B6B),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect
                    ? const Color(0xFF2EB872)
                    : const Color(0xFFFF6B6B),
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? 'Great job! 🎉' : 'Not quite right',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isCorrect
                        ? const Color(0xFF2EB872)
                        : const Color(0xFFFF6B6B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Explanation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explanation:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.subText2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _answerFeedback!.explanation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.textBlack),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _goToNextQuestion,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColors.measurementIcon),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: _currentQuestionIndex > 0
                      ? const Color(AppColors.measurementIcon)
                      : Colors.grey,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _goToNextQuestion,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.measurementIcon),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
