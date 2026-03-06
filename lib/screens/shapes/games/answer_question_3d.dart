import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Answer3DQuestionsScreen - Quiz for identifying 3D shapes in real-world objects  
/// Updated for grade 2-3 students with larger fonts and colorful design
class Answer3DQuestionsScreen extends StatefulWidget {
  const Answer3DQuestionsScreen({super.key});

  @override
  State<Answer3DQuestionsScreen> createState() => _Answer3DQuestionsScreenState();
}

class _Answer3DQuestionsScreenState extends State<Answer3DQuestionsScreen> {
  int _currentQuestion = 1;
  final int _totalQuestions = 5;
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _isCorrect = false;
  int _score = 0;

  // All available quiz questions for 3D shapes - randomly select 5 from this pool
  static final List<Map<String, dynamic>> _allQuestions = [
    {
      'question': 'Which object is a Sphere?',
      'correctAnswer': 'Ball',
      'options': ['Ball', 'Soda can', 'Gift Box', 'Book'],
      'shape': 'sphere',
    },
    {
      'question': 'A tin can has which 3D shape?',
      'correctAnswer': 'Cylinder',
      'options': ['Cone', 'Cylinder', 'Cube', 'Ball'],
      'shape': 'cylinder',
    },
    {
      'question': 'Which object is a Cube?',
      'correctAnswer': 'Gift Box',
      'options': ['Ball', 'Gift Box', 'Ice cream cone', 'Soda can'],
      'shape': 'cube',
    },
    {
      'question': 'Which object is a Cone?',
      'correctAnswer': 'Ice cream cone',
      'options': ['Ball', 'Box', 'Ice cream cone', 'Gift Box'],
      'shape': 'cone',
    },
    {
      'question': 'Which object is a Rectangular Prism?',
      'correctAnswer': 'Book',
      'options': ['Ball', 'Book', 'Soda can', 'Cone'],
      'shape': 'prism',
    },
  ];

  late final List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    // Randomly select 5 questions from all available questions
    final random = Random();
    final shuffled = List<Map<String, dynamic>>.from(_allQuestions)..shuffle(random);
    _questions = shuffled.take(5).toList();
  }

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
      // Show completion dialog
      final isPerfect = _score == _totalQuestions * 10;
      final isGood = _score >= (_totalQuestions * 10) * 0.7;
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isPerfect ? '🌟 Perfect Score! 🌟' : (isGood ? '😊 Great Job! 😊' : '💪 Keep Practicing! 💪'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'You scored $_score out of ${_totalQuestions * 10} points!',
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.back();
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF36D399),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        ),
      );
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
                        'Fun 3D Shape Quiz! 🌟',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F3FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        shadows: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF36D399),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.view_in_ar_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '� Fun 3D Shape Quiz!',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find the right shape! 🚀',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF36D399),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$_currentQuestion/$_totalQuestions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Question display with 3D shape image and answer options
  Widget _buildQuestionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17),
      padding: const EdgeInsets.all(28),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9F0), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 3,
            color: const Color(0xFF36D399),
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Question Text
          Text(
            '❓ ' + _currentQuestionData['question'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // 3D Shape Image
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[100]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF36D399),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
    
    return Icon(iconData, size: 120, color: color);
  }

  // Option buttons in 2x2 grid
  Widget _buildOptionButtons() {
    final options = _currentQuestionData['options'] as List<String>;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildOptionButton(options[0])),
            const SizedBox(width: 8),
            Expanded(child: _buildOptionButton(options[1])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildOptionButton(options[2])),
            const SizedBox(width: 8),
            Expanded(child: _buildOptionButton(options[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton(String option) {
    final isSelected = _selectedAnswer == option;
    final isCorrectAnswer = option == _currentQuestionData['correctAnswer'];
    final showAsWrong = _isAnswered && isSelected && !_isCorrect;
    final showAsCorrect = _isAnswered && isCorrectAnswer;
    
    String emoji = '';
    if (showAsCorrect) emoji = '✅ ';
    if (showAsWrong) emoji = '❌ ';
    
    return GestureDetector(
      onTap: () => _selectAnswer(option),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: ShapeDecoration(
          gradient: showAsCorrect 
              ? const LinearGradient(
                  colors: [Color(0xFF36D399), Color(0xFF2BC58A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : showAsWrong
                  ? const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
          color: showAsCorrect || showAsWrong
              ? null
              : (isSelected 
                  ? const Color(0xFF8A38F5)
                  : Colors.white),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 3,
              color: showAsWrong
                  ? const Color(0xFFE53935)
                  : (showAsCorrect
                      ? const Color(0xFF36D399)
                      : (isSelected 
                          ? const Color(0xFF8A38F5) 
                          : const Color(0xFFA349596D))),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          shadows: [
            if (isSelected || showAsCorrect)
              BoxShadow(
                color: (showAsCorrect 
                    ? const Color(0xFF36D399) 
                    : const Color(0xFF8A38F5)).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 1,
              maxWidth: MediaQuery.of(context).size.width / 2.5,
            ),
            child: Text(
              emoji + option,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: showAsCorrect || showAsWrong
                    ? Colors.white
                    : (isSelected ? Colors.white : const Color(0xFF2859C5)),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Next button
  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: GestureDetector(
        onTap: _isAnswered ? _nextQuestion : _submitAnswer,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: ShapeDecoration(
            gradient: (_selectedAnswer == null && !_isAnswered)
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFF1AD7F), Color(0xFFFF9A6C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: (_selectedAnswer == null && !_isAnswered)
                ? const Color(0xFFCCCCCC)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            shadows: [
              if (_selectedAnswer != null || _isAnswered)
                BoxShadow(
                  color: const Color(0xFFF1AD7F).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isAnswered ? '➡️ Next Question' : '✨ Check Answer',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
