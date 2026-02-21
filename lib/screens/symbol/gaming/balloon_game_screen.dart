import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class BalloonGameScreen extends StatefulWidget {
  final int grade;
  final int level;

  const BalloonGameScreen({
    super.key,
    required this.grade,
    required this.level,
  });

  @override
  State<BalloonGameScreen> createState() => _BalloonGameScreenState();
}

class _BalloonGameScreenState extends State<BalloonGameScreen> with SingleTickerProviderStateMixin {
  int _score = 2755;
  int _num1 = 2;
  int _num2 = 2;
  int _result = 4;
  String? _selectedOperation;
  String _correctOperation = '+';
  List<String> _options = ['+', '-', '='];

  final GlobalKey _overlayKey = GlobalKey();
  final GlobalKey _monsterKey = GlobalKey();
  final List<GlobalKey> _optionKeys = [GlobalKey(), GlobalKey(), GlobalKey()];

  late AnimationController _feedController;
  late Animation<Offset> _feedPositionAnim;
  late Animation<double> _feedScaleAnim;

  bool _isFeeding = false;
  String _feedingText = '';
  Color _feedingColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _feedController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _feedController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishFeeding();
      }
    });

    _feedPositionAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_feedController);
    _feedScaleAnim = Tween<double>(begin: 1.0, end: 1.0).animate(_feedController);

    _generateQuestion();
  }

  @override
  void dispose() {
    _feedController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = math.Random();
    final operations = ['+', '-', '×', '÷'];
    _correctOperation = operations[random.nextInt(operations.length)];

    switch (_correctOperation) {
      case '+':
        _num1 = random.nextInt(5) + 1;
        _num2 = random.nextInt(5) + 1;
        _result = _num1 + _num2;
        break;
      case '-':
        _result = random.nextInt(5) + 1;
        _num2 = random.nextInt(_result + 1);
        _num1 = _result + _num2;
        break;
      case '×':
        _num1 = random.nextInt(5) + 1;
        _num2 = random.nextInt(5) + 1;
        _result = _num1 * _num2;
        break;
      case '÷':
        _num2 = random.nextInt(5) + 1;
        _result = random.nextInt(5) + 1;
        _num1 = _num2 * _result;
        break;
    }

    _options = [_correctOperation];
    while (_options.length < 3) {
      String op = operations[random.nextInt(operations.length)];
      if (!_options.contains(op)) {
        _options.add(op);
      }
    }
    _options.shuffle();
  }

  void _onOptionSelected(int index, String text, Color color) {
    if (_isFeeding) return;

    final RenderBox? optionBox =
        _optionKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? monsterBox =
        _monsterKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        _overlayKey.currentContext?.findRenderObject() as RenderBox?;

    if (optionBox != null && monsterBox != null && overlayBox != null) {
      final startPosGlobal = optionBox.localToGlobal(Offset.zero);
      // Target center of monster mouth
      final endPosGlobal = monsterBox.localToGlobal(Offset(
        monsterBox.size.width / 2 - 52.5, // 52.5 is half flying widget width
        monsterBox.size.height / 2 - 52.5 + 20, // +20 to aim slightly lower (mouth)
      ));

      final startPos = overlayBox.globalToLocal(startPosGlobal);
      final endPos = overlayBox.globalToLocal(endPosGlobal);

      setState(() {
        _selectedOperation = text;
        _feedingText = text;
        _feedingColor = color;
        _isFeeding = true;
      });

      _feedPositionAnim = Tween<Offset>(begin: startPos, end: endPos).animate(
        CurvedAnimation(parent: _feedController, curve: Curves.easeInOut),
      );
      _feedScaleAnim = Tween<double>(begin: 1.0, end: 0.2).animate(
        CurvedAnimation(parent: _feedController, curve: Curves.easeInOut),
      );

      _feedController.forward(from: 0.0);
    } else {
      _checkAnswer(text);
    }
  }

  void _finishFeeding() {
    setState(() {
      _isFeeding = false;
    });
    _checkAnswer(_feedingText);
  }

  void _checkAnswer(String operation) {
    if (operation == _correctOperation) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _score += 10;
            _selectedOperation = null;
            _generateQuestion();
          });
        }
        Get.snackbar(
          'Correct! 🎉',
          '+10 points',
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 1),
        );
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _selectedOperation = null;
          });
        }
        Get.snackbar(
          'Try Again! 💭',
          'Keep trying!',
          backgroundColor: const Color(0xFFFF9800),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 1),
        );
      });
    }
  }

  Widget _buildTopCircle(String text) {
    return Container(
      width: 75,
      height: 75,
      decoration: const BoxDecoration(
        color: Color(0xFF8B3A1C),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.lora(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOperationBox({required String text}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF8B3A1C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCircle(int index, String text, Color color) {
    final isSelected = _selectedOperation == text;
    // Don't show correct/wrong border while flying
    final isCorrect = isSelected && text == _correctOperation && !_isFeeding;
    final isWrong = isSelected && text != _correctOperation && !_isFeeding;

    Color borderColor = Colors.transparent;
    if (isCorrect) borderColor = Colors.green;
    if (isWrong) borderColor = Colors.red;

    final shadowColor = color == Colors.white ? const Color(0xFFE0E0E0) : const Color(0xFFE4D82C);
    
    final bool isFlying = _isFeeding && isSelected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _onOptionSelected(index, text, color),
          child: Container(
            key: _optionKeys[index],
            width: 105,
            height: 105,
            decoration: isFlying ? const BoxDecoration(shape: BoxShape.circle) : BoxDecoration(
              color: shadowColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: isSelected ? 4 : 0),
            ),
            child: isFlying ? null : Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 105,
                height: 98,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 55,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF19324B), // Dark navy color for symbols
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: 90,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF6D4C41), // Brown stand
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF5D4037),
              width: 1.5,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildFlyingOptionCircle(String text, Color color) {
    final shadowColor = color == Colors.white ? const Color(0xFFE0E0E0) : const Color(0xFFE4D82C);
    
    return Container(
      width: 105,
      height: 105,
      decoration: BoxDecoration(
        color: shadowColor,
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 105,
          height: 98,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 55,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF19324B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFC2D2B8), // Matching pale green
      body: Stack(
        key: _overlayKey,
        children: [
          // Background Landscape (Bottom Half only)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.52,
            child: Image.asset(
              'assets/symbols/gaminBack.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Home button
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B6447), // Dark brown color
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.home_outlined, color: Colors.black, size: 40),
                          onPressed: () => Get.back(),
                        ),
                      ),
                      // Score
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8), // More rectangular in UI
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDAA520), // Gold
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.eco, color: Colors.white, size: 20), // Clover substitute
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$_score',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Equation Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTopCircle('$_num1'),
                    const SizedBox(width: 12),
                    _buildOperationBox(text: '?'),
                    const SizedBox(width: 12),
                    _buildTopCircle('$_num2'),
                    const SizedBox(width: 12),
                    _buildOperationBox(text: '='),
                    const SizedBox(width: 12),
                    _buildTopCircle('$_result'),
                  ],
                ),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Feed Me Answer Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF67A43), // Vibrant orange
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Feed Me Answer',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Ghost Image
                        SizedBox(
                          height: 250,
                          child: Stack(
                            key: _monsterKey,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB3E5FC).withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Image.asset(
                                'assets/symbols/gostgamming.png',
                                height: 230,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Options (Bottom Circles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 70),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionCircle(0, _options[0], Colors.white),
                      _buildOptionCircle(1, _options[1], const Color(0xFFFFF111)), // Bright yellow
                      _buildOptionCircle(2, _options[2], Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Side icons
          Positioned(
            right: 16,
            top: 240,
            child: Column(
              children: [
                _buildSideIcon(Icons.volume_up),
                const SizedBox(height: 18),
                _buildSideIcon(Icons.pause),
                const SizedBox(height: 18),
                _buildSideIcon(Icons.settings),
              ],
            ),
          ),

          // Flying animation overlay
          if (_isFeeding)
            AnimatedBuilder(
              animation: _feedController,
              builder: (context, child) {
                return Positioned(
                  left: _feedPositionAnim.value.dx,
                  top: _feedPositionAnim.value.dy,
                  child: Transform.scale(
                    scale: _feedScaleAnim.value,
                    child: child,
                  ),
                );
              },
              child: _buildFlyingOptionCircle(_feedingText, _feedingColor),
            ),
        ],
      ),
    );
  }
}
