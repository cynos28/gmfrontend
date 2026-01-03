/// Kids-Friendly Design System for Ganithamithura
/// Target: Children aged 6-10, Grades 1-4
/// Design: Playful, colorful, simple with big elements

library;

import 'package:flutter/material.dart';

/// Kids-friendly color palette
/// Using bright, vibrant colors that appeal to 6-10 year olds
class KidsColors {
  // Primary accent color (bright blue)
  static const Color primaryAccent = Color(0xFF4285F4);
  static const Color primaryLight = Color(0xFF7CB3FF);
  static const Color primaryLighter = Color(0xFFB3D7FF);
  static const Color primaryBackground = Color(0xFFE8F4FF);
  
  // Secondary accent color (vibrant green)
  static const Color secondaryAccent = Color(0xFF34C759);
  static const Color secondaryLight = Color(0xFF69E085);
  static const Color secondaryBackground = Color(0xFFE6F9EC);
  
  // Highlight color (bright orange)
  static const Color highlightAccent = Color(0xFFFF9500);
  static const Color highlightLight = Color(0xFFFFB84D);
  static const Color highlightBackground = Color(0xFFFFF3E0);
  
  // Fun accent colors
  static const Color purple = Color(0xFF9C27B0);
  static const Color purpleLight = Color(0xFFBA68C8);
  static const Color pink = Color(0xFFFF4081);
  static const Color pinkLight = Color(0xFFFF80AB);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color yellowLight = Color(0xFFFFF176);
  
  // Backgrounds (bright and clean)
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFF);
  static const Color backgroundWarmer = Color(0xFFFFFBF5);
  static const Color backgroundCream = Color(0xFFFFF9F0);
  
  // Text colors (very clear, high contrast)
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textTertiary = Color(0xFF757575);
  
  // Feedback colors (bright and clear)
  static const Color success = Color(0xFF34C759);
  static const Color successLight = Color(0xFFE6F9EC);
  static const Color successDark = Color(0xFF28A745);
  static const Color error = Color(0xFFFF3B30);
  static const Color errorLight = Color(0xFFFFE5E3);
  static const Color errorDark = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFCC00);
  static const Color warningLight = Color(0xFFFFF9E5);
  
  // Module colors (bright and distinguishable)
  static const Color lengthColor = Color(0xFF4285F4);
  static const Color lengthBackground = Color(0xFFE8F4FF);
  static const Color areaColor = Color(0xFF34C759);
  static const Color areaBackground = Color(0xFFE6F9EC);
  static const Color capacityColor = Color(0xFF00BCD4);
  static const Color capacityBackground = Color(0xFFE0F7FA);
  static const Color weightColor = Color(0xFFFF9500);
  static const Color weightBackground = Color(0xFFFFF3E0);
  
  // Borders (colorful)
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color borderBright = Color(0xFF4285F4);
  
  // Star/achievement colors (shiny gold)
  static const Color starGold = Color(0xFFFFD700);
  static const Color starOrange = Color(0xFFFFB800);
  static const Color starBackground = Color(0xFFFFFBE6);
}

/// Typography scale for kids aged 6-10
/// Using larger, bolder fonts for easy reading
class KidsTypography {
  // Main title (screen headers) - Extra large and bold
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: KidsColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  // Subtitle (section headers) - Large and friendly
  static const TextStyle subtitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: KidsColors.textPrimary,
    height: 1.3,
  );
  
  // Question text - Clear and prominent
  static const TextStyle question = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: KidsColors.textPrimary,
    height: 1.5,
  );
  
  // Answer options / labels - Big and readable
  static const TextStyle label = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: KidsColors.textPrimary,
    height: 1.4,
  );
  
  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: KidsColors.textSecondary,
    height: 1.5,
  );
  
  // Helper text
  static const TextStyle helper = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: KidsColors.textTertiary,
    height: 1.4,
  );
  
  // Small text (badges, counts)
  static const TextStyle small = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: KidsColors.textSecondary,
    height: 1.2,
  );
  
  // Button text - Bold and clear
  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.3,
  );
  
  // Large button text - Extra prominent
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.4,
  );
}

/// Spacing constants - Generous for small fingers
class KidsSpacing {
  // Minimum tap target size (larger for kids)
  static const double minTapTarget = 56.0;
  
  // Screen padding (extra space for comfortable viewing)
  static const double screenPadding = 24.0;
  static const double screenPaddingLarge = 28.0;
  
  // Card spacing (more breathing room)
  static const double cardPadding = 20.0;
  static const double cardPaddingLarge = 24.0;
  static const double cardMargin = 16.0;
  static const double cardMarginLarge = 20.0;
  
  // Element spacing
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double xxxl = 36.0;
  
  // Border radius (more rounded for playful look)
  static const double radiusSmall = 16.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 28.0;
  static const double radiusRound = 50.0;
}

/// Shadow styles for depth and pop-out effect
class KidsShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
  
  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
  
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  // Fun colored shadows
  static List<BoxShadow> coloredBlue = [
    BoxShadow(
      color: KidsColors.primaryAccent.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> coloredGreen = [
    BoxShadow(
      color: KidsColors.secondaryAccent.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Reusable component styles for consistent UI
class KidsComponents {
  /// Primary button style (for main actions) - Big and colorful
  static ButtonStyle primaryButton({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? KidsColors.primaryAccent,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, KidsSpacing.minTapTarget + 4),
      padding: const EdgeInsets.symmetric(
        horizontal: KidsSpacing.xl,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
      ),
      elevation: 0,
      textStyle: KidsTypography.button,
    );
  }
  
  /// Secondary button style (for less important actions)
  static ButtonStyle secondaryButton({Color? borderColor}) {
    return OutlinedButton.styleFrom(
      foregroundColor: borderColor ?? KidsColors.primaryAccent,
      minimumSize: const Size(double.infinity, KidsSpacing.minTapTarget),
      padding: const EdgeInsets.symmetric(
        horizontal: KidsSpacing.xl,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
      ),
      side: BorderSide(
        color: borderColor ?? KidsColors.primaryAccent,
        width: 2,
      ),
      textStyle: KidsTypography.button,
    );
  }
  
  /// Card decoration (for content containers)
  static BoxDecoration card({
    Color? backgroundColor,
    Color? borderColor,
    List<BoxShadow>? shadow,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
      border: borderColor != null
          ? Border.all(color: borderColor, width: 2)
          : null,
      boxShadow: shadow ?? KidsShadows.soft,
    );
  }
  
  /// Question card decoration
  static BoxDecoration questionCard() {
    return BoxDecoration(
      color: KidsColors.primaryBackground,
      borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
      border: Border.all(
        color: KidsColors.primaryLight.withOpacity(0.3),
        width: 2,
      ),
    );
  }
  
  /// Answer option card (unselected)
  static BoxDecoration answerCard({
    required bool isSelected,
    required bool showFeedback,
    required bool isCorrect,
  }) {
    Color borderColor;
    Color backgroundColor;
    
    if (showFeedback) {
      if (isCorrect) {
        borderColor = KidsColors.success;
        backgroundColor = KidsColors.successLight;
      } else if (isSelected) {
        borderColor = KidsColors.error;
        backgroundColor = KidsColors.errorLight;
      } else {
        borderColor = KidsColors.borderLight;
        backgroundColor = Colors.white;
      }
    } else {
      borderColor = isSelected ? KidsColors.primaryAccent : KidsColors.borderLight;
      backgroundColor = isSelected ? KidsColors.primaryBackground : Colors.white;
    }
    
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
      border: Border.all(color: borderColor, width: 2.5),
      boxShadow: isSelected && !showFeedback ? KidsShadows.medium : null,
    );
  }
  
  /// Feedback container decoration
  static BoxDecoration feedbackCard({required bool isCorrect}) {
    return BoxDecoration(
      color: isCorrect ? KidsColors.successLight : KidsColors.errorLight,
      borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
      border: Border.all(
        color: isCorrect ? KidsColors.success : KidsColors.error,
        width: 2,
      ),
    );
  }
  
  /// Badge decoration (for letters A/B/C/D, difficulty, etc.)
  static BoxDecoration badge({Color? color}) {
    return BoxDecoration(
      color: (color ?? KidsColors.primaryAccent).withOpacity(0.15),
      borderRadius: BorderRadius.circular(KidsSpacing.radiusSmall),
    );
  }
  
  /// Icon container decoration
  static BoxDecoration iconContainer({Color? backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor ?? KidsColors.primaryBackground,
      borderRadius: BorderRadius.circular(KidsSpacing.radiusSmall),
    );
  }
}

/// Animation durations
class KidsAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
}

/// Module icons mapping
class KidsIcons {
  static IconData getModuleIcon(String moduleName) {
    switch (moduleName.toLowerCase()) {
      case 'length':
        return Icons.straighten_rounded;
      case 'area':
        return Icons.crop_square_rounded;
      case 'capacity':
        return Icons.local_drink_rounded;
      case 'weight':
        return Icons.fitness_center_rounded;
      case 'numbers':
        return Icons.looks_one_rounded;
      case 'symbols':
        return Icons.calculate_rounded;
      case 'shapes':
        return Icons.category_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}
