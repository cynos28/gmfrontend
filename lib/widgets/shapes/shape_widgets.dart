/// AR Challenge Card widget for measurement types
/// Shows icon, title, subtitle, and units for each AR challenge

import 'package:flutter/material.dart';

class ShapeMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon; // Emoji icon
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const ShapeMenuCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70, // Fixed height set to 70
        constraints: const BoxConstraints(
          maxWidth: 350, // Increased max width for better usability, adjust if needed
        ),
        decoration: BoxDecoration(
          color: const Color(0xB39BE5C9).withOpacity(0.24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xB39BE5C9),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with camera badge
            Stack(
              children: [
                // Main icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      icon,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D4059),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF2D4059).withOpacity(0.64),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0x80000000),
            ), // Arrow icon
          ],
        ),
      ),
    );
  }
}


class ShapeGameCard extends StatelessWidget {
  final String title;
  final String level;
  final String icon; // Emoji icon
  final Color backgroundColor;
  final Color borderColor;
  final int starCount;
  final VoidCallback onTap;
  final bool isLocked;

  const ShapeGameCard({
    Key? key,
    required this.title,
    required this.level,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.starCount,
    required this.onTap,
    this.isLocked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          height: 70, // Fixed height set to 70
          constraints: const BoxConstraints(
            maxWidth: 350, // Increased max width for better usability, adjust if needed
          ),
          decoration: BoxDecoration(
            color: isLocked 
                ? Colors.grey.withOpacity(0.24)
                : const Color(0xB39BE5C9).withOpacity(0.24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked ? Colors.grey : const Color(0xB39BE5C9),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with camera badge
              Stack(
                children: [
                  // Main icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isLocked 
                          ? Colors.grey.withOpacity(0.5)
                          : backgroundColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isLocked
                          ? const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 24,
                            )
                          : Image.asset(
                              icon,
                              width: 24,
                              height: 24,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game level
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF2D4059).withOpacity(0.64),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D4059),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        starCount,
                        (index) => const Icon(
                          Icons.star,
                          color: Color(0xFFF5C53D),
                          size: 16,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              isLocked
                  ? const Icon(
                      Icons.lock,
                      size: 20,
                      color: Color(0x80000000),
                    )
                  : const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0x80000000),
                    ), // Arrow or Lock icon
            ],
          ),
        ),
      ),
    );
  }
}
