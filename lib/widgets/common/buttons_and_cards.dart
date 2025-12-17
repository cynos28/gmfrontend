import 'package:flutter/material.dart';
import 'package:ganithamithura/utils/constants.dart';

/// ModuleButton - Reusable button for main modules
class ModuleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;
  
  const ModuleButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimationDuration,
        padding: const EdgeInsets.all(AppConstants.standardPadding),
        decoration: BoxDecoration(
          color: isEnabled ? color : Color(AppColors.disabledColor),
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ActionButton - Large primary button
class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isEnabled;
  final Color? color;
  final IconData? icon;
  
  const ActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.color,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Color(AppColors.primaryColor),
          disabledBackgroundColor: Color(AppColors.disabledColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
          elevation: AppConstants.cardElevation,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24),
              const SizedBox(width: 12),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// LevelCard - Card for level selection
class LevelCard extends StatelessWidget {
  final int levelNumber;
  final String title;
  final String description;
  final bool isUnlocked;
  final double progress;
  final VoidCallback? onTap;
  
  const LevelCard({
    super.key,
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.isUnlocked,
    this.progress = 0.0,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Card(
        elevation: AppConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        color: isUnlocked ? Colors.white : Colors.grey[300],
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.standardPadding),
          child: Row(
            children: [
              // Level number circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? Color(AppColors.numberColor)
                      : Color(AppColors.disabledColor),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$levelNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Level info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.black87 : Colors.grey,
                          ),
                        ),
                        if (!isUnlocked) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.lock, size: 18, color: Colors.grey),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnlocked ? Colors.black54 : Colors.grey,
                      ),
                    ),
                    if (isUnlocked && progress > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        color: Color(AppColors.successColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toInt()}% Complete',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUnlocked)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ActivityCard - Card for activity display
class ActivityCard extends StatelessWidget {
  final String title;
  final String type;
  final bool isCompleted;
  final VoidCallback onTap;
  
  const ActivityCard({
    super.key,
    required this.title,
    required this.type,
    required this.isCompleted,
    required this.onTap,
  });
  
  IconData _getIconForType() {
    switch (type) {
      case AppConstants.activityTypeVideo:
        return Icons.play_circle_outline;
      case AppConstants.activityTypeTrace:
        return Icons.edit;
      case AppConstants.activityTypeRead:
        return Icons.menu_book;
      case AppConstants.activityTypeSay:
        return Icons.mic;
      case AppConstants.activityTypeObjectDetection:
        return Icons.camera_alt;
      default:
        return Icons.assignment;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: AppConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.standardPadding),
          child: Row(
            children: [
              Icon(
                _getIconForType(),
                size: 32,
                color: Color(AppColors.numberColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isCompleted)
                Icon(
                  Icons.check_circle,
                  color: Color(AppColors.successColor),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
