import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/screens/symbol/widgets/floating_symbols_background.dart';
import 'package:ganithamithura/screens/symbol/widgets/symbol_intro_page.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_hunter_options_screen.dart';

class SymbolQuizIntroScreen extends StatefulWidget {
  const SymbolQuizIntroScreen({super.key});

  @override
  State<SymbolQuizIntroScreen> createState() => _SymbolQuizIntroScreenState();
}

class _SymbolQuizIntroScreenState extends State<SymbolQuizIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _startQuiz();
    }
  }

  void _startQuiz() {
    Get.to(() => const SymbolHunterOptionsScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symbol Hunter',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "Let's Learn Symbols Together !",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Floating Symbols Background (Reusable Widget)
            const FloatingSymbolsBackground(),
            
            // Slider Content
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Page 1: Short and Friendly
                SymbolIntroPage(
                  card1Text: 'Short and Friendly',
                  card1Color: const Color(0xFF6A5ACD), // SlateBlue
                  card2Text: 'Only 3 - 4 minutes.',
                  card2Color: const Color(0xFFFFE4E1),
                  descriptionText: 'Tap the best Answer.\nGrown - Ups can read the\nquestions.',
                  buttonText: 'NEXT',
                  onButtonPressed: _nextPage,
                ),
                
                // Page 2: Adaptive Path
                SymbolIntroPage(
                  card1Text: 'A path made just for You',
                  card1Color: const Color(0xFF6A5ACD), 
                  card2Text: 'We choose the right Level.',
                  card2Color: const Color(0xFFFFE4E1),
                  descriptionText: 'Practice only what need a\nlittle help + , - , × , ÷ , > , <',
                  buttonText: 'NEXT',
                  onButtonPressed: _nextPage,
                ),
                
                // Page 3: Safe and Simple
                SymbolIntroPage(
                  card1Text: 'Safe and Simple',
                  card1Color: const Color(0xFF6A5ACD),
                  card2Text: 'Your data stays Private.',
                  card2Color: const Color(0xFFFFE4E1),
                  descriptionText: 'Complete in one go for best\nresults.',
                  buttonText: "Let's Get\nStart !", // Wraps text to match button size roughly
                  onButtonPressed: _startQuiz,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
