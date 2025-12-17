import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Progress;
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/api/api_service.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/bucket_manager.dart';
import 'package:ganithamithura/screens/number/trace/trace_activity_screen.dart';
import 'package:ganithamithura/screens/number/read/read_activity_screen.dart';
import 'package:ganithamithura/screens/number/say/say_activity_screen.dart';
import 'package:ganithamithura/screens/number/object_detection/object_detection_activity_screen.dart';

/// TestScreen - Beginner progress test
class TestScreen extends StatefulWidget {
  final String testType; // 'beginner', 'intermediate', 'advanced'
  
  const TestScreen({
    super.key,
    required this.testType,
  });
  
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _apiService = ApiService.instance;
  final _storageService = StorageService.instance;
  final _bucketManager = BucketManager.instance;
  
  bool _isLoading = true;
  bool _testStarted = false;
  List<Activity> _testActivities = [];
  int _currentActivityIndex = 0;
  Map<String, bool> _results = {}; // activityId -> wasCorrect
  
  @override
  void initState() {
    super.initState();
    _loadTestActivities();
  }
  
  Future<void> _loadTestActivities() async {
    try {
      List<Activity> activities;
      
      if (widget.testType == 'beginner') {
        // Fetch from backend
        activities = await _apiService.getBeginnerTestActivities();
      } else {
        // TODO: Phase 2 - Implement other test types
        throw Exception('Test type not yet implemented');
      }
      
      setState(() {
        _testActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to load test: $e',
        backgroundColor: Color(AppColors.errorColor),
        colorText: Colors.white,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(AppColors.backgroundColor),
        body: const Center(
          child: LoadingOverlay(message: 'Loading test...'),
        ),
      );
    }
    
    if (!_testStarted) {
      return _buildTestIntro();
    }
    
    if (_currentActivityIndex >= _testActivities.length) {
      return _buildTestResults();
    }
    
    return _buildTestActivity();
  }
  
  Widget _buildTestIntro() {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text('${_getTestTitle()} Test'),
        backgroundColor: Color(AppColors.successColor),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.standardPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz,
                size: 100,
                color: Color(AppColors.successColor),
              ),
              const SizedBox(height: 24),
              Text(
                '${_getTestTitle()} Test',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Test your knowledge with ${_testActivities.length} activities',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              Card(
                elevation: AppConstants.cardElevation,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.standardPadding),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.numbers, 'Questions: ${_testActivities.length}'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.timer, 'No time limit'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.school, 'Passing score: 70%'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              ActionButton(
                text: 'Start Test',
                icon: Icons.play_arrow,
                color: Color(AppColors.successColor),
                onPressed: () {
                  setState(() {
                    _testStarted = true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Color(AppColors.successColor)),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
  
  Widget _buildTestActivity() {
    final activity = _testActivities[_currentActivityIndex];
    
    // For test mode, we'll use simplified versions
    // In production, you'd render actual activity screens
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text('Question ${_currentActivityIndex + 1}/${_testActivities.length}'),
        backgroundColor: Color(AppColors.successColor),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.standardPadding),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: _currentActivityIndex / _testActivities.length,
                backgroundColor: Colors.grey[300],
                color: Color(AppColors.successColor),
              ),
              const SizedBox(height: 24),
              
              // Activity info
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getActivityIcon(activity.type),
                        size: 80,
                        color: Color(AppColors.numberColor),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Activity Type: ${activity.type}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Mock answer buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitAnswer(activity.id, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.errorColor),
                        padding: const EdgeInsets.all(20),
                      ),
                      child: const Text(
                        'Wrong',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitAnswer(activity.id, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.successColor),
                        padding: const EdgeInsets.all(20),
                      ),
                      child: const Text(
                        'Correct',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getActivityIcon(String type) {
    switch (type) {
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
  
  void _submitAnswer(String activityId, bool isCorrect) {
    setState(() {
      _results[activityId] = isCorrect;
      _currentActivityIndex++;
    });
  }
  
  Widget _buildTestResults() {
    final correctCount = _results.values.where((v) => v).length;
    final totalCount = _testActivities.length;
    
    final testResult = TestResult(
      testType: widget.testType,
      totalQuestions: totalCount,
      correctAnswers: correctCount,
      completedAt: DateTime.now(),
      activityIds: _testActivities.map((a) => a.id).toList(),
      activityResults: _results,
    );
    
    // Save result
    _storageService.saveTestResult(testResult);
    
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Test Complete'),
        backgroundColor: Color(AppColors.successColor),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.standardPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScoreCard(
                score: correctCount,
                total: totalCount,
                title: 'Your Test Score',
              ),
              
              const SizedBox(height: 32),
              
              if (testResult.isPassed) ...[
                Icon(
                  Icons.celebration,
                  size: 80,
                  color: Color(AppColors.successColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You passed the test!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.replay,
                  size: 80,
                  color: Color(AppColors.warningColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Keep Practicing!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try again to improve your score',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ],
              
              const SizedBox(height: 48),
              
              ActionButton(
                text: 'Retake Test',
                icon: Icons.refresh,
                onPressed: () {
                  setState(() {
                    _currentActivityIndex = 0;
                    _results.clear();
                    _testStarted = false;
                  });
                  _loadTestActivities();
                },
              ),
              
              const SizedBox(height: 12),
              
              ActionButton(
                text: 'Back to Home',
                icon: Icons.home,
                color: Color(AppColors.numberColor),
                onPressed: () {
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getTestTitle() {
    switch (widget.testType) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Unknown';
    }
  }
}
