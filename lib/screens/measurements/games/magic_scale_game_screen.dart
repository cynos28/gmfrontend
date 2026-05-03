/// Magic Scale Game — Balance beam weight game for kindergarten kids
/// Mode 1: Match the Target — drag weights to match a given number on left pan
/// Mode 2: Equal Sides    — balance the right pan against fixed left weights

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';
import 'package:ganithamithura/utils/kids_theme.dart';

// ─── Weight Definition ───────────────────────────────────────────────────────

class _WeightItem {
  final int grams;
  final Color color;
  final String emoji;
  final String label;

  const _WeightItem({
    required this.grams,
    required this.color,
    required this.emoji,
    required this.label,
  });
}

const _allWeights = [
  _WeightItem(grams: 10,  color: Color(0xFFE53935), emoji: '🐞', label: '10g'),
  _WeightItem(grams: 50,  color: Color(0xFFFFA000), emoji: '🐥', label: '50g'),
  _WeightItem(grams: 100, color: Color(0xFF1E88E5), emoji: '🐘', label: '100g'),
  _WeightItem(grams: 200, color: Color(0xFF8E24AA), emoji: '🐳', label: '200g'),
  _WeightItem(grams: 500, color: Color(0xFF43A047), emoji: '🐢', label: '500g'),
];

enum GameMode { matchTarget, equalSides }

// ─────────────────────────────────────────────────────────────────────────────

class MagicScaleGameScreen extends StatefulWidget {
  final GameMode mode;
  const MagicScaleGameScreen({super.key, required this.mode});

  @override
  State<MagicScaleGameScreen> createState() => _MagicScaleGameScreenState();
}

class _MagicScaleGameScreenState extends State<MagicScaleGameScreen>
    with TickerProviderStateMixin {

  // ─── IRT State ─────────────────────────────────────────────────────────────
  String _studentId        = 'student_001';
  double _theta            = 0.0;
  int _irtDifficultyLevel  = 1;
  int _irtRoundsPlayed     = 0;
  Map<String, dynamic> _irtParams = {};
  bool _irtLoading         = true;

  // ─── Game State ────────────────────────────────────────────────────────────
  int _hintsUsed     = 0;
  int _attempts      = 0;
  int _questionNumber = 1;
  int _totalCorrect  = 0;
  static const _maxQuestions = 5;
  bool _showFinishScreen = false;

  // ─── Question state ─────────────────────────────────────────────────────────
  int _targetGrams = 0;
  List<int> _leftPanGrams  = []; // player fills this in matchTarget
  List<int> _rightPanGrams = []; // player fills this in equalSides
  List<int> _fixedLeftGrams = []; // pre-placed (equalSides)
  List<_WeightItem> _trayWeights = [];

  // ─── UI state ───────────────────────────────────────────────────────────────
  bool _showFeedback = false;
  bool _isCorrect    = false;
  bool _showHint     = false;
  String _owlMood    = '😊'; // idle

  // ─── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _tiltController;
  late Animation<double>   _tiltAnimation;   // radians
  double _tiltTarget = 0.0;

  late AnimationController _bounceController;
  late Animation<double>   _bounceAnimation;

  late AnimationController _celebrationController;

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _tiltController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _tiltAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.elasticOut));

    _bounceController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _bounceController.reverse();
      });

    _celebrationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

    _fetchIRTState();
  }

  @override
  void dispose() {
    _tiltController.dispose();
    _bounceController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  // ─── IRT helpers ──────────────────────────────────────────────────────────

  Future<void> _fetchIRTState() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString('student_id') ?? 'student_001';
    final variant = widget.mode == GameMode.matchTarget ? 'W-W1' : 'W-W2';

    final state = await GamesApiService.getIRTState(
      studentId: _studentId,
      domain: 'weight',
      variant: variant,
    );

    if (mounted) {
      setState(() {
        _theta             = (state['theta'] as num?)?.toDouble() ?? 0.0;
        _irtDifficultyLevel = (state['difficulty_level'] as int?) ?? 1;
        _irtRoundsPlayed   = (state['rounds_played'] as int?) ?? 0;
        _irtParams         = (state['next_params'] as Map<String, dynamic>?) ?? {};
        _irtLoading        = false;
      });
      _generateQuestion();
    }
  }

  Future<void> _submitRoundToIRT() async {
    final variant = widget.mode == GameMode.matchTarget ? 'W-W1' : 'W-W2';
    final result = await GamesApiService.submitRoundResult(
      studentId: _studentId,
      domain: 'weight',
      variant: variant,
      correct: _isCorrect,
      attempts: _attempts,
      hintsUsed: _hintsUsed,
      timeSeconds: 0,
      starsEarned: _isCorrect ? 1 : 0,
    );
    if (mounted) {
      setState(() {
        _theta              = (result['theta'] as num?)?.toDouble() ?? _theta;
        _irtDifficultyLevel = (result['difficulty_level'] as int?) ?? _irtDifficultyLevel;
        _irtRoundsPlayed    = (result['rounds_played'] as int?) ?? _irtRoundsPlayed;
        _irtParams          = (result['next_params'] as Map<String, dynamic>?) ?? _irtParams;
      });
    }
  }

  List<_WeightItem> _weightsForDifficulty() {
    final gramList = (_irtParams['available_weight_grams'] as List<dynamic>?)
        ?.map((e) => (e as num).toInt()).toList()
        ?? _defaultGramsForLevel(_irtDifficultyLevel);
    return _allWeights.where((w) => gramList.contains(w.grams)).toList();
  }

  List<int> _defaultGramsForLevel(int level) {
    switch (level) {
      case 1:  return [10, 50];
      case 2:  return [10, 50, 100];
      case 3:  return [10, 50, 100, 200];
      case 4:  return [10, 50, 100, 200, 500];
      case 5:  return [10, 50, 100, 200, 500];
      default: return [10, 50, 100];
    }
  }

  int _maxTarget() {
    return (_irtParams['max_target_grams'] as int?) ?? _defaultMaxTarget(_irtDifficultyLevel);
  }

  int _defaultMaxTarget(int level) {
    switch (level) {
      case 1:  return 100;
      case 2:  return 200;
      case 3:  return 350;
      case 4:  return 500;
      case 5:  return 700;
      default: return 200;
    }
  }

  int _maxPieces() {
    return (_irtParams['max_pieces'] as int?) ?? (2 + _irtDifficultyLevel.clamp(1, 5) - 1);
  }

  bool _hintsAllowed() {
    final h = (_irtParams['hints'] as int?) ?? (3 - (_irtDifficultyLevel - 1).clamp(0, 2));
    return h > 0;
  }

  // ─── IRT badge ────────────────────────────────────────────────────────────

  Widget _buildIRTBadge() {
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    const colors = [
      Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
      Color(0xFFE91E63), Color(0xFF9C27B0),
    ];
    final idx = (_irtDifficultyLevel - 1).clamp(0, 4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[idx].withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors[idx].withOpacity(0.5), width: 1),
      ),
      child: Text(
        labels[idx],
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: colors[idx],
        ),
      ),
    );
  }

  Color _getIRTColor() {
    const colors = [
      Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
      Color(0xFFE91E63), Color(0xFF9C27B0),
    ];
    return colors[(_irtDifficultyLevel - 1).clamp(0, 4)];
  }

  String _getIRTLabel() {
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    return labels[(_irtDifficultyLevel - 1).clamp(0, 4)];
  }

  // ─── Question generation ─────────────────────────────────────────────────────

  void _generateQuestion() {
    final rng = math.Random();
    final weights = _weightsForDifficulty();
    final maxT   = _maxTarget();

    // Build a reachable target by summing random weight picks
    int target = 0;
    final used = <int>[];
    final maxPieces = _maxPieces();
    for (int i = 0; i < maxPieces; i++) {
      final w = weights[rng.nextInt(weights.length)].grams;
      if (target + w <= maxT) { target += w; used.add(w); }
    }
    if (target == 0) { target = weights[0].grams; used.add(target); }

    setState(() {
      _targetGrams    = target;
      _leftPanGrams   = [];
      _rightPanGrams  = [];
      _fixedLeftGrams = widget.mode == GameMode.equalSides ? List.of(used) : [];
      _trayWeights    = List.of(weights);
      _showFeedback   = false;
      _isCorrect      = false;
      _showHint       = false;
      _hintsUsed      = 0;
      _attempts       = 0;
      _owlMood        = '😊';
    });
    _animateTilt();
  }

  // ─── Weight interactions ─────────────────────────────────────────────────────

  void _addWeight(int grams, {bool toRight = false}) {
    if (_showFeedback) return;
    setState(() {
      if (toRight) {
        _rightPanGrams.add(grams);
      } else {
        _leftPanGrams.add(grams);
      }
    });
    _bounceController.forward(from: 0);
    _animateTilt();
    _checkBalance();
  }

  void _removeFromPan(int index, {bool fromRight = false}) {
    if (_showFeedback) return;
    setState(() {
      if (fromRight) {
        _rightPanGrams.removeAt(index);
      } else {
        _leftPanGrams.removeAt(index);
      }
    });
    _animateTilt();
  }

  void _animateTilt() {
    final left  = _leftWeight  + _fixedLeftGrams.fold(0, (a, b) => a + b);
    final right = _rightWeight;
    final maxDiff = math.max(_maxTarget(), 1);
    final newTilt = ((left - right) / maxDiff * (30 * math.pi / 180))
        .clamp(-30 * math.pi / 180, 30 * math.pi / 180)
        .toDouble();
    _tiltAnimation = Tween<double>(begin: _tiltAnimation.value, end: newTilt)
        .animate(CurvedAnimation(parent: _tiltController, curve: Curves.elasticOut));
    _tiltController.forward(from: 0);

    // Owl mood
    final diff = (left - right).abs();
    if (diff == 0 && (left > 0 || right > 0)) {
      setState(() => _owlMood = '🎉');
    } else if (diff > 200) {
      setState(() => _owlMood = '😅');
    } else {
      setState(() => _owlMood = '🤔');
    }
  }

  int get _leftWeight  => _leftPanGrams.fold(0, (a, b) => a + b);
  int get _rightWeight => _rightPanGrams.fold(0, (a, b) => a + b);

  // ─── Balance check ───────────────────────────────────────────────────────────

  void _checkBalance() {
    if (_showFeedback) return;
    final left  = _leftWeight  + _fixedLeftGrams.fold(0, (a, b) => a + b);
    final right = widget.mode == GameMode.matchTarget
        ? _leftWeight
        : _rightWeight;
    final target = widget.mode == GameMode.matchTarget ? _targetGrams : _targetGrams;

    bool correct = false;
    if (widget.mode == GameMode.matchTarget) {
      correct = _leftWeight == _targetGrams;
    } else {
      correct = _rightWeight == _targetGrams;
    }

    if (correct) {
      _attempts++;
      _totalCorrect++;
      setState(() {
        _showFeedback = true;
        _isCorrect    = true;
        _owlMood      = '🎉';
      });
      _celebrationController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 2200), () async {
        await _submitRoundToIRT();
        _nextQuestion();
      });
    }
  }

  void _trySubmit() {
    if (_showFeedback) return;
    _attempts++;
    final correct = widget.mode == GameMode.matchTarget
        ? _leftWeight == _targetGrams
        : _rightWeight == _targetGrams;

    if (!correct) {
      setState(() {
        _showFeedback = true;
        _isCorrect    = false;
        _owlMood      = '😕';
      });
      Future.delayed(const Duration(milliseconds: 1800), () async {
        await _submitRoundToIRT();
        if (mounted) setState(() { _showFeedback = false; _owlMood = '😊'; });
      });
    } else {
      _totalCorrect++;
      setState(() { _showFeedback = true; _isCorrect = true; _owlMood = '🎉'; });
      _celebrationController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 2200), () async {
        await _submitRoundToIRT();
        _nextQuestion();
      });
    }
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_questionNumber >= _maxQuestions) {
      setState(() => _showFinishScreen = true);
    } else {
      setState(() => _questionNumber++);
      _generateQuestion();
    }
  }

  void _showHintTap() {
    _hintsUsed++;
    setState(() => _showHint = true);
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showFinishScreen) return _buildFinishScreen();

    if (_irtLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8E1),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              CircularProgressIndicator(color: KidsColors.weightColor),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _questionNumber / _maxQuestions,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(KidsColors.weightColor),
              ),
            ),
          ),

          // Target badge / hint
          _buildTargetBadge(),

          // Scale
          Expanded(child: _buildScale()),

          // Tray
          _buildWeightTray(),

          const SizedBox(height: 8),

          // Check button
          _buildCheckRow(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: KidsColors.textPrimary),
        onPressed: () => Get.back(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.mode == GameMode.matchTarget ? 'Match Target' : 'Equal Sides',
              style: const TextStyle(color: KidsColors.textPrimary, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          _buildIRTBadge(),
        ],
      ),
      actions: [
        // Owl guide
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Text(_owlMood, style: const TextStyle(fontSize: 32)),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: KidsColors.weightColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Q $_questionNumber/$_maxQuestions',
            style: TextStyle(
              color: KidsColors.weightColor,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Target badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFFFB300), const Color(0xFFFFA000)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎯', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Target: $_targetGrams g',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Hint button (allowed by IRT level)
          if (_hintsAllowed() && !_showHint)
            GestureDetector(
              onTap: _showHintTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: KidsColors.weightColor.withOpacity(0.4), width: 2),
                  boxShadow: KidsShadows.soft,
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text('Hint', style: TextStyle(fontWeight: FontWeight.w700, color: KidsColors.weightColor)),
                  ],
                ),
              ),
            ),

          // Hint display
          if (_showHint)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.4), width: 2),
              ),
              child: Text(
                _getHintText(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  String _getHintText() {
    final weights = _weightsForDifficulty();
    int remaining = _targetGrams;
    final parts = <String>[];
    for (final w in weights.reversed) {
      final count = remaining ~/ w.grams;
      if (count > 0) { parts.add('${count}×${w.label}'); remaining %= w.grams; }
    }
    return parts.isEmpty ? '$_targetGrams g' : parts.join(' + ');
  }

  // ─── Scale ───────────────────────────────────────────────────────────────────

  Widget _buildScale() {
    return AnimatedBuilder(
      animation: _tiltAnimation,
      builder: (context, _) {
        final tilt = _tiltAnimation.value;
        return LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final cx = w / 2;
          final beamHalf = w * 0.38;
          final panY = h * 0.22;

          // Pan positions after tilt
          final leftPanOffY  = math.sin(tilt)  * beamHalf;
          final rightPanOffY = -math.sin(tilt) * beamHalf;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Beam
              Positioned(
                top: h * 0.18,
                child: Transform.rotate(
                  angle: -tilt,
                  child: Container(
                    width: beamHalf * 2,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFBF8A3D), Color(0xFF8B5E3C)]),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 4)),
                      ],
                    ),
                  ),
                ),
              ),

              // Pivot (triangle)
              Positioned(
                top: h * 0.18 - 28,
                child: CustomPaint(
                  size: const Size(40, 50),
                  painter: _PivotPainter(),
                ),
              ),
              Positioned(
                top: h * 0.18 + 18,
                child: Container(
                  width: 60, height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5E3C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),

              // Left chain & pan
              Positioned(
                left: cx - beamHalf,
                top: h * 0.18 + leftPanOffY + 8,
                child: _buildPan(
                  isLeft: true,
                  weights: widget.mode == GameMode.equalSides
                      ? _fixedLeftGrams
                      : _leftPanGrams,
                  locked: widget.mode == GameMode.equalSides,
                  panHeight: panY,
                ),
              ),

              // Right chain & pan
              Positioned(
                right: cx - beamHalf,
                top: h * 0.18 + rightPanOffY + 8,
                child: _buildPan(
                  isLeft: false,
                  weights: widget.mode == GameMode.matchTarget
                      ? _rightPanGrams
                      : _rightPanGrams,
                  locked: false,
                  panHeight: panY,
                  isTarget: widget.mode == GameMode.matchTarget,
                ),
              ),

              // Left weight total badge
              if (_leftWeight + _fixedLeftGrams.fold(0, (a, b) => a + b) > 0)
                Positioned(
                  left: 24,
                  top: 20,
                  child: _weightBadge(
                    _leftWeight + _fixedLeftGrams.fold(0, (a, b) => a + b),
                    KidsColors.weightColor,
                  ),
                ),

              // Right weight total badge
              if ((widget.mode == GameMode.matchTarget ? _leftWeight : _rightWeight) > 0)
                Positioned(
                  right: 24,
                  top: 20,
                  child: _weightBadge(
                    widget.mode == GameMode.matchTarget ? _leftWeight : _rightWeight,
                    const Color(0xFF1E88E5),
                  ),
                ),

              // Success glow
              if (_isCorrect)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _celebrationController,
                      builder: (_, __) => CustomPaint(
                        painter: _ConfettiPainter(_celebrationController.value),
                      ),
                    ),
                  ),
                ),
            ],
          );
        });
      },
    );
  }

  Widget _weightBadge(int grams, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(
        '${grams}g',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }

  Widget _buildPan({
    required bool isLeft,
    required List<int> weights,
    required bool locked,
    required double panHeight,
    bool isTarget = false,
  }) {
    final total = weights.fold(0, (a, b) => a + b);
    // Make locked pan (Equal Sides reference) colorful and inviting
    final Color panColor = locked
        ? const Color(0xFFFFB74D) // Bright orange for locked/reference pan
        : (isTarget ? const Color(0xFF64B5F6) : KidsColors.weightColor.withOpacity(0.8));

    Widget panContent = DragTarget<int>(
      onAcceptWithDetails: (details) {
        if (widget.mode == GameMode.matchTarget && isLeft) {
          _addWeight(details.data);
        } else if (widget.mode == GameMode.equalSides && !isLeft) {
          _addWeight(details.data, toRight: true);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label for Equal Sides locked pan (reference side)
            if (locked && weights.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB74D).withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '👀 Match these! →',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Label for Equal Sides player pan (where to drag)
            if (!locked && !isTarget && widget.mode == GameMode.equalSides)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: KidsColors.weightColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: KidsColors.weightColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '← Drag here!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Chain
            Container(width: 3, height: 40, color: const Color(0xFF8B5E3C)),
            // Pan
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              constraints: const BoxConstraints(minHeight: 60),
              decoration: BoxDecoration(
                color: isHovered ? panColor.withOpacity(0.9) : panColor.withOpacity(locked ? 0.85 : 0.7),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                border: Border.all(
                  color: locked ? Colors.white : (isHovered ? Colors.white : Colors.black26),
                  width: locked ? 3 : (isHovered ? 3 : 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: panColor.withOpacity(locked ? 0.5 : 0.3),
                    blurRadius: locked ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                  // Extra glow for locked pan
                  if (locked)
                    BoxShadow(
                      color: const Color(0xFFFFB74D).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isTarget && !locked && weights.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white70)),
                      ),
                    ...weights.asMap().entries.map((e) {
                      final w = _allWeights.firstWhere((ww) => ww.grams == e.value, orElse: () => _allWeights[0]);
                      return GestureDetector(
                        onTap: locked ? null : () {
                          if (isLeft && widget.mode == GameMode.matchTarget) {
                            _removeFromPan(e.key);
                          } else if (!isLeft && widget.mode == GameMode.equalSides) {
                            _removeFromPan(e.key, fromRight: true);
                          }
                        },
                        child: Container(
                          height: 28,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            gradient: locked
                                ? LinearGradient(
                                    colors: [w.color, w.color.withOpacity(0.8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: locked ? null : w.color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white,
                              width: locked ? 2.5 : 2,
                            ),
                            boxShadow: locked
                                ? [
                                    BoxShadow(
                                      color: w.color.withOpacity(0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                w.emoji,
                                style: TextStyle(fontSize: locked ? 14 : 12),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                w.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: locked ? 12 : 11,
                                  shadows: locked
                                      ? [
                                          const Shadow(
                                            color: Colors.black26,
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Add "Tap to remove" hint for player's pan
                    if (!locked && weights.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Tap to remove',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    return panContent;
  }

  // ─── Weight Tray ─────────────────────────────────────────────────────────────

  Widget _buildWeightTray() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KidsColors.weightColor.withOpacity(0.2), width: 2),
        boxShadow: KidsShadows.soft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _trayWeights.map((w) => _buildDraggableWeight(w)).toList(),
      ),
    );
  }

  Widget _buildDraggableWeight(_WeightItem w) {
    Widget chip = GestureDetector(
      // Tap to add (fallback for non-drag)
      onTap: () {
        if (widget.mode == GameMode.matchTarget) {
          _addWeight(w.grams);
        } else {
          _addWeight(w.grams, toRight: true);
        }
      },
      child: _weightChip(w),
    );

    return Draggable<int>(
      data: w.grams,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.15, child: _weightChip(w)),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: _weightChip(w)),
      child: chip,
    );
  }

  Widget _weightChip(_WeightItem w) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [w.color, w.color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: w.color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(w.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            w.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Check Row ───────────────────────────────────────────────────────────────

  Widget _buildCheckRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Clear button
          GestureDetector(
            onTap: () {
              setState(() {
                _leftPanGrams.clear();
                _rightPanGrams.clear();
                _showFeedback = false;
                _owlMood = '😊';
              });
              _animateTilt();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
                boxShadow: KidsShadows.soft,
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 28),
            ),
          ),

          const SizedBox(width: 16),

          // Check button
          Expanded(
            child: GestureDetector(
              onTap: _trySubmit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _showFeedback && _isCorrect
                        ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                        : [KidsColors.weightColor, KidsColors.weightColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: KidsColors.weightColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showFeedback && _isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.balance_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _showFeedback && _isCorrect ? '✅ Balanced!' : '⚖️ Check Balance!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Finish Screen ───────────────────────────────────────────────────────────

  Widget _buildFinishScreen() {
    final rate = _totalCorrect * 100 ~/ _maxQuestions;
    final stars = rate >= 80 ? 3 : (rate >= 60 ? 2 : 1);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: const Text('⚖️', style: TextStyle(fontSize: 80)),
              ),
              const SizedBox(height: 24),
              Text(
                rate >= 80 ? '🎉 Amazing Job!' : rate >= 60 ? '👍 Good Work!' : '💪 Keep Going!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: KidsColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                '$_totalCorrect out of $_maxQuestions correct',
                style: const TextStyle(fontSize: 18, color: KidsColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              // IRT skill level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _getIRTColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getIRTColor().withOpacity(0.3), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology_rounded, color: _getIRTColor(), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Skill Level: ${_getIRTLabel()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _getIRTColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFFFB300),
                    size: 52,
                  ),
                )),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _questionNumber = 1;
                          _totalCorrect = 0;
                          _showFinishScreen = false;
                        });
                        _generateQuestion();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KidsColors.weightColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: KidsColors.weightColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: KidsColors.weightColor.withOpacity(0.3), width: 2),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
}

// ─── Pivot Painter ───────────────────────────────────────────────────────────

class _PivotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFBF8A3D), Color(0xFF8B5E3C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Confetti Painter ────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final _rng = math.Random(42);

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final colors = [
      const Color(0xFFFFB300), const Color(0xFF4CAF50),
      const Color(0xFF1E88E5), const Color(0xFFE53935),
      const Color(0xFF8E24AA),
    ];
    for (int i = 0; i < 40; i++) {
      final color = colors[i % colors.length];
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height * progress;
      final r = 6 + _rng.nextDouble() * 8;
      canvas.drawCircle(
        Offset(x, y),
        r * (1 - progress * 0.5),
        Paint()..color = color.withOpacity((1 - progress).clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
