import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/services/learning_flow_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// VideoLessonScreen - Display video lesson with Continue button
class VideoLessonScreen extends StatefulWidget {
  final Activity activity;
  final List<Activity> allActivities;
  final int currentNumber;
  final LearningLevel level;
  
  const VideoLessonScreen({
    super.key,
    required this.activity,
    required this.allActivities,
    required this.currentNumber,
    required this.level,
  });
  
  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  bool _videoCompleted = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  
  @override
  void initState() {
    super.initState();
    _initVideo();
  }
  
  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    // Determine URL from activity metadata
    String? url;
    try {
      final meta = widget.activity.metadata;
      if (meta != null) {
        if (meta.containsKey('url')) {
          url = meta['url'] as String?;
        } else if (meta.containsKey('video') && meta['video'] is Map) {
          url = (meta['video'] as Map)['url'] as String?;
        } else if (meta.containsKey('source')) {
          url = meta['source'] as String?;
        }
      }
    } catch (_) {
      url = null;
    }

    // Fallback: if activity title looks like a URL, use it
    url ??= (widget.activity.title.contains('http') ? widget.activity.title : null);

    debugPrint('🎬 Initializing video for number ${widget.currentNumber}');
    debugPrint('   URL/Path: $url');

    try {
      if (url != null && url.startsWith('http')) {
        debugPrint('   Loading network video...');
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      } else if (url != null && url.isNotEmpty) {
        // treat as asset
        debugPrint('   Loading asset video...');
        _videoController = VideoPlayerController.asset(url);
      }

      if (_videoController != null) {
        debugPrint('   Initializing video controller...');
        await _videoController!.initialize();
        debugPrint('   ✅ Video initialized successfully');
        
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          showControls: true,
        );

        // listen for end of playback
        _videoController!.addListener(() {
          if (!_videoController!.value.isPlaying &&
              _videoController!.value.position >= _videoController!.value.duration &&
              !_videoCompleted) {
            debugPrint('   ✅ Video playback completed');
            setState(() {
              _videoCompleted = true;
            });
          }
        });

        if (mounted) setState(() {});
      } else {
        // No URL found - mark completed so user can continue
        debugPrint('   ⚠️ No video URL found, marking as completed');
        setState(() {
          _videoCompleted = true;
        });
      }
    } catch (e) {
      debugPrint('   ❌ Error initializing video: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      // mark as completed so user won't be blocked
      setState(() {
        _videoCompleted = true;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Learn Number ${widget.currentNumber}'),
        backgroundColor: Color(AppColors.numberColor),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video player area
            Expanded(
              child: Center(
                child: _buildVideoPlaceholder(),
              ),
            ),
            
            // Controls
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(AppConstants.standardPadding),
              child: Column(
                children: [
                  // Number display
                  // NumberDisplay(
                  //   number: widget.currentNumber,
                  //   word: NumberWords.getWord(widget.currentNumber),
                  // ),
                  const SizedBox(height: 24),
                  
                  // Continue button
                  ActionButton(
                    text: 'Continue',
                    icon: Icons.arrow_forward,
                    isEnabled: _videoCompleted,
                    onPressed: _onContinue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoPlaceholder() {
    // If video initialized, show Chewie player
    if (_chewieController != null && _videoController != null && _videoController!.value.isInitialized) {
      return Container(
        margin: const EdgeInsets.all(AppConstants.standardPadding),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Chewie(
            controller: _chewieController!,
          ),
        ),
      );
    }

    // Fallback placeholder
    return Container(
      margin: const EdgeInsets.all(AppConstants.standardPadding),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _videoCompleted ? Icons.check_circle : Icons.play_circle_outline,
            size: 100,
            color: _videoCompleted 
                ? Color(AppColors.successColor)
                : Colors.white,
          ),
          const SizedBox(height: 24),
          Text(
            _videoCompleted 
                ? 'Video Completed!' 
                : 'Preparing video...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Learn about number ${widget.currentNumber}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          if (!_videoCompleted) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ],
      ),
    );
  }
  
  void _onContinue() async {
    debugPrint('🎬 Video continue button pressed');
    debugPrint('  Current activity: ${widget.activity.id} (${widget.activity.type})');
    debugPrint('  Current number: ${widget.currentNumber}');
    debugPrint('  Level: ${widget.level.levelNumber}');
    
    // Use LearningFlowManager to handle progression
    final learningFlowManager = LearningFlowManager.instance;
    
    try {
      await learningFlowManager.moveToNextActivity(
        currentActivity: widget.activity,
        currentNumber: widget.currentNumber,
        level: widget.level,
        isTutorial: true, // Tutorial mode uses easy questions
      );
      debugPrint('  ✅ moveToNextActivity completed');
    } catch (e) {
      debugPrint('  ❌ Error in moveToNextActivity: $e');
      Get.snackbar(
        'Error',
        'Failed to load next activity: $e',
        backgroundColor: Color(AppColors.errorColor),
        colorText: Colors.white,
      );
    }
  }
}
