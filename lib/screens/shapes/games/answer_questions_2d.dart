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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Results'),
          content: Text('You answered $correct of ${_questions.length} correctly.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
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
          'Answer 2D Questions',
          style: TextStyle(color: Color(0xFF2D4059), fontWeight: FontWeight.w700),
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
                      minHeight: 8,
                      color: const Color(0xFF36D399),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${_current + 1}/${_questions.length}', style: const TextStyle(color: Color(0xFF2D4059))),
                ],
              ),

              const SizedBox(height: 18),

              // Question card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (q.image != null) ...[
                      SizedBox(
                        height: 120,
                        child: Center(child: Image.asset(q.image!, fit: BoxFit.contain)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      q.question,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D4059)),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: List.generate(q.options.length, (i) {
                        final option = q.options[i];
                        final isSelected = _selectedIndex == i;
                        final isCorrect = q.correctIndex == i;

                        Color bg = Colors.white;
                        Color border = Colors.grey.shade300;

                        if (_showAnswer) {
                          if (isCorrect) {
                            bg = const Color(0xFFE8FFEF);
                            border = const Color(0xFF36D399);
                          } else if (isSelected && !isCorrect) {
                            bg = const Color(0xFFFFE8E8);
                            border = const Color(0xFFE57A7A);
                          }
                        } else if (isSelected) {
                          bg = const Color(0xFFF0F8FF);
                          border = const Color(0xFF36D399);
                        }

                        return GestureDetector(
                          onTap: () => _selectOption(i),
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border, width: 1.4),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(option, style: const TextStyle(fontSize: 16, color: Color(0xFF2D4059))),
                                ),
                                if (_showAnswer && isCorrect)
                                  const Icon(Icons.check_circle, color: Color(0xFF36D399))
                                else if (_showAnswer && isSelected && !isCorrect)
                                  const Icon(Icons.cancel, color: Color(0xFFE57A7A))
                                else if (!_showAnswer && isSelected)
                                  const Icon(Icons.radio_button_checked, color: Color(0xFF36D399))
                                else
                                  const Icon(Icons.radio_button_off, color: Colors.grey),
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
                        backgroundColor: const Color(0xFF36D399),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _showAnswer ? (_current < _questions.length - 1 ? 'Next' : 'Finish') : 'Check',
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
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
