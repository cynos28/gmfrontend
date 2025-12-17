import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ganithamithura/utils/constants.dart';

/// SuccessAnimation - Animated success feedback
class SuccessAnimation extends StatelessWidget {
  final String message;
  final VoidCallback? onComplete;
  
  const SuccessAnimation({
    super.key,
    this.message = 'Great Job!',
    this.onComplete,
  });
  
  @override
  Widget build(BuildContext context) {
    // Auto-dismiss after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (onComplete != null) {
        onComplete!();
      }
    });
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon with animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppConstants.mediumAnimationDuration,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.check_circle,
                        color: Color(AppColors.successColor),
                        size: 80,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedBuilder(
                        animation: AlwaysStoppedAnimation(0),
                        builder: (context, child) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: AppConstants.shortAnimationDuration,
                            builder: (context, value, child) {
                              return Icon(
                                Icons.star,
                                color: Color(AppColors.warningColor).withOpacity(value),
                                size: 32,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// FailureAnimation - Animated failure feedback
class FailureAnimation extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onSkip;
  
  const FailureAnimation({
    super.key,
    this.message = 'Try Again!',
    this.onRetry,
    this.onSkip,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Failure icon with animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppConstants.mediumAnimationDuration,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.cancel,
                        color: Color(AppColors.errorColor),
                        size: 80,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onRetry != null)
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(AppColors.primaryColor),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (onSkip != null)
                      TextButton(
                        onPressed: onSkip,
                        child: const Text('Skip'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// LoadingOverlay - Show loading indicator
class LoadingOverlay extends StatelessWidget {
  final String message;
  
  const LoadingOverlay({
    super.key,
    this.message = 'Loading...',
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ScoreCard - Display test/activity score
class ScoreCard extends StatelessWidget {
  final int score;
  final int total;
  final String title;
  
  const ScoreCard({
    super.key,
    required this.score,
    required this.total,
    this.title = 'Your Score',
  });
  
  double get percentage => total > 0 ? (score / total) * 100 : 0;
  
  Color get scoreColor {
    if (percentage >= 80) return Color(AppColors.successColor);
    if (percentage >= 60) return Color(AppColors.warningColor);
    return Color(AppColors.errorColor);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[300],
                    color: scoreColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score/$total',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Correct', score, Color(AppColors.successColor)),
                _buildStatItem('Wrong', total - score, Color(AppColors.errorColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

/// NumberDisplay - Large animated number display
class NumberDisplay extends StatelessWidget {
  final int number;
  final String? word;
  
  const NumberDisplay({
    super.key,
    required this.number,
    this.word,
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppConstants.mediumAnimationDuration,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (value * 0.5),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(AppColors.numberColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                border: Border.all(
                  color: Color(AppColors.numberColor),
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: Color(AppColors.numberColor),
                    ),
                  ),
                  if (word != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      word!,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(AppColors.numberColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
