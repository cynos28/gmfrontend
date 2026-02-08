import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class LevelIslandWidget extends StatefulWidget {
  final int levelNumber;
  final bool isLocked;
  final bool isCompleted;
  final VoidCallback? onTap;
  final double size;

  const LevelIslandWidget({
    super.key,
    required this.levelNumber,
    this.isLocked = true,
    this.isCompleted = false,
    this.onTap,
    this.size = 100,
  });

  @override
  State<LevelIslandWidget> createState() => _LevelIslandWidgetState();
}

class _LevelIslandWidgetState extends State<LevelIslandWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + math.Random().nextInt(1000)), // Randomize slightly
    );

    // Floating up and down animation
    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    if (!widget.isLocked) {
       _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLocked ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, widget.isLocked ? 0 : _floatAnimation.value),
            child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Island Base
                    Image.asset(
                      'assets/symbols/game/gammingLandIcon.png',
                      fit: BoxFit.contain,
                      // Removed color filter as requested: "without changing color for disable one"
                    ),

                    // Level Number Indicator - Positioned at bottom left/center
                    Positioned(
                      bottom: widget.size * 0.625,  // adjusted to sit at the base of the island
                      left: widget.size * 0.225,  // Centered horizontally: (1 - 0.35) / 2
                      child: Container(
                        width: widget.size * 0.35,
                        height: widget.size * 0.35,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black, // Always black background
                        ),
                        alignment: Alignment.center,
                        child: widget.isLocked
                            ? Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: widget.size * 0.18,
                              )
                            : Text(
                                '${widget.levelNumber}',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: widget.size * 0.18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    
                    // Stars or completion indicator could go here
                  ],
                ),
              ),
            );
        },
      ),
    );
  }
}
