import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Question {
  final String question;
  final String? image; // optional image path
  final List<String> options;
  final int correctIndex;

  Question({
    required this.question,
    this.image,
    required this.options,
    required this.correctIndex,
  });
}

class Questions2DShapesScreen extends StatefulWidget {
  const Questions2DShapesScreen({Key? key}) : super(key: key);

  @override
  State<Questions2DShapesScreen> createState() => _Questions2DShapesScreenState();
}

class _Questions2DShapesScreenState extends State<Questions2DShapesScreen> {
  static const int _quizSize = 5; // Number of questions per quiz round
  
  // All available questions - randomly select 5 from this pool
  static final List<Question> _allQuestions = [
    Question(
      question: 'Which shape has all points equidistant from the center?',
      image: 'assets/images/2d_shapes/circle.png',
      options: ['Square', 'Triangle', 'Circle', 'Rectangle'],
      correctIndex: 2,
    ),
    Question(
      question: 'Which shape has 3 sides?',
      image: 'assets/images/2d_shapes/triangle.png',
      options: ['Circle', 'Triangle', 'Square', 'Rectangle'],
      correctIndex: 1,
    ),
    Question(
      question: 'Which shape has 4 equal sides and 4 right angles?',
      image: 'assets/images/2d_shapes/square.png',
      options: ['Square', 'Rectangle', 'Trapezoid', 'Parallelogram'],
      correctIndex: 0,
    ),
    Question(
      question: 'Which shape has 4 sides with opposite sides equal?',
      image: 'assets/images/2d_shapes/rectangle.png',
      options: ['Circle', 'Triangle', 'Square', 'Rectangle'],
      correctIndex: 3,
    ),
    Question(
      question: 'Which shape has NO corners or edges?',
      image: 'assets/images/2d_shapes/circle.png',
      options: ['Rectangle', 'Circle', 'Triangle', 'Square'],
      correctIndex: 1,
    ),
  ];

  late final List<Question> _questions;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    // Randomly select questions from all available questions
    final random = Random();
    final shuffled = List<Question>.from(_allQuestions)..shuffle(random);
    _questions = shuffled.take(_quizSize).toList();
    assert(_questions.length == _quizSize, 'Quiz must have exactly $_quizSize questions');
  }
  int? _selectedIndex;
  Map<int, int> _answers = {}; // Map question index to selected answer index
  bool _showAnswer = false;

  void _selectOption(int idx) {
    if (_showAnswer) return; // don't allow changes after reveal
    setState(() {
      _selectedIndex = idx;
    });
  }

  void _checkAnswer() {
    if (_selectedIndex == null || _showAnswer || _answers.containsKey(_current)) return; // Prevent multiple answers
    setState(() {
      _showAnswer = true;
      _answers[_current] = _selectedIndex!; // Use Map to ensure only one answer per question
    });
  }

  bool _isFinished = false;

  void _nextQuestion() {
    if (!_showAnswer) return; // force checking first
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selectedIndex = null;
        _showAnswer = false;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _buildResultsScreen();
    }

    final q = _questions[_current];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildProgressHeader(),
                    const SizedBox(height: 24),
                    _buildQuestionCard(q),
                    const SizedBox(height: 32),
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shapes Quiz',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fun with 2D Shapes!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.psychology_rounded, color: Color(0xFF2196F3), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pick the right answer!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_current + 1) / _questions.length,
                    minHeight: 8,
                    color: const Color(0xFF2196F3),
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_current + 1}/${_questions.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2196F3)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (q.image != null) ...[
            Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(q.image!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            q.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 30),
          Column(
            children: List.generate(q.options.length, (i) => _buildOptionButton(i, q)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int i, Question q) {
    final option = q.options[i];
    final isSelected = _selectedIndex == i;
    final isCorrect = q.correctIndex == i;
    
    Color borderColor;
    Color bgColor;
    Color textColor;
    
    if (_showAnswer) {
      if (isCorrect) {
        borderColor = const Color(0xFF4CAF50);
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
      } else if (isSelected) {
        borderColor = const Color(0xFFE91E63);
        bgColor = const Color(0xFFFCE4EC);
        textColor = const Color(0xFFC2185B);
      } else {
        borderColor = const Color(0xFFE0E0E0);
        bgColor = Colors.white;
        textColor = Colors.black45;
      }
    } else if (isSelected) {
      borderColor = const Color(0xFF2196F3);
      bgColor = const Color(0xFFBBDEFB);
      textColor = const Color(0xFF1976D2);
    } else {
      borderColor = const Color(0xFFE0E0E0);
      bgColor = Colors.white;
      textColor = Colors.black87;
    }

    return GestureDetector(
      onTap: () => _selectOption(i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: isSelected || (_showAnswer && (isCorrect || isSelected)) ? [
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showAnswer && isCorrect) const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20),
            if (_showAnswer && isSelected && !isCorrect) const Icon(Icons.cancel_rounded, color: Color(0xFFC2185B), size: 20),
            if (_showAnswer && (isCorrect || (isSelected && !isCorrect))) const SizedBox(width: 8),
            Flexible(
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final bool canInteract = _selectedIndex != null || _showAnswer;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canInteract ? (_showAnswer ? _nextQuestion : _checkAnswer) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: canInteract ? 4 : 0,
        ),
        child: Text(
          _showAnswer ? (_current < _questions.length - 1 ? 'Next Question ➡️' : 'Finish Quiz 🎉') : 'Check Answer ✨',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final correct = _answers.entries.where((entry) => 
      entry.value == _questions[entry.key].correctIndex
    ).length;
    final bool isExcellent = correct >= 4;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isExcellent ? const Color(0xFFC8E6C9) : const Color(0xFFFFE0B2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            isExcellent ? '🎉 Amazing! 🎉' : '😊 Good Effort! 😊',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You got $correct out of ${_questions.length} questions correct!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              final score = (correct / _questions.length);
                              final stars = score >= 1.0 ? 3 : (score >= 0.7 ? 2 : 1);
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: index < stars ? const Color(0xFFFFC107) : Colors.black26,
                                  size: 48,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('$correct', 'Correct', const Color(0xFF4CAF50)),
                          _buildStatItem('${_questions.length - correct}', 'Wrong', const Color(0xFFE91E63)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _current = 0;
                                _selectedIndex = null;
                                _answers.clear();
                                _showAnswer = false;
                                _isFinished = false;
                                // Reshuffle for new round
                                final random = Random();
                                final shuffled = List<Question>.from(_allQuestions)..shuffle(random);
                                _questions.clear();
                                _questions.addAll(shuffled.take(_quizSize));
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2196F3),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: Color(0xFF2196F3), width: 2),
                              ),
                            ),
                            child: const Text('Try Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Go Back', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
      ],
    );
  }
}
