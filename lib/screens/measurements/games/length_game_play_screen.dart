/// Length Game Play Screen
/// Renders L-V1 (Ruler Explorer) and L-V4 (Build a Bridge) with kids-friendly UI,
/// adaptive difficulty, star rating and backend submission when the session ends.

// ignore_for_file: use_key_in_widget_constructors, dangling_library_doc_comments

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';
import 'package:ganithamithura/screens/measurements/ar_challenges/ar_length_measure_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { playing, wrongAnswer, showResult, complete }

// Per-variant target times (seconds per round)
const Map<String, int> _targetSeconds = {
  'L-V1': 45,
  'L-V4': 90,
};

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LengthGamePlayScreen extends StatefulWidget {
  final String variant; // 'L-V1' | 'L-V4'
  const LengthGamePlayScreen({required this.variant});

  @override
  State<LengthGamePlayScreen> createState() => _LengthGamePlayScreenState();
}

class _LengthGamePlayScreenState extends State<LengthGamePlayScreen>
    with TickerProviderStateMixin {
  // ── game config (loaded from backend) ──────────────────────────────────
  Map<String, dynamic> _params = {};
  int _hintsAllowed = 2;

  // ── round state ─────────────────────────────────────────────────────────
  int _round = 1; // 1-based
  static const int _totalRounds = 5;
  _Phase _phase = _Phase.playing;

  int _roundAttempts = 0;
  int _hintsUsedThisRound = 0;
  int _totalAttempts = 0;
  int _totalHints = 0;
  int _roundStars = 3;
  String _resultMessage = '';

  // ── timing ──────────────────────────────────────────────────────────────
  late DateTime _sessionStart;
  Timer? _timer;
  int _elapsedSeconds = 0;

  // ── round data by variant ────────────────────────────────────────────────
  // V1 - AR camera measurement
  double? _v1MeasuredCm;  // measured value from AR camera
  List<int> _v1Choices = [];
  int _v1Correct = 0;

  // V4 - Build a Bridge
  int _v4Target = 0;
  List<int> _v4Strips = [];
  Set<int> _v4Selected = {};
  List<int> _v4PlacedOrder = []; // placement order for visual bridge rendering

  // ── IRT adaptive state (L-V4) ───────────────────────────────────────────
  double _irtTheta = 0.0;           // IRT ability estimate
  int _irtDifficultyLevel = 1;      // 1-5 mapped from θ
  int _irtRoundsPlayed = 0;         // total rounds across sessions
  String _userId = 'student_001';   // loaded from prefs

  // ── completion ───────────────────────────────────────────────────────────
  int _totalStarsEarned = 0;
  bool _submitting = false;

  // ── animations ───────────────────────────────────────────────────────────
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _starCtrl;
  late Animation<double> _starAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  final _rng = Random();

  // ── pass threshold: 60% of max stars ─────────────────────────────────────
  static const int _passPercent = 60;

  // ── ordered variant list ─────────────────────────────────────────────────
  static const List<String> _variantOrder = ['L-V1', 'L-V4'];

  int get _activeTotalRounds => _totalRounds;

  String? get _nextVariantCode {
    final idx = _variantOrder.indexOf(widget.variant);
    if (idx < 0 || idx >= _variantOrder.length - 1) return null;
    return _variantOrder[idx + 1];
  }

  // V1 bench layout is computed responsively inside _buildV1 from MediaQuery.

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();

    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 8)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _starAnim = CurvedAnimation(parent: _starCtrl, curve: Curves.elasticOut);

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _loadAndStart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounceCtrl.dispose();
    _starCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INIT / ROUND GENERATION
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadAndStart() async {
    // Load student ID
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _userId = prefs.getString('student_id') ?? 'student_001';

    // For L-V4, fetch IRT-adapted parameters
    if (widget.variant == 'L-V4') {
      // Fetch IRT session state from backend
      final irtState = await GamesApiService.getIRTState(
        studentId: _userId,
        domain: 'length',
        variant: 'L-V4',
      );
      if (!mounted) return;
      _irtTheta = (irtState['theta'] as num?)?.toDouble() ?? 0.0;
      _irtDifficultyLevel = (irtState['difficulty_level'] as num?)?.toInt() ?? 1;
      _irtRoundsPlayed = (irtState['rounds_played'] as num?)?.toInt() ?? 0;

      // Load params merged with IRT-adapted bridge config
      _params = await GamesApiService.getParameters(
        'length',
        studentId: _userId,
        variant: 'L-V4',
      );
    } else {
      _params = await GamesApiService.getParameters('length');
    }

    if (!mounted) return;
    _hintsAllowed = (_params['hints'] as int?) ?? 2;
    _generateRound();
    _startTimer();
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _phase == _Phase.playing) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _generateRound() {
    setState(() {
      _phase = _Phase.playing;
      _roundAttempts = 0;
      _hintsUsedThisRound = 0;
      _roundStars = 3;
      _v1MeasuredCm = null;
      _v4Selected    = {};
      _v4PlacedOrder = [];
      _shakeCtrl.reset();
    });

    switch (widget.variant) {
      case 'L-V1':
        _genV1();
      case 'L-V4':
        _genV4();
    }
  }

  void _genV1() {
    // V1 uses AR measurement - no pre-generation needed
    // Choices will be generated after AR measurement completes
    setState(() {
      _v1MeasuredCm = null;
      _v1Choices = [];
      _v1Correct = 0;
    });
  }

  void _genV4() {
    // Get IRT-adapted params from backend (merged in _loadAndStart / _nextRound)
    final bridgeRange = (_params['bridge_target_range'] as List?)?.cast<num>() ?? [12, 18];
    final plankSizesParam = (_params['plank_sizes'] as List?)?.cast<num>();
    final plankCount = (_params['plank_count'] as num?)?.toInt() ?? 7;
    final minSolPlanks = (_params['min_solution_planks'] as num?)?.toInt() ?? 2;
    final maxSolPlanks = (_params['max_solution_planks'] as num?)?.toInt() ?? 4;

    // Convert plank sizes to int list
    final availablePlankSizes = plankSizesParam?.map((n) => n.toInt()).toList()
        ?? [3, 4, 5, 6, 7, 8];

    // Generate random target within IRT-adapted range
    final target = bridgeRange[0].toInt() +
                   _rng.nextInt(bridgeRange[1].toInt() - bridgeRange[0].toInt() + 1);

    // Find valid combinations (minSolPlanks..maxSolPlanks planks that sum to target)
    final validCombos = <List<int>>[];
    _findCombinations(
      availablePlankSizes, target, minSolPlanks, maxSolPlanks, [], 0, validCombos,
    );

    List<int> solution;
    if (validCombos.isNotEmpty) {
      solution = validCombos[_rng.nextInt(validCombos.length)];
    } else {
      // Fallback: pick minSolPlanks planks
      final shuffled = List.of(availablePlankSizes)..shuffle(_rng);
      solution = shuffled.take(minSolPlanks).toList();
    }

    // Add distractors to reach plankCount total
    final distractors = availablePlankSizes
        .where((s) => !solution.contains(s))
        .toList()
      ..shuffle(_rng);

    final neededDistractors = (plankCount - solution.length).clamp(0, distractors.length);
    final displayStrips = [...solution, ...distractors.take(neededDistractors)]..shuffle(_rng);

    setState(() {
      _v4Target = target;
      _v4Strips = displayStrips;
      _v4Selected = {};
    });
  }

  /// Recursive combination finder with configurable plank count range.
  void _findCombinations(
    List<int> sizes, int target, int minPlanks, int maxPlanks,
    List<int> current, int startIdx, List<List<int>> results,
  ) {
    if (current.length >= minPlanks) {
      final sum = current.fold(0, (a, b) => a + b);
      if (sum == target) {
        results.add(List.of(current));
        if (results.length > 50) return; // cap search
      }
    }
    if (current.length >= maxPlanks) return;
    for (int i = startIdx; i < sizes.length; i++) {
      current.add(sizes[i]);
      _findCombinations(sizes, target, minPlanks, maxPlanks, current, i, results);
      current.removeLast();
      if (results.length > 50) return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANSWER HANDLING
  // ─────────────────────────────────────────────────────────────────────────

  void _submitV1(int choice) {
    if (_phase != _Phase.playing || _v1MeasuredCm == null) return;
    setState(() => _roundAttempts++);
    
    // Check if choice is within ±2 cm of measured value
    final diff = (choice - _v1MeasuredCm!).abs();
    if (diff <= 2.0) {
      _roundCorrect('🎉 Great job! You measured ${_v1MeasuredCm!.toStringAsFixed(1)} cm and picked $choice cm!');
    } else {
      _roundWrong('Try again! Think about your measurement 📏');
    }
  }

  void _submitV4() {
    if (_phase != _Phase.playing) return;
    final total = _v4PlacedOrder.fold(0, (s, i) => s + _v4Strips[i]);
    setState(() => _roundAttempts++);
    if (total == _v4Target) {
      _roundCorrect('🌉 Bridge built! ${_v4PlacedOrder.length} planks = $_v4Target cm!');
    } else {
      _roundWrong(
          total < _v4Target ? 'Not enough planks! Add more 📏' : 'Too long! Remove a plank 📏');
    }
  }

  void _roundCorrect(String message) {
    _timer?.cancel();
    final stars = _calcStars(_roundAttempts, _hintsUsedThisRound);
    setState(() {
      _phase = _Phase.showResult;
      _resultMessage = message;
      _roundStars = stars;
      _totalAttempts += _roundAttempts;
      _totalHints += _hintsUsedThisRound;
      _totalStarsEarned += stars;
    });
    _starCtrl.forward(from: 0);
    // Submit to IRT engine in background (fire-and-forget)
    _submitRoundToIRT(true, stars);
  }

  void _roundWrong(String message) {
    setState(() {
      _phase = _Phase.wrongAnswer;
      _resultMessage = message;
      if (_roundAttempts >= 2) _roundStars = max(1, _roundStars - 1);
    });
    // After 3 failed attempts, count as incorrect round for IRT
    if (_roundAttempts >= 3) {
      _submitRoundToIRT(false, 0);
    }
    _shakeCtrl.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _phase = _Phase.playing;
          _resultMessage = '';
        });
      }
    });
  }

  int _calcStars(int attempts, int hints) {
    if (attempts == 1 && hints == 0) return 3;
    if (attempts <= 2 && hints <= 1) return 2;
    return 1;
  }

  void _useHint() {
    if (_hintsUsedThisRound >= _hintsAllowed) {
      Get.snackbar('No more hints!', 'You used all your hints for this round',
          backgroundColor: KidsColors.warning,
          colorText: KidsColors.textPrimary,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 16);
      return;
    }
    setState(() => _hintsUsedThisRound++);
    _showHintDialog();
  }

  void _showHintDialog() {
    String hint;
    switch (widget.variant) {
      case 'L-V1':
        hint =
            'Open your camera and measure a real object around you! '
            'Point at both ends carefully, then pick the closest answer. '
            'Remember: the answer should be within 2 cm of what you measured!';
      case 'L-V4':
        final partial = _v4Target ~/ 2;
        hint =
            'You need to reach $_v4Target cm in total. Try picking a strip close to $partial cm first!';
      default:
        hint = 'Look carefully and try again! You can do it! 💪';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFFFDE7),
        title: const Row(
          children: [
            Text('💡', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Text('Hint!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF8F00))),
          ],
        ),
        content: Text(hint,
            style: const TextStyle(fontSize: 17, height: 1.5, color: Color(0xFF5D4037))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F00),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text('Got it! ✓',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _nextRound() {
    if (_round >= _activeTotalRounds) {
      _completeGame();
    } else {
      setState(() => _round++);
      _generateRound();
      _startTimer();
    }
  }

  /// Submit round result to IRT engine (L-V4 only) and update local params
  /// for the *next* round generation.
  Future<void> _submitRoundToIRT(bool correct, int stars) async {
    if (widget.variant != 'L-V4') return;
    try {
      final result = await GamesApiService.submitRoundResult(
        studentId: _userId,
        domain: 'length',
        variant: 'L-V4',
        correct: correct,
        attempts: _roundAttempts,
        hintsUsed: _hintsUsedThisRound,
        timeSeconds: _elapsedSeconds.toDouble(),
        starsEarned: stars,
      );
      // Update local IRT state for next round
      _irtTheta = (result['theta'] as num?)?.toDouble() ?? _irtTheta;
      _irtDifficultyLevel = (result['difficulty_level'] as num?)?.toInt() ?? _irtDifficultyLevel;
      _irtRoundsPlayed = (result['rounds_played'] as num?)?.toInt() ?? _irtRoundsPlayed;
      // Merge next-round params
      final nextParams = result['next_params'] as Map<String, dynamic>?;
      if (nextParams != null) {
        _params.addAll(nextParams);
        _hintsAllowed = (nextParams['hints'] as int?) ?? _hintsAllowed;
      }
    } catch (_) {
      // Offline — continue with current params
    }
  }

  Future<void> _completeGame() async {
    setState(() {
      _phase = _Phase.complete;
      _submitting = true;
    });

    final sessionDuration =
        DateTime.now().difference(_sessionStart).inSeconds.toDouble();
    final targetTime =
      (_targetSeconds[widget.variant] ?? 60) * _activeTotalRounds.toDouble();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('student_id') ?? 'student_001';

    try {
      await GamesApiService.evaluateSession(
        userId: userId,
        domain: 'length',
        attempts: (_totalAttempts / _activeTotalRounds).round(),
        time: sessionDuration,
        targetTime: targetTime,
        hints: _totalHints,
      );
    } catch (_) {}

    // If player passed, save the unlocked variant locally so the hub
    // reflects it immediately even before the backend response refreshes.
    final maxStars = _activeTotalRounds * 3;
    final percent  = (_totalStarsEarned / maxStars * 100).round();
    if (percent >= _passPercent) {
      final next = _nextVariantCode;
      if (next != null) {
        await prefs.setString('length_unlocked_variant', next);
      }
    }

    if (mounted) setState(() => _submitting = false);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _phase == _Phase.complete
                      ? _buildCompleteScreen()
                      : _buildGameArea(),
                ),
              ],
            ),

            // Wrong answer shake overlay message
            if (_phase == _Phase.wrongAnswer)
              Positioned(
                bottom: 100,
                left: 24,
                right: 24,
                child: AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) {
                    final dx = sin(_shakeAnim.value * pi * 8) * 8;
                    return Transform.translate(offset: Offset(dx, 0), child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: KidsColors.error,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: KidsColors.error.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('❌', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(_resultMessage,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Correct answer banner
            if (_phase == _Phase.showResult)
              Positioned.fill(
                child: _buildResultOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  // ─── top bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final targetSec = _targetSeconds[widget.variant] ?? 60;
    final timerColor =
        _elapsedSeconds > targetSec * 0.8 ? KidsColors.error : KidsColors.lengthColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.close_rounded, color: KidsColors.textSecondary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_variantTitle,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: KidsColors.textPrimary)),
                    Text('Round $_round of $_activeTotalRounds',
                        style: const TextStyle(
                            fontSize: 12,
                            color: KidsColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: timerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded, color: timerColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_elapsedSeconds}s',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: timerColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Hint button
              GestureDetector(
                onTap: _useHint,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        if (_hintsUsedThisRound > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                  color: KidsColors.error, shape: BoxShape.circle),
                              child: Center(
                                child: Text('$_hintsUsedThisRound',
                                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Round progress dots + IRT difficulty indicator
          Row(
            children: [
              ...List.generate(_activeTotalRounds, (i) {
                Color dotColor;
                if (i + 1 < _round) {
                  dotColor = KidsColors.success;
                } else if (i + 1 == _round) {
                  dotColor = KidsColors.lengthColor;
                } else {
                  dotColor = const Color(0xFFE0E0E0);
                }
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
              if (widget.variant == 'L-V4') ...[
                const SizedBox(width: 8),
                _buildIRTBadge(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String get _variantTitle {
    switch (widget.variant) {
      case 'L-V1':
        return '📏 Ruler Explorer';
      case 'L-V4':
        return '🌉 Build a Bridge';
      default:
        return '📏 Length Game';
    }
  }

  // ─── IRT difficulty badge ─────────────────────────────────────────────────

  Widget _buildIRTBadge() {
    final labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];
    final idx = (_irtDifficultyLevel - 1).clamp(0, 4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors[idx].withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors[idx].withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, size: 12, color: colors[idx]),
          const SizedBox(width: 3),
          Text(
            'Lv${_irtDifficultyLevel} ${labels[idx]}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors[idx],
            ),
          ),
        ],
      ),
    );
  }

  // ─── game area router ─────────────────────────────────────────────────────

  Widget _buildGameArea() {
    switch (widget.variant) {
      case 'L-V1':
        return _buildV1();
      case 'L-V4':
        return _buildV4();
      default:
        return const Center(child: Text('Unknown variant'));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // L-V1: AR Camera Measurement
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildV1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instruction card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF3DBDB3)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ECDC4).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '📱',
                  style: TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 16),
                Text(
                  _v1MeasuredCm == null
                      ? 'Measure a Real Object!'
                      : 'Pick the Closest Answer!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _v1MeasuredCm == null
                      ? 'Use your camera to measure something around you.\nIt could be a book, pencil, or anything!'
                      : 'You measured ${_v1MeasuredCm!.toStringAsFixed(1)} cm.\nWhich answer is closest?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // AR measurement button or result
          if (_v1MeasuredCm == null)
            _buildARLaunchButton()
          else
            _buildMeasurementResult(),

          // Answer choices (only after measurement)
          if (_v1MeasuredCm != null && _v1Choices.isNotEmpty) ...[  
            const SizedBox(height: 28),
            const Text(
              'Pick the closest answer:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: KidsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.2,
              children: _v1Choices
                  .map((c) => _choiceBtn('$c cm', () => _submitV1(c)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildARLaunchButton() {
    return GestureDetector(
      onTap: _launchARMeasurement,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF4ECDC4),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ECDC4).withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 50,
                color: Color(0xFF4ECDC4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Open Camera',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4ECDC4),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to start measuring!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: KidsColors.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementResult() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4ECDC4),
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Measurement Complete!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4ECDC4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF3DBDB3)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_v1MeasuredCm!.toStringAsFixed(1)} cm',
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _launchARMeasurement,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 20,
            ),
            label: const Text(
              'Measure Again',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4ECDC4),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchARMeasurement() async {
    final result = await Get.to<String>(
      () => const ARLengthMeasureScreen(),
      transition: Transition.fadeIn,
    );

    if (result != null && mounted) {
      final measuredCm = double.tryParse(result);
      if (measuredCm != null && measuredCm > 0) {
        _generateChoicesFromMeasurement(measuredCm);
      }
    }
  }

  void _generateChoicesFromMeasurement(double measuredCm) {
    final rounded = measuredCm.round();
    final choiceSpread = (_params['choice_spread'] as num?)?.toInt() ?? 3;

    // Generate decoys around the measured value
    final decoys = <int>{};
    while (decoys.length < 3) {
      final offset = (_rng.nextInt(choiceSpread * 2) + 1) * (_rng.nextBool() ? 1 : -1);
      final decoy = (rounded + offset).clamp(1, 100);
      if (decoy != rounded && !decoys.contains(decoy)) {
        decoys.add(decoy);
      }
    }

    final choices = [rounded, ...decoys]..shuffle(_rng);

    setState(() {
      _v1MeasuredCm = measuredCm;
      _v1Choices = choices;
      _v1Correct = rounded;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // L-V4: Build a Bridge
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildV4() {
    return LayoutBuilder(builder: (context, constraints) {
      final availW = constraints.maxWidth;
      final placedTotal = _v4PlacedOrder.fold(0, (s, i) => s + _v4Strips[i]);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          children: [
            // Bridge scene (river + banks + draggable planks)
            _buildBridgeScene(availW, placedTotal),
            const SizedBox(height: 18),
            // Strip plank bank
            _buildStripBank(availW),
            const SizedBox(height: 16),
            // Progress indicator
            _buildBridgeProgress(placedTotal),
            const SizedBox(height: 20),
            _bigPlayBtn(
              _v4PlacedOrder.isEmpty
                  ? 'Place planks on the bridge! 🪵'
                  : 'Check my bridge! 🌉',
              _v4PlacedOrder.isEmpty
                  ? KidsColors.textTertiary
                  : const Color(0xFF9C27B0),
              _v4PlacedOrder.isEmpty ? () {} : _submitV4,
            ),
          ],
        ),
      );
    });
  }

  // ── Bridge scene ─────────────────────────────────────────────────────────

  static const double _kSceneH  = 200.0;
  static const double _kCliffW  = 48.0;
  static const double _kBridgeY = 90.0;
  static const double _kBridgeH = 32.0;
  static const double _kWaterY  = 130.0;

  Color _v4StripColor(int idx) {
    const cols = [
      Color(0xFF8D6E63), // brown wood tones
      Color(0xFFA1887F),
      Color(0xFF795548),
      Color(0xFF6D4C41),
      Color(0xFF5D4037),
      Color(0xFFBCAAA4),
    ];
    return cols[idx % cols.length];
  }

  Widget _buildBridgeScene(double availW, int placedTotal) {
    final gapW = availW - _kCliffW * 2;

    // Compute pixel widths of each placed plank
    final placedPxW = _v4PlacedOrder.map((i) {
      return (_v4Strips[i] / _v4Target) * gapW;
    }).toList();
    final filledPx = placedPxW.fold(0.0, (s, w) => s + w);
    final bridgeComplete = placedTotal == _v4Target;

    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        final idx = details.data;
        if (!_v4Selected.contains(idx)) {
          setState(() {
            _v4Selected.add(idx);
            _v4PlacedOrder.add(idx);
          });
        }
      },
      builder: (context, candidates, _) {
        final isHovered = candidates.isNotEmpty;
        return Container(
          width: availW,
          height: _kSceneH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: isHovered
                ? Border.all(color: const Color(0xFF9C27B0), width: 3)
                : null,
            boxShadow: KidsShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // ── Sky gradient ────────────────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF87CEEB), Color(0xFFB0E0E6)],
                      ),
                    ),
                  ),
                ),
                // ── Sun ─────────────────────────────────────────────
                Positioned(
                  top: 12,
                  right: 20,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD54F),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Clouds ──────────────────────────────────────────
                const Positioned(
                  top: 18,
                  left: 30,
                  child: Text('☁️', style: TextStyle(fontSize: 20)),
                ),
                const Positioned(
                  top: 8,
                  left: 90,
                  child: Text('☁️', style: TextStyle(fontSize: 14)),
                ),
                // ── Water/River ─────────────────────────────────────
                Positioned(
                  left: _kCliffW,
                  top: _kWaterY,
                  width: gapW,
                  height: _kSceneH - _kWaterY,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Wave lines
                        ...List.generate(3, (i) => Positioned(
                          top: 8.0 + i * 18,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              '~ ~ ~ ~ ~ ~',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.5),
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        )),
                        // Fish
                        const Positioned(
                          bottom: 12,
                          left: 20,
                          child: Text('🐟', style: TextStyle(fontSize: 14)),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 30,
                          child: Transform.flip(
                            flipX: true,
                            child: const Text('🐟', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Left cliff ──────────────────────────────────────
                Positioned(
                  left: 0,
                  top: 50,
                  width: _kCliffW,
                  height: _kSceneH - 50,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Ground texture
                        ...List.generate(4, (i) => Positioned(
                          top: 20.0 + i * 25,
                          left: 8,
                          child: Container(
                            width: 30,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.green.shade800.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
                        // Character waiting
                        const Positioned(
                          top: 8,
                          left: 8,
                          child: Text('🐻', style: TextStyle(fontSize: 26)),
                        ),
                        // Grass
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Text('🌿', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Right cliff ─────────────────────────────────────
                Positioned(
                  right: 0,
                  top: 50,
                  width: _kCliffW,
                  height: _kSceneH - 50,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Ground texture
                        ...List.generate(4, (i) => Positioned(
                          top: 20.0 + i * 25,
                          right: 8,
                          child: Container(
                            width: 30,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.green.shade800.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
                        // Honey pot goal
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Text('🍯', style: TextStyle(fontSize: 22)),
                        ),
                        // Grass
                        const Positioned(
                          top: 0,
                          left: 0,
                          child: Text('🌿', style: TextStyle(fontSize: 12)),
                        ),
                        // Tree
                        const Positioned(
                          bottom: 20,
                          right: 4,
                          child: Text('🌲', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Bridge supports (vertical posts) ────────────────
                Positioned(
                  left: _kCliffW - 6,
                  top: _kBridgeY,
                  child: Container(
                    width: 8,
                    height: _kWaterY - _kBridgeY + 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  right: _kCliffW - 6,
                  top: _kBridgeY,
                  child: Container(
                    width: 8,
                    height: _kWaterY - _kBridgeY + 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── Bridge gap outline ──────────────────────────────
                Positioned(
                  left: _kCliffW,
                  top: _kBridgeY,
                  width: gapW,
                  height: _kBridgeH,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100.withOpacity(0.3),
                      border: Border.all(
                        color: const Color(0xFF8D6E63).withOpacity(0.5),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: filledPx == 0
                        ? Center(
                            child: Text(
                              'Place planks here →',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5D4037).withOpacity(0.6),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                // ── Placed planks ───────────────────────────────────
                Positioned(
                  left: _kCliffW,
                  top: _kBridgeY,
                  child: Row(
                    children: [
                      for (int pi = 0; pi < _v4PlacedOrder.length; pi++)
                        GestureDetector(
                          onTap: () {
                            final idx = _v4PlacedOrder[pi];
                            setState(() {
                              _v4PlacedOrder.removeAt(pi);
                              _v4Selected.remove(idx);
                            });
                          },
                          child: Container(
                            width: placedPxW[pi].clamp(12.0, gapW),
                            height: _kBridgeH,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _v4StripColor(_v4PlacedOrder[pi]),
                                  _v4StripColor(_v4PlacedOrder[pi])
                                      .withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Wood grain lines
                                ...List.generate(
                                  (placedPxW[pi] / 10).floor().clamp(1, 15),
                                  (k) => Positioned(
                                    left: 4.0 + k * 10,
                                    top: 4,
                                    bottom: 4,
                                    child: Container(
                                      width: 1,
                                      color: Colors.black.withOpacity(0.12),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: FittedBox(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: Text(
                                        '${_v4Strips[_v4PlacedOrder[pi]]}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.brown.shade900,
                                          shadows: [
                                            Shadow(
                                              color: Colors.white.withOpacity(0.5),
                                              blurRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // ── Target label chip ───────────────────────────────
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: bridgeComplete 
                              ? KidsColors.success 
                              : const Color(0xFF8D6E63),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bridgeComplete ? '✅' : '🌉',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Bridge: $_v4Target cm',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: bridgeComplete 
                                  ? KidsColors.success 
                                  : const Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Tap-to-remove hint ──────────────────────────────
                if (_v4PlacedOrder.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    left: _kCliffW + 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'tap to remove',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Strip bank ───────────────────────────────────────────────────────────

  Widget _buildStripBank(double availW) {
    const maxRef = 25.0;
    final maxBarW = (availW - 48).clamp(120.0, 340.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: KidsShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🪵 Plank pieces — drag onto bridge or tap',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: KidsColors.textSecondary)),
          const SizedBox(height: 14),
          Column(
            children: List.generate(_v4Strips.length, (i) {
              final cm = _v4Strips[i];
              final placed = _v4Selected.contains(i);
              final barW =
                  ((cm / maxRef) * maxBarW).clamp(40.0, maxBarW);
              final color = _v4StripColor(i);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Draggable<int>(
                  data: i,
                  maxSimultaneousDrags: placed ? 0 : 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.85,
                      child:
                          _buildPlankBar(cm, barW, color, placed: false),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildPlankBar(cm, barW, color, placed: true),
                  ),
                  child: GestureDetector(
                    onTap: placed
                        ? () {
                            setState(() {
                              _v4Selected.remove(i);
                              _v4PlacedOrder.remove(i);
                            });
                          }
                        : () {
                            setState(() {
                              _v4Selected.add(i);
                              _v4PlacedOrder.add(i);
                            });
                          },
                    child: _buildPlankBar(cm, barW, color, placed: placed),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPlankBar(int cm, double barW, Color color,
      {required bool placed}) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: barW,
          height: 44,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: placed ? color.withOpacity(0.28) : color,
            borderRadius: BorderRadius.circular(10),
            border: placed ? Border.all(color: color, width: 2) : null,
            boxShadow: placed
                ? []
                : [
                    BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 3))
                  ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$cm cm',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: placed ? color : Colors.white,
                  ),
                ),
              ),
              if (placed && barW > 60)
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 6),
                  child: Icon(Icons.check_circle, color: color, size: 16),
                )
              else
                const SizedBox(width: 6),
            ],
          ),
        ),
        // Wood grain decoration
        ...List.generate(
          (barW / 14).floor().clamp(0, 10),
          (k) => Positioned(
            left: 12.0 + k * 14,
            top: 10,
            height: 24,
            child: Container(
              width: 1,
              color: placed
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.28),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bridge progress ──────────────────────────────────────────────────────

  Widget _buildBridgeProgress(int placedTotal) {
    final progress =
        _v4Target > 0 ? (placedTotal / _v4Target).clamp(0.0, 1.0) : 0.0;
    final over = placedTotal > _v4Target;
    final exact = placedTotal == _v4Target;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: KidsShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bridge filled:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KidsColors.textSecondary)),
              Text(
                '$placedTotal / $_v4Target cm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: over
                      ? KidsColors.error
                      : exact
                          ? KidsColors.success
                          : KidsColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(
                over
                    ? KidsColors.error
                    : exact
                        ? KidsColors.success
                        : const Color(0xFF9C27B0),
              ),
            ),
          ),
          if (_v4PlacedOrder.isNotEmpty && !exact) ...[
            const SizedBox(height: 8),
            Text(
              over
                  ? '${placedTotal - _v4Target} cm too long! Remove a plank.'
                  : '${_v4Target - placedTotal} cm more needed!',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: over ? KidsColors.error : const Color(0xFF7B1FA2)),
            ),
          ] else if (exact) ...[
            const SizedBox(height: 8),
            const Text('🎉 Perfect fit! Hit the bridge button!',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KidsColors.success)),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESULT OVERLAY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildResultOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                  color: KidsColors.success.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(_resultMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: KidsColors.textPrimary)),
              const SizedBox(height: 20),
              // Stars earned this round
              ScaleTransition(
                scale: _starAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        i < _roundStars ? '⭐' : '☆',
                        style: TextStyle(
                          fontSize: 40,
                          color: i < _roundStars ? KidsColors.starGold : const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _nextRound,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [KidsColors.success, Color(0xFF28A745)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: KidsColors.success.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    _round < _activeTotalRounds ? '➡️ Next Round!' : '🏁 Finish!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPLETE SCREEN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCompleteScreen() {
    final maxStars = _activeTotalRounds * 3;
    final percent = (_totalStarsEarned / maxStars * 100).round();
    String medal;
    String praise;
    if (percent >= 90) {
      medal = '🥇';
      praise = 'You\'re a Measurement Master!';
    } else if (percent >= 70) {
      medal = '🥈';
      praise = 'Amazing work! Keep it up!';
    } else if (percent >= 50) {
      medal = '🥉';
      praise = 'Good job! Practice makes perfect!';
    } else {
      medal = '🌟';
      praise = 'Great try! Play again to improve!';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        children: [
          // Medal
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -_bounceAnim.value),
              child: Text(medal, style: const TextStyle(fontSize: 80)),
            ),
          ),
          const SizedBox(height: 20),
          Text(praise,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: KidsColors.textPrimary)),
          const SizedBox(height: 8),
          Text('You finished all $_activeTotalRounds rounds!',
              style: const TextStyle(
                  fontSize: 17, color: KidsColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 28),
          // Star summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: KidsShadows.soft,
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: List.generate(
                    min(_totalStarsEarned, 15),
                    (_) => const Text('⭐', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('$_totalStarsEarned / $maxStars stars',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: KidsColors.textPrimary)),
                const SizedBox(height: 4),
                Text('$percent% accuracy!',
                    style: const TextStyle(
                        fontSize: 16,
                        color: KidsColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                if (_submitting) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: const [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: KidsColors.lengthColor)),
                      Text('Saving your progress...',
                          style: TextStyle(fontSize: 13, color: KidsColors.textTertiary)),
                    ],
                  ),
                ],
                // IRT adaptive info (L-V4 only)
                if (widget.variant == 'L-V4') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text('🧠 Adaptive Learning',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6A1B9A))),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _irtStatChip('Level', '$_irtDifficultyLevel/5', const Color(0xFF9C27B0)),
                            _irtStatChip('Ability', _irtTheta.toStringAsFixed(2), const Color(0xFF2196F3)),
                            _irtStatChip('Rounds', '$_irtRoundsPlayed', const Color(0xFF4CAF50)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── primary action: unlock next level OR play again ─────────────
          Builder(builder: (_) {
            final maxStars = _activeTotalRounds * 3;
            final percent  = (_totalStarsEarned / maxStars * 100).round();
            final passed   = percent >= _passPercent;
            final next     = _nextVariantCode;

            if (passed && next != null) {
              // ── PASSED: show next-level unlock button ───────────────────
              return Column(
                children: [
                  // Unlock banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: KidsColors.success, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔓', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text(
                          'Next level unlocked!',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: KidsColors.successDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Go to next level
                  GestureDetector(
                    onTap: () {
                      final target = next!; // non-null inside this branch
                      Get.off<void>(
                        () => LengthGamePlayScreen(variant: target),
                        preventDuplicates: false,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [KidsColors.success, Color(0xFF28A745)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: KidsColors.success.withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        '🚀 Play Next Level!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else if (passed && next == null) {
              // ── ALL LEVELS COMPLETE ──────────────────────────────────────
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    ),
                    child: const Text(
                      '🏆 All Levels Complete! You are amazing!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF57F17),
                      ),
                    ),
                  ),
                  // Play again even after passing
                  _bigPlayBtn('🔄 Play Again!', KidsColors.lengthColor, () {
                    setState(() {
                      _round            = 1;
                      _phase            = _Phase.playing;
                      _totalStarsEarned = 0;
                      _totalAttempts    = 0;
                      _totalHints       = 0;
                      _sessionStart     = DateTime.now();
                    });
                    _generateRound();
                    _startTimer();
                  }),
                ],
              );
            } else {
              // ── NOT PASSED: show play again ──────────────────────────────
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: KidsColors.highlightAccent, width: 2),
                    ),
                    child: const Text(
                      'Need 60% or more to unlock the next level — try again! 💪',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: KidsColors.textSecondary,
                      ),
                    ),
                  ),
                  _bigPlayBtn('🔄 Play Again!', KidsColors.lengthColor, () {
                    setState(() {
                      _round            = 1;
                      _phase            = _Phase.playing;
                      _totalStarsEarned = 0;
                      _totalAttempts    = 0;
                      _totalHints       = 0;
                      _sessionStart     = DateTime.now();
                    });
                    _generateRound();
                    _startTimer();
                  }),
                ],
              );
            }
          }),

          const SizedBox(height: 14),
          // Go back
          Material(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Get.back(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text('← Back to Games',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: KidsColors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _choiceBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KidsColors.lengthColor, width: 2),
          boxShadow: [
            BoxShadow(
                color: KidsColors.lengthColor.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: KidsColors.lengthColor)),
        ),
      ),
    );
  }

  Widget _bigPlayBtn(String label, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withOpacity(0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
      ),
    );
  }

  Widget _irtStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KidsColors.textTertiary)),
      ],
    );
  }

}
