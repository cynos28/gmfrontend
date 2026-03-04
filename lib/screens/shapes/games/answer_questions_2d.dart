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
  final List<Question> _questions = [
    Question(
      question: 'Which shape has all points equidistant from the center?',
      image: 'assets/images/circle.png',
      options: ['Square', 'Triangle', 'Circle', 'Rectangle'],
      correctIndex: 2,
    ),
    Question(
      question: 'Which shape has 3 sides?',
      image: 'assets/images/triangle.png',
      options: ['Circle', 'Triangle', 'Square', 'Rectangle'],
      correctIndex: 1,
    ),
    Question(
      question: 'Which shape has 4 equal sides and 4 right angles?',
      image: 'assets/images/square.png',
      options: ['Square', 'Rectangle', 'Trapezoid', 'Parallelogram'],
      correctIndex: 0,
    ),
  ];

  int _current = 0;
  int? _selectedIndex;
  List<int> _answers = [];
  bool _showAnswer = false;

  void _selectOption(int idx) {
    if (_showAnswer) return; // don't allow changes after reveal
    setState(() {
      _selectedIndex = idx;
    });
  }

  void _checkAnswer() {
    if (_selectedIndex == null) return;
    setState(() {
      _showAnswer = true;
      _answers.add(_selectedIndex!);
    });
  }

  void _nextQuestion() {
    if (!_showAnswer) return; // force checking first
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selectedIndex = null;
        _showAnswer = false;
      });
    } else {
      // Show results
      final correct = List.generate(_questions.length, (i) => _answers[i] == _questions[i].correctIndex).where((v) => v).length;
      final isPerfect = correct == _questions.length;
      final isGood = correct >= _questions.length * 0.7;
      
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
            'You got $correct out of ${_questions.length} correct!',
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_current];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D4059)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '🌟 Fun 2D Shape Quiz! 🌟',
          style: TextStyle(color: Color(0xFF2D4059), fontWeight: FontWeight.w700, fontSize: 22),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_current + 1) / _questions.length,
                      minHeight: 12,
                      color: const Color(0xFF36D399),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF36D399),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_current + 1}/${_questions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Question card
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF9F0), Color(0xFFFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF36D399), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (q.image != null) ...[
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(child: Image.asset(q.image!, fit: BoxFit.contain)),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      '❓ ' + q.question,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D4059),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: List.generate(q.options.length, (i) {
                        final option = q.options[i];
                        final isSelected = _selectedIndex == i;
                        final isCorrect = q.correctIndex == i;

                        Color bg = Colors.white;
                        Color border = const Color(0xFF9E9E9E);
                        String emoji = '';

                        if (_showAnswer) {
                          if (isCorrect) {
                            bg = const Color(0xFF36D399);
                            border = const Color(0xFF36D399);
                            emoji = '✅ ';
                          } else if (isSelected && !isCorrect) {
                            bg = const Color(0xFFFF6B6B);
                            border = const Color(0xFFFF6B6B);
                            emoji = '❌ ';
                          }
                        } else if (isSelected) {
                          bg = const Color(0xFF8A38F5);
                          border = const Color(0xFF8A38F5);
                        }

                        return GestureDetector(
                          onTap: () => _selectOption(i),
                          child: Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: border, width: 3),
                              boxShadow: [
                                if (!_showAnswer || (isCorrect && _showAnswer))
                                  BoxShadow(
                                    color: border.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: 1,
                                        maxWidth: MediaQuery.of(context).size.width - 100,
                                      ),
                                      child: Text(
                                        emoji + option,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: (_showAnswer && (isCorrect || (isSelected && !isCorrect))) 
                                              ? Colors.white 
                                              : (isSelected ? Colors.white : const Color(0xFF2D4059)),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showAnswer ? _nextQuestion : _checkAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1AD7F),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: const Color(0xFFF1AD7F).withOpacity(0.4),
                      ),
                      child: Text(
                        _showAnswer ? (_current < _questions.length - 1 ? '➡️ Next Question' : '🎉 Finish') : '✨ Check Answer',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
