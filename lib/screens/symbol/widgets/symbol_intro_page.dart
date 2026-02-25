import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SymbolIntroPage extends StatelessWidget {
  final String card1Text;
  final Color card1Color;
  final String card2Text;
  final Color card2Color;
  final String descriptionText;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const SymbolIntroPage({
    super.key,
    required this.card1Text,
    required this.card1Color,
    required this.card2Text,
    required this.card2Color,
    required this.descriptionText,
    required this.buttonText,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              
              // Card 1 (Top)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: card1Color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: card1Color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  card1Text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Card 2 (Middle)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: card2Color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: card2Color.withOpacity(0.5), width: 1), // darkening border slightly
                ),
                child: Text(
                  card2Text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Description Card (Bottom)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E1), // Default light pink background for text
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB6C1), width: 1),
                ),
                child: Text(
                  descriptionText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Teacher Image and Button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 370,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Teacher Image
                Positioned(
                  right: 125,
                  top: 10,
                  child: Image.asset(
                    'assets/symbols/teacher1.png',
                    height: 370,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => 
                        const SizedBox(height: 200, width: 200, child: Center(child: Icon(Icons.person, size: 100))),
                  ),
                ),
                
                // Button
                Positioned(
                  right: 20,
                  bottom: 160,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF08080), // Light Coral/Pink
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFFF08080).withOpacity(0.4),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
