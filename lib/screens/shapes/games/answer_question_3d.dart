import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Answer3DQuestionsScreen - Quiz for identifying 3D shapes in real-world objects
class Answer3DQuestionsScreen extends StatefulWidget {
  const Answer3DQuestionsScreen({super.key});

  @override
  State<Answer3DQuestionsScreen> createState() => _Answer3DQuestionsScreenState();
}

class _Answer3DQuestionsScreenState extends State<Answer3DQuestionsScreen> {
  int _currentQuestion = 1;
  final int _totalQuestions = 10;
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _isCorrect = false;
  int _score = 0;

  // Quiz questions for 3D shapes
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Which object is a Sphere?',
      'correctAnswer': 'Ball',
      'options': ['Ball', 'Soda can', 'Dice'],
      'shape': 'sphere',
    },
    {
      'question': 'A tin can has which 3D shape?',
      'correctAnswer': 'Cylinder',
      'options': ['Cone', 'Cylinder', 'Cube'],
      'shape': 'cylinder',
    },
    {
      'question': 'Which object is a Cube?',
      'correctAnswer': 'Dice',
      'options': ['Ball', 'Dice', 'Ice cream cone'],
      'shape': 'cube',
    },
    {
      'question': 'Which object is a Cone?',
      'correctAnswer': 'Ice cream cone',
      'options': ['Ball', 'Box', 'Ice cream cone'],
      'shape': 'cone',
    },
    {
      'question': 'Which object is a Rectangular Prism?',
      'correctAnswer': 'Book',
      'options': ['Ball', 'Book', 'Soda can'],
      'shape': 'prism',
    },
  ];

  Map<String, dynamic> get _currentQuestionData =>
      _questions[(_currentQuestion - 1) % _questions.length];

  void _selectAnswer(String answer) {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswer = answer;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _isAnswered) return;
    
    setState(() {
      _isAnswered = true;
      _isCorrect = _selectedAnswer == _currentQuestionData['correctAnswer'];
      if (_isCorrect) {
        _score += 10;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion >= _totalQuestions) {
      Get.back();
      return;
    }

    setState(() {
      _currentQuestion++;
      _selectedAnswer = null;
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _resetAnswer() {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 393.0 : screenWidth - 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Back Navigation Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_ios_new),
                        color: const Color(0xFF2D4059),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Menu',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedAnswer != null && !_isAnswered)
                        TextButton.icon(
                          onPressed: _resetAnswer,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text('Reset'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B6B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: cardWidth,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: const Color(0xF2F9F9F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      
                      // Header Section
                      _buildHeader(),
                      
                      const SizedBox(height: 30),
                      
                      // Question and Answer Section
                      _buildQuestionSection(),
                      
                      const SizedBox(height: 30),
                      
                      // Next Button
                      _buildNextButton(),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header with icon, title, and question counter
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17),
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.view_in_ar_rounded,
              size: 24,
              color: Color(0xFF36D399),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Match 3D Shapes',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Click the real-world example!',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Question',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_currentQuestion/$_totalQuestions',
                style: const TextStyle(
                  color: Color(0xFF36D399),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Question display with 3D shape image and answer options
  Widget _buildQuestionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17),
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 2,
            color: Colors.black.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Question Text
          Text(
            _currentQuestionData['question'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // 3D Shape Image
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 2,
              ),
            ),
            child: Center(
              child: _build3DShapeIcon(_currentQuestionData['shape']),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Option Buttons
          _buildOptionButtons(),
        ],
      ),
    );
  }

  // Build 3D shape icon
  Widget _build3DShapeIcon(String shapeType) {
    IconData iconData;
    Color color;
    
    switch (shapeType) {
      case 'sphere':
        iconData = Icons.circle;
        color = const Color(0xFFFF6B6B);
        break;
      case 'cylinder':
        iconData = Icons.view_in_ar_rounded;
        color = const Color(0xFF4ECDC4);
        break;
      case 'cube':
        iconData = Icons.crop_square_rounded;
        color = const Color(0xFFFFE66D);
        break;
      case 'cone':
        iconData = Icons.change_history_rounded;
        color = const Color(0xFF95E1D3);
        break;
      case 'prism':
        iconData = Icons.rectangle_rounded;
        color = const Color(0xFFF38181);
        break;
      default:
        iconData = Icons.category;
        color = Colors.grey;
    }
    
    return Icon(iconData, size: 100, color: color);
  }

  // Option buttons
  Widget _buildOptionButtons() {
    final options = _currentQuestionData['options'] as List<String>;
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: options.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrectAnswer = option == _currentQuestionData['correctAnswer'];
        final showAsWrong = _isAnswered && isSelected && !_isCorrect;
        final showAsCorrect = _isAnswered && isCorrectAnswer;
        
        return GestureDetector(
          onTap: () => _selectAnswer(option),
          child: Container(
            width: 142,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: ShapeDecoration(
              color: showAsCorrect 
                  ? const Color(0xFF36D399)
                  : (isSelected 
                      ? const Color(0xFFD9D9D9)
                      : Colors.white.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: showAsWrong
                      ? const Color(0xFFE53935)
                      : (showAsCorrect
                          ? const Color(0xFF36D399)
                          : (isSelected 
                              ? const Color(0xFF8A38F5) 
                              : const Color(0xA349596D))),
                ),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              option,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: showAsCorrect
                    ? Colors.white
                    : (showAsWrong
                        ? const Color(0xFFE53935)
                        : const Color(0xFF2859C5)),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Next button
  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 85),
      child: GestureDetector(
        onTap: _isAnswered ? _nextQuestion : _submitAnswer,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: ShapeDecoration(
            color: (_selectedAnswer == null && !_isAnswered)
                ? const Color(0xFFCCCCCC)
                : const Color(0xFFF1AD7F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isAnswered ? 'Next Question' : 'Submit Answer',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_isAnswered) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
