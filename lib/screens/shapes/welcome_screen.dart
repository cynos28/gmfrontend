import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/shapes/shape_home_screen.dart';


/// WelcomeScreen - Main screen for Measurement module
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) {
      // Navigate to home
      Get.back();
      return;
    }

    if (index == _currentNavIndex) {
      // Already on current tab
      return;
    }

    // TODO: Navigate to other screens when ready
    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child:
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 280,
                      height: 220, // Adjusted height for 3 lines
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFEC76A0), // #EC76A0 25%
                            Color(0xFF5DCBE7), // #5DCBE7 71.15%
                          ],
                          stops: [0.25, 0.7115],
                        ).createShader(bounds),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start, // Align to the top of the SizedBox
                          crossAxisAlignment: CrossAxisAlignment.center, // Center text horizontally
                          children: [
                            Text(
                              'SHAPES',
                              style: GoogleFonts.bowlbyOneSc(
                                fontSize: 50,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                                height: 0.8, // line-height / font-size
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              '&',
                              style: GoogleFonts.bioRhyme(
                                fontSize: 40,
                                letterSpacing: 0,
                                height: 0.8, // line-height / font-size
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Pattern',
                              style: GoogleFonts.bowlbyOne(
                                fontSize: 50,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                                height: 0.8, // line-height / font-size
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 319,
                  height: 200,
                  child: Image.asset(
                    'assets/animations/Animation_Video_Generation_Complete.gif',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () {
                    Get.off(() => const ShapeHomeScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1AD7F), // Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // Border radius
                    ),
                    fixedSize: const Size(230, 68), // Width and height
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0), // Padding
                  ),
                  child: Text(
                    'Start Playing',
                    style: GoogleFonts.bioRhyme(
                      fontSize: 30, // Adjust font size as needed
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: _currentNavIndex,
                onTap: _onNavTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
