import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/ui_helpers.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/services/api/number_api_service.dart';
import 'package:ganithamithura/services/learning_flow_manager.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';

/// LevelSelectionScreen - Display 5 levels with only Level 1 enabled
class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late List<LearningLevel> _levels;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLevels();
  }

  Future<void> _initializeLevels() async {
    final storageService = StorageService.instance;
    
    // Load unlock status from storage (set by progress test)
    final level1Unlocked = await storageService.isLevelUnlocked(1);
    final level2Unlocked = await storageService.isLevelUnlocked(2);
    final level3Unlocked = await storageService.isLevelUnlocked(3);
    final level4Unlocked = await storageService.isLevelUnlocked(4);
    final level5Unlocked = await storageService.isLevelUnlocked(5);
    
    setState(() {
      _levels = [
        LearningLevel(
          levelNumber: 1,
          title: 'Level 1',
          description: 'Numbers 1-10',
          minNumber: 1,
          maxNumber: 10,
          isUnlocked: level1Unlocked,
          totalActivities: 50, // 10 numbers × 5 activities
          completedActivities: 0,
        ),
        LearningLevel(
          levelNumber: 2,
          title: 'Level 2',
          description: 'Numbers 11-20',
          minNumber: 11,
          maxNumber: 20,
          isUnlocked: level2Unlocked,
        ),
        LearningLevel(
          levelNumber: 3,
          title: 'Level 3',
          description: 'Numbers 21-50',
          minNumber: 21,
          maxNumber: 50,
          isUnlocked: level3Unlocked,
        ),
        LearningLevel(
          levelNumber: 4,
          title: 'Level 4',
          description: 'Numbers 51-100',
          minNumber: 51,
          maxNumber: 100,
          isUnlocked: level4Unlocked,
        ),
        LearningLevel(
          levelNumber: 5,
          title: 'Level 5',
          description: 'Advanced Numbers',
          minNumber: 100,
          maxNumber: 1000,
          isUnlocked: level5Unlocked,
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text('Select Level : ${AppConstants.numBaseUrl}'),
        backgroundColor: Color(AppColors.numberColor),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.standardPadding),
                child: ListView.builder(
                  itemCount: _levels.length,
                  itemBuilder: (context, index) {
                    final level = _levels[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LevelCard(
                        levelNumber: level.levelNumber,
                        title: level.title,
                        description: level.description,
                        isUnlocked: level.isUnlocked,
                        progress: level.progress,
                        onTap: level.isUnlocked
                            ? () => _startLevel(level)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  void _startLevel(LearningLevel level) async {
    try {
      // Show loading with a small delay to ensure overlay is ready
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      debugPrint('Starting Level ${level.levelNumber} - Fetching activities...');

      Get.dialog(
        Material(
          color: Colors.transparent,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Additional delay to ensure dialog is fully rendered
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) {
        Get.back();
        return;
      }

      // Fetch activities for this level with timeout
      final activities = await NumApiService.instance
          .getActivitiesForLevel(level.levelNumber)
          .timeout(
            Duration(seconds: AppConstants.apiTimeout),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your internet connection.',
              );
            },
          );

      if (!mounted) {
        Get.back();
        return;
      }

      if (activities.isEmpty) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
        await UIHelpers.showSafeSnackbar(
          title: 'No Activities',
          message:
              'No activities found for this level. Please try again later.',
          backgroundColor: Color(AppColors.warningColor),
        );
        return;
      }

      Get.back(); // Close loading

      // Use LearningFlowManager to start/resume learning
      final learningFlowManager = LearningFlowManager.instance;
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if there's a saved session for this level
      final savedSession = learningFlowManager.getSavedSession();

      if (savedSession != null && savedSession.level == level.levelNumber) {
        // Resume from saved position (skips completed activities like video)
        debugPrint(
          '📥 Resuming from saved session: Number ${savedSession.number}',
        );
        await learningFlowManager.resumeLearning(levelData: level);
      } else {
        // Start fresh from the first number
        debugPrint('🆕 Starting fresh from number ${level.minNumber}');
        await learningFlowManager.startLearningFromNumber(
          level: level.levelNumber,
          startNumber: level.minNumber,
          levelData: level,
        );
      }
    } catch (e) {
      debugPrint('Error in _startLevel: $e');

      // Safely close dialog if it's open
      try {
        if (mounted && Get.isDialogOpen == true) {
          Get.back();
        }
      } catch (_) {
        // Dialog might not be open, ignore
      }

      // Wait before showing snackbar
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      final errorMessage = UIHelpers.getErrorMessage(e);

      // Use ScaffoldMessenger as fallback for more reliability
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(errorMessage, style: const TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Color(AppColors.errorColor),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (snackbarError) {
        debugPrint('Could not show snackbar: $snackbarError');
      }
    }
  }
}
