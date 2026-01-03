import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/models/unit_models.dart';
import 'package:ganithamithura/services/api/unit_api_service.dart';
import 'package:ganithamithura/services/unit_progress_service.dart';
import 'package:ganithamithura/services/user_service.dart';

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
  
  // Session-based practice (limit questions per session)
  static const int MAX_QUESTIONS_PER_SESSION = 10; // Kids practice 10 questions at a time
  static const int INITIAL_ASSESSMENT_QUESTIONS = 5; // First 5 questions for baseline
  int _answeredQuestionsCount = 0;
  int _correctAnswersCount = 0;
  bool _isInitialAssessment = true; // Start with baseline questions
  bool _hasCompletedSession = false; // Track if session is complete

  @override
  void initState() {
    super.initState();
    _loadSavedProgress();
  }
  
  // Load saved progress for this unit
  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCount = prefs.getInt('practice_progress_${widget.unit.id}') ?? 0;
    final savedCorrect = prefs.getInt('practice_correct_${widget.unit.id}') ?? 0;
    
    setState(() {
      _answeredQuestionsCount = savedCount;
      _correctAnswersCount = savedCorrect;
    });
    
    debugPrint('📚 Loaded saved progress for ${widget.unit.id}: $savedCount/$MAX_QUESTIONS_PER_SESSION answered, $savedCorrect correct');
    
    _loadNextQuestion();
  }
  
  // Save progress for this unit
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('practice_progress_${widget.unit.id}', _answeredQuestionsCount);
    await prefs.setInt('practice_correct_${widget.unit.id}', _correctAnswersCount);
    debugPrint('💾 Saved progress: $_answeredQuestionsCount/$MAX_QUESTIONS_PER_SESSION answered');
  }
  
  // Clear saved progress for this unit
  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('practice_progress_${widget.unit.id}');
    await prefs.remove('practice_correct_${widget.unit.id}');
    debugPrint('🗑️ Cleared saved progress for ${widget.unit.id}');
  }

  Future<void> _loadNextQuestion() async {
    // Check if session is complete
    if (_answeredQuestionsCount >= MAX_QUESTIONS_PER_SESSION) {
      setState(() {
        _hasCompletedSession = true;
        _isLoading = false;
      });
      return;
    }
    
    // Check if initial assessment is done
    if (_isInitialAssessment && _answeredQuestionsCount >= INITIAL_ASSESSMENT_QUESTIONS) {
      setState(() {
        _isInitialAssessment = false;
      });
      debugPrint('✅ Initial assessment complete! Moving to adaptive practice.');
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedAnswer = null;
      _answerFeedback = null;
      _showingFeedback = false;
      _questionStartTime = DateTime.now();
    });

    try {
      // Get student's grade from profile settings
      final grade = await UserService.getGrade();
      
      // Always use adaptive questions from RAG service
      debugPrint('🎯 Loading adaptive question from RAG service for ${widget.unit.name} (${widget.unit.id}) - Grade $grade...');
      
      final ragQuestion = await _apiService.getAdaptiveQuestion(
        unitId: widget.unit.id, // Use full unit_id like "unit_length_1", "unit_area_1", etc.
        gradeLevel: grade,
      );
      
      debugPrint('📦 Received RAG question:');
      debugPrint('   Unit ID: ${widget.unit.id}');
      debugPrint('   Question: ${ragQuestion.questionText}');
      debugPrint('   Type: ${ragQuestion.questionType}');
      debugPrint('   Options: ${ragQuestion.options}');
      debugPrint('   Options count: ${ragQuestion.options?.length ?? 0}');
      
      // Validate question has options (skip short_answer questions)
      if (ragQuestion.questionType == 'short_answer') {
        debugPrint('⚠️ Skipping short_answer question, requesting MCQ instead...');
        // Recursively try to get another question
        return _loadNextQuestion();
      }
      
      if (ragQuestion.options == null || ragQuestion.options!.isEmpty) {
        debugPrint('⚠️ Question has no options, requesting another question...');
        // Recursively try to get another question
        return _loadNextQuestion();
      }
      
      // Convert RAG question to Question model
      final question = ragQuestion.toQuestion();
      
      debugPrint('✅ Converted to Question:');
      debugPrint('   Options: ${question.options}');
      debugPrint('   Options count: ${question.options.length}');
      
      // Validate question matches the unit topic
      if (!_isQuestionRelevantToUnit(question.questionText, widget.unit.id)) {
        debugPrint('⚠️ Question topic does not match unit ${widget.unit.id}, treating as no questions available');
        setState(() {
          _hasCompletedSession = true;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _currentQuestion = question;
        _questionHistory.add(question);
        _currentQuestionIndex = _questionHistory.length - 1;
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('❌ Error loading question for ${widget.unit.name} (${widget.unit.id}): $e');
      
      // Check if error is due to no more questions available
      final errorMessage = e.toString().toLowerCase();
      final noQuestionsAvailable = errorMessage.contains('no suitable questions') ||
          errorMessage.contains('no questions available') ||
          errorMessage.contains('no questions found') ||
          errorMessage.contains('404') ||
          errorMessage.contains('document not found');
      
      if (noQuestionsAvailable || _answeredQuestionsCount >= 5) {
        // Show completion screen instead of error
        setState(() {
          _hasCompletedSession = true;
          _isLoading = false;
        });
        
        debugPrint('✅ No questions available for ${widget.unit.name} (${widget.unit.id})');
      } else {
        // Show actual error for other issues
        setState(() {
          _error = 'Failed to load question. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _currentQuestion == null) return;

    setState(() => _isSubmitting = true);

    final timeTaken = DateTime.now().difference(_questionStartTime!).inSeconds;

    try {
      // Submit to adaptive endpoint
      final adaptiveFeedback = await _apiService.submitAdaptiveAnswer(
        questionId: _currentQuestion!.questionId,
        unitId: widget.unit.id,
        answer: _currentQuestion!.options[_selectedAnswer!],
        timeTaken: timeTaken,
      );
      
      // Convert to AnswerResponse
      final response = AnswerResponse(
        isCorrect: adaptiveFeedback.isCorrect,
        correctIndex: _currentQuestion!.options.indexOf(adaptiveFeedback.correctAnswer),
        explanation: adaptiveFeedback.explanation,
      );
      
      // Record progress
      await _progressService.recordAnswer(
        unitId: widget.unit.id,
        isCorrect: response.isCorrect,
      );
      
      // Increment answered questions count
      setState(() {
        _answeredQuestionsCount++;
        if (response.isCorrect) {
          _correctAnswersCount++;
        }
        _answerFeedback = response;
        _showingFeedback = true;
        _isSubmitting = false;
      });
      
      // Save progress after each answer
      await _saveProgress();
      
      // Log progress
      if (_isInitialAssessment) {
        debugPrint('📊 Initial Assessment: ${_answeredQuestionsCount}/$INITIAL_ASSESSMENT_QUESTIONS questions');
      } else {
        debugPrint('📊 Practice Progress: ${_answeredQuestionsCount}/$MAX_QUESTIONS_PER_SESSION questions');
      }
      debugPrint('✅ Progress recorded: ${response.isCorrect ? "Correct" : "Incorrect"} (${_correctAnswersCount}/$_answeredQuestionsCount correct)');
      
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

  // Validate if question is relevant to the unit topic
  bool _isQuestionRelevantToUnit(String questionText, String unitId) {
    final lowerQuestion = questionText.toLowerCase();
    
    // Check if it's a length unit
    if (unitId.contains('length')) {
      // Length keywords
      if (lowerQuestion.contains('long') || 
          lowerQuestion.contains('short') || 
          lowerQuestion.contains('tall') ||
          lowerQuestion.contains('height') ||
          lowerQuestion.contains('distance') ||
          lowerQuestion.contains('meter') ||
          lowerQuestion.contains('centimeter') ||
          lowerQuestion.contains('cm') ||
          lowerQuestion.contains('km')) {
        return true;
      }
      return false;
    }
    
    // Check if it's a weight unit
    if (unitId.contains('weight')) {
      // Weight keywords
      if (lowerQuestion.contains('heavy') || 
          lowerQuestion.contains('light') || 
          lowerQuestion.contains('weigh') ||
          lowerQuestion.contains('weight') ||
          lowerQuestion.contains('kg') ||
          lowerQuestion.contains('kilogram') ||
          lowerQuestion.contains('gram') ||
          lowerQuestion.contains('mass')) {
        return true;
      }
      return false;
    }
    
    // Check if it's an area unit
    if (unitId.contains('area')) {
      // Area keywords
      if (lowerQuestion.contains('area') || 
          lowerQuestion.contains('square') || 
          lowerQuestion.contains('space') ||
          lowerQuestion.contains('cover') ||
          lowerQuestion.contains('surface') ||
          lowerQuestion.contains('m²') ||
          lowerQuestion.contains('cm²')) {
        return true;
      }
      return false;
    }
    
    // Check if it's a capacity/volume unit
    if (unitId.contains('capacity') || unitId.contains('volume')) {
      // Capacity keywords
      if (lowerQuestion.contains('hold') || 
          lowerQuestion.contains('contain') || 
          lowerQuestion.contains('fill') ||
          lowerQuestion.contains('capacity') ||
          lowerQuestion.contains('volume') ||
          lowerQuestion.contains('liter') ||
          lowerQuestion.contains('ml') ||
          lowerQuestion.contains('litre')) {
        return true;
      }
      return false;
    }
    
    // Default: allow the question if we can't determine the unit type
    return true;
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
                      ? 'Initial Assessment: ${_answeredQuestionsCount}/$INITIAL_ASSESSMENT_QUESTIONS'
                      : 'Practice Session: ${_answeredQuestionsCount}/$MAX_QUESTIONS_PER_SESSION',
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
    // Show completion screen if session is done
    if (_hasCompletedSession) {
      return _buildCompletionScreen();
    }
    
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
      padding: const EdgeInsets.all(KidsSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question text
          Container(
            padding: const EdgeInsets.all(KidsSpacing.cardPaddingLarge),
            decoration: KidsComponents.questionCard(),
            child: Text(
              _currentQuestion!.questionText,
              style: KidsTypography.question.copyWith(
                fontSize: 20,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: KidsSpacing.xxl),
          
          // Answer options
          ..._buildAnswerOptions(),
          
          const SizedBox(height: KidsSpacing.xl),
          
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
      
      return Padding(
        padding: const EdgeInsets.only(bottom: KidsSpacing.cardMargin),
        child: GestureDetector(
          onTap: _showingFeedback || _isSubmitting
              ? null
              : () => setState(() => _selectedAnswer = index),
          child: Container(
            padding: const EdgeInsets.all(KidsSpacing.cardPaddingLarge),
            decoration: KidsComponents.answerCard(
              isSelected: isSelected,
              showFeedback: _showingFeedback,
              isCorrect: isCorrect,
            ),
            child: Row(
              children: [
                // Option letter badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: KidsComponents.badge(
                    color: _showingFeedback && isCorrect
                        ? KidsColors.success
                        : _showingFeedback && isWrong
                            ? KidsColors.error
                            : isSelected
                                ? KidsColors.primaryAccent
                                : KidsColors.borderMedium,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _showingFeedback && isCorrect
                            ? KidsColors.success
                            : _showingFeedback && isWrong
                                ? KidsColors.error
                                : isSelected
                                    ? KidsColors.primaryAccent
                                    : KidsColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: KidsSpacing.lg),
                // Option text
                Expanded(
                  child: Text(
                    option,
                    style: KidsTypography.label.copyWith(
                      fontSize: 17,
                    ),
                  ),
                ),
                // Check/Cross icon
                if (_showingFeedback && (isCorrect || isWrong))
                  Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? KidsColors.success : KidsColors.error,
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
      style: KidsComponents.primaryButton(
        backgroundColor: const Color(AppColors.measurementIcon),
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
          : Text(
              'Check Answer',
              style: KidsTypography.buttonLarge.copyWith(
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildFeedback() {
    final isCorrect = _answerFeedback!.isCorrect;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(KidsSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCorrect 
              ? [
                  KidsColors.successLight,
                  KidsColors.successLight.withOpacity(0.8),
                ]
              : [
                  KidsColors.errorLight,
                  KidsColors.errorLight.withOpacity(0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        border: Border.all(
          color: isCorrect ? KidsColors.success : KidsColors.error,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? KidsColors.success : KidsColors.error).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Big celebration header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCorrect ? '🎉' : '🤔',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    children: [
                      Text(
                        isCorrect ? 'Awesome!' : 'Oops!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isCorrect ? KidsColors.success : KidsColors.error,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCorrect ? 'You got it right!' : 'Let\'s try again!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KidsColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KidsSpacing.lg),
          // Explanation box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KidsSpacing.cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
              border: Border.all(
                color: isCorrect ? KidsColors.success.withOpacity(0.3) : KidsColors.error.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCorrect ? KidsColors.successLight : KidsColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '💡',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Here\'s why:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: KidsColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KidsSpacing.md),
                Text(
                  _answerFeedback!.explanation,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: KidsColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KidsSpacing.xl),
          // Next button - big and fun
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _goToNextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? KidsColors.success : KidsColors.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
                ),
                elevation: 6,
                shadowColor: (isCorrect ? KidsColors.success : KidsColors.primaryAccent).withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next Question',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 28),
                ],
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
  
  Widget _buildCompletionScreen() {
    // Check if student answered any questions
    final hasAnsweredQuestions = _answeredQuestionsCount > 0;
    
    // If no questions were answered, show "no questions available" message
    if (!hasAnsweredQuestions) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              const SizedBox(height: 20),
              
              // Fun animated-style icon with gradient background
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6B7FFF),
                      const Color(0xFF8CA9FF),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B7FFF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title with fun emoji - Kid friendly
              const Text(
                '🎈 No Questions Here Yet! 🎈',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B7FFF),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Unit-specific message - Simpler language for kids
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'We don\'t have any questions about\n"${widget.unit.name}" ready for you yet! 😊',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textBlack),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              
              // Fun suggestions card - Bright and encouraging
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE8F5E9),
                      const Color(0xFFD4F1D7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2EB872),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2EB872).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_objects_rounded,
                        size: 44,
                        color: Color(0xFF2EB872),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Let\'s Try Something Fun!',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B7F4E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            children: [
                              Text('🎯', style: TextStyle(fontSize: 22)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Try other units with questions!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(AppColors.textBlack),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Text('🤖', style: TextStyle(fontSize: 22)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Chat with your AI tutor!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(AppColors.textBlack),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Text('📱', style: TextStyle(fontSize: 22)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Play with AR measurements!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(AppColors.textBlack),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Big friendly back button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7FFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF6B7FFF).withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    
    // Normal completion screen when student answered questions
    final percentage = _answeredQuestionsCount > 0 
        ? ((_correctAnswersCount / _answeredQuestionsCount) * 100).round()
        : 0;
    final isPerfect = percentage == 100;
    final isGreat = percentage >= 80;
    final isGood = percentage >= 60;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            // Trophy/Celebration Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isPerfect 
                    ? const Color(0xFFFFD700).withOpacity(0.2)
                    : isGreat
                        ? const Color(0xFF2EB872).withOpacity(0.2)
                        : const Color(AppColors.measurementColor).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPerfect ? Icons.emoji_events : isGreat ? Icons.star : Icons.thumb_up,
                size: 64,
                color: isPerfect 
                    ? const Color(0xFFFFD700)
                    : isGreat
                        ? const Color(0xFF2EB872)
                        : const Color(AppColors.measurementIcon),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              isPerfect 
                  ? '🎉 Perfect Score!'
                  : isGreat
                      ? '⭐ Great Job!'
                      : isGood
                          ? '👍 Good Work!'
                          : '💪 Keep Practicing!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textBlack),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              _isInitialAssessment
                  ? 'Assessment Complete'
                  : 'Practice Session Complete',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(AppColors.subText1),
              ),
            ),
            const SizedBox(height: 32),
            
            // Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Questions',
                        _answeredQuestionsCount.toString(),
                        Icons.quiz,
                        const Color(AppColors.measurementIcon),
                      ),
                      _buildStatItem(
                        'Correct',
                        _correctAnswersCount.toString(),
                        Icons.check_circle,
                        const Color(0xFF2EB872),
                      ),
                      _buildStatItem(
                        'Score',
                        '$percentage%',
                        Icons.stars,
                        const Color(0xFFFFB800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPerfect 
                            ? const Color(0xFFFFD700)
                            : isGreat
                                ? const Color(0xFF2EB872)
                                : const Color(AppColors.measurementIcon),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _clearProgress();
                      setState(() {
                        _answeredQuestionsCount = 0;
                        _correctAnswersCount = 0;
                        _hasCompletedSession = false;
                        _questionHistory.clear();
                        _currentQuestionIndex = -1;
                      });
                      _loadNextQuestion();
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Practice Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.measurementIcon),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.home),
                    label: const Text('Back to Unit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      side: const BorderSide(
                        color: Color(AppColors.measurementIcon),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(AppColors.subText2),
          ),
        ),
      ],
    );
  }
}
