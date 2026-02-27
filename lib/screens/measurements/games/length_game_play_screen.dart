/// Length Game Play Screen
/// Renders all four length game variants (L-V1 → L-V4) with kids-friendly UI,
/// adaptive difficulty, star rating and backend submission when the session ends.

// ignore_for_file: use_key_in_widget_constructors, dangling_library_doc_comments

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _Obj {
  final String name;
  final String svg;  // asset path for the SVG illustration
  final int cm;      // real approximate length in centimetres
  final Color color;
  const _Obj(this.name, this.svg, this.cm, this.color);
}

// Real-world school objects with approximate cm lengths.
const List<_Obj> _objects = [
  _Obj('Pencil',     'assets/images/obj_pencil.svg',     17, Color(0xFFFFCA28)),
  _Obj('Glue Stick', 'assets/images/obj_glue_stick.svg', 10, Color(0xFFBA68C8)),
  _Obj('Crayon',     'assets/images/obj_crayon.svg',     12, Color(0xFFFF7043)),
  _Obj('Scissors',   'assets/images/obj_scissors.svg',   15, Color(0xFF66BB6A)),
  _Obj('Paperclip',  'assets/images/obj_paperclip.svg',   3, Color(0xFF42A5F5)),
  _Obj('Eraser',     'assets/images/obj_eraser.svg',      5, Color(0xFFFF80AB)),
  _Obj('Pen',        'assets/images/obj_pen.svg',        14, Color(0xFF29B6F6)),
  _Obj('Spoon',      'assets/images/obj_spoon.svg',      18, Color(0xFF78909C)),
];

const List<int> _combineStrips = [3, 5, 7, 10, 12, 15, 20, 25];

enum _Phase { playing, wrongAnswer, showResult, complete }

// Per-variant target times (seconds per round)
const Map<String, int> _targetSeconds = {
  'L-V1': 45,
  'L-V2': 60,
  'L-V3': 60,
  'L-V4': 90,
};

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LengthGamePlayScreen extends StatefulWidget {
  final String variant; // 'L-V1' | 'L-V2' | 'L-V3' | 'L-V4'
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
  // V1
  _Obj? _v1Object;
  List<int> _v1Choices = [];
  int _v1Correct = 0;
  // V1 drag
  Offset _v1DragOffset    = Offset.zero;
  bool   _v1Snapped       = false;
  bool   _v1IsDragging    = false;
  double _v1SnapThreshY   = 80.0; // computed per object in _genV1

  // V2
  _Obj? _v2ObjA;
  _Obj? _v2ObjB;
  String _v2Correct = 'A'; // 'A' | 'B'

  // V3
  _Obj? _v3Object;
  String _v3GivenUnit = 'mm'; // 'mm' or 'm'
  double _v3GivenValue = 0;   // measurement in given unit
  int _v3Correct = 0;         // answer in cm
  List<int> _v3Choices = [];

  // V4
  int _v4Target = 0;
  List<int> _v4Strips = [];
  Set<int> _v4Selected = {};
  List<int> _v4PlacedOrder = []; // placement order for visual bridge rendering

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
  static const List<String> _variantOrder = ['L-V1', 'L-V2', 'L-V3', 'L-V4'];

  String? get _nextVariantCode {
    final idx = _variantOrder.indexOf(widget.variant);
    if (idx < 0 || idx >= _variantOrder.length - 1) return null;
    return _variantOrder[idx + 1];
  }

  // ── L-V1 bench layout constants ─────────────────────────────────────────
  static const double _kBenchH        = 310.0;
  static const double _kRulerTopY     = 228.0; // ruler top Y inside bench
  static const double _kObjBarStartY  =  60.0; // initial bar top Y inside bench
  static const double _kObjVisualH    =  56.0; // emoji object visual height

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
    _params = await GamesApiService.getParameters('length');
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
      _v1DragOffset  = Offset.zero;
      _v1Snapped     = false;
      _v1IsDragging  = false;
      _v4Selected    = {};
      _v4PlacedOrder = [];
      _shakeCtrl.reset();
    });

    switch (widget.variant) {
      case 'L-V1':
        _genV1();
      case 'L-V2':
        _genV2();
      case 'L-V3':
        _genV3();
      case 'L-V4':
        _genV4();
    }
  }

  void _genV1() {
    // Get adaptive params from backend
    final sizeRange = (_params['object_size_range'] as List?)?.cast<num>() ?? [5, 15];
    final minSize = sizeRange[0].toInt();
    final maxSize = sizeRange[1].toInt();
    final choiceSpread = (_params['choice_spread'] as num?)?.toInt() ?? 3;

    // Filter objects within the adaptive size range
    final eligible = _objects.where((o) => o.cm >= minSize && o.cm <= maxSize).toList();
    if (eligible.isEmpty) {
      // Fallback to all objects if no match
      eligible.addAll(_objects);
    }

    final obj = eligible[_rng.nextInt(eligible.length)];
    final correct = obj.cm;

    // Generate decoys based on adaptive choice_spread
    final decoys = <int>{};
    while (decoys.length < 3) {
      final offset = (_rng.nextInt(choiceSpread) + 1) * (_rng.nextBool() ? 1 : -1);
      final decoy = (correct + offset).clamp(1, 30);
      if (decoy != correct) decoys.add(decoy);
    }
    final choices = [correct, ...decoys]..shuffle(_rng);

    // Compute snap threshold: how far down the user must drag
    // so the object bottom reaches the ruler top (-30 px buffer)
    final snapThresh = _kRulerTopY - _kObjBarStartY - _kObjVisualH - 30.0;

    setState(() {
      _v1Object       = obj;
      _v1Choices      = choices;
      _v1Correct      = correct;
      _v1SnapThreshY  = snapThresh;
    });
  }

  void _genV2() {
    // Get adaptive params from backend
    final sizeRange = (_params['object_size_range'] as List?)?.cast<num>() ?? [5, 20];
    final minSize = sizeRange[0].toInt();
    final maxSize = sizeRange[1].toInt();
    final minDiff = (_params['min_size_difference'] as num?)?.toInt() ?? 3;

    // Filter objects within size range
    final eligible = _objects.where((o) => o.cm >= minSize && o.cm <= maxSize).toList();
    if (eligible.isEmpty) eligible.addAll(_objects);

    final shuffled = List.of(eligible)..shuffle(_rng);
    
    // Find two objects with sufficient size difference
    _Obj objA = shuffled[0];
    _Obj objB = shuffled[1];
    
    // Ensure minimum size difference for adaptive difficulty
    for (int i = 2; i < shuffled.length; i++) {
      if ((objA.cm - objB.cm).abs() >= minDiff) break;
      objB = shuffled[i];
    }
    
    setState(() {
      _v2ObjA = objA;
      _v2ObjB = objB;
      _v2Correct = objA.cm > objB.cm ? 'A' : 'B';
    });
  }

  void _genV3() {
    // Get adaptive params from backend
    final allowDecimals = (_params['allow_decimals'] as bool?) ?? false;
    final mmRange = (_params['value_range_mm'] as List?)?.cast<num>() ?? [30, 150];
    final mRange = (_params['value_range_m'] as List?)?.cast<num>() ?? [0.05, 0.25];
    final choiceSpread = (_params['choice_spread'] as num?)?.toInt() ?? 3;

    final obj = _objects[_rng.nextInt(_objects.length)];
    final unit = _rng.nextBool() ? 'mm' : 'm';
    
    double givenValue;
    if (unit == 'mm') {
      // Use adaptive mm range
      if (allowDecimals) {
        givenValue = mmRange[0].toDouble() + 
                     _rng.nextDouble() * (mmRange[1].toDouble() - mmRange[0].toDouble());
      } else {
        // Round to nearest 10 for easier calculation
        final intVal = (mmRange[0].toInt() + 
                       _rng.nextInt(mmRange[1].toInt() - mmRange[0].toInt())) ~/ 10 * 10;
        givenValue = intVal.toDouble();
      }
    } else {
      // Use adaptive m range
      if (allowDecimals) {
        givenValue = mRange[0].toDouble() + 
                     _rng.nextDouble() * (mRange[1].toDouble() - mRange[0].toDouble());
      } else {
        // Round to 0.05 increments for easier calculation
        givenValue = ((mRange[0].toDouble() + 
                      _rng.nextDouble() * (mRange[1].toDouble() - mRange[0].toDouble())) / 0.05).round() * 0.05;
      }
    }
    
    final correct = (unit == 'mm' ? givenValue / 10 : givenValue * 100).round();
    
    // Generate decoys based on adaptive choice_spread
    final decoys = <int>{};
    while (decoys.length < 3) {
      final offset = (_rng.nextInt(choiceSpread) + 1) * (_rng.nextBool() ? 1 : -1);
      final d = (correct + offset).clamp(1, 50);
      if (d != correct) decoys.add(d);
    }
    final choices = [correct, ...decoys]..shuffle(_rng);
    
    setState(() {
      _v3Object    = obj;
      _v3GivenUnit  = unit;
      _v3GivenValue = givenValue;
      _v3Correct    = correct;
      _v3Choices    = choices;
    });
  }

  void _genV4() {
    // Get adaptive params from backend
    final bridgeRange = (_params['bridge_target_range'] as List?)?.cast<num>() ?? [10, 18];
    final plankSizesParam = (_params['plank_sizes'] as List?)?.cast<num>();
    final plankCount = (_params['plank_count'] as num?)?.toInt() ?? 7;

    // Convert plank sizes to int list
    final availablePlankSizes = plankSizesParam?.map((n) => n.toInt()).toList() 
        ?? [3, 4, 5, 6, 7, 8, 9];

    // Generate random target within adaptive range
    final target = bridgeRange[0].toInt() + 
                   _rng.nextInt(bridgeRange[1].toInt() - bridgeRange[0].toInt() + 1);

    // Find valid combinations (2-3 planks that sum to target)
    final validCombos = <List<int>>[];
    for (int i = 0; i < availablePlankSizes.length; i++) {
      for (int j = i; j < availablePlankSizes.length; j++) {
        final sum2 = availablePlankSizes[i] + availablePlankSizes[j];
        if (sum2 == target) {
          validCombos.add([availablePlankSizes[i], availablePlankSizes[j]]);
        }
        for (int k = j; k < availablePlankSizes.length; k++) {
          final sum3 = availablePlankSizes[i] + availablePlankSizes[j] + availablePlankSizes[k];
          if (sum3 == target) {
            validCombos.add([availablePlankSizes[i], availablePlankSizes[j], availablePlankSizes[k]]);
          }
        }
      }
    }

    List<int> solution;
    if (validCombos.isNotEmpty) {
      // Use a valid combination from available planks
      solution = validCombos[_rng.nextInt(validCombos.length)];
    } else {
      // Fallback: pick 2-3 planks (may not sum to target exactly)
      final shuffled = List.of(availablePlankSizes)..shuffle(_rng);
      solution = shuffled.take(2 + _rng.nextInt(2)).toList();
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

  // ─────────────────────────────────────────────────────────────────────────
  // ANSWER HANDLING
  // ─────────────────────────────────────────────────────────────────────────

  void _submitV1(int choice) {
    if (_phase != _Phase.playing) return;
    setState(() => _roundAttempts++);
    if (choice == _v1Correct) {
      _roundCorrect('🎉 Awesome! The ${_v1Object!.name} is $_v1Correct cm!');
    } else {
      _roundWrong('Oops! Try again 💪');
    }
  }

  void _submitV2(String choice) {
    if (_phase != _Phase.playing) return;
    setState(() => _roundAttempts++);
    if (choice == _v2Correct) {
      final longer = _v2Correct == 'A' ? _v2ObjA! : _v2ObjB!;
      _roundCorrect('🎉 Yes! The ${longer.name} is longer!');
    } else {
      _roundWrong('Look more carefully 👀');
    }
  }

  void _submitV3(int choice) {
    if (_phase != _Phase.playing) return;
    setState(() => _roundAttempts++);
    if (choice == _v3Correct) {
      final disp = _v3GivenUnit == 'mm'
          ? '${_v3GivenValue.round()} mm'
          : '${_v3GivenValue.toStringAsFixed(2)} m';
      _roundCorrect('🧮 Correct! $disp = ${_v3Correct} cm!');
    } else {
      _roundWrong('Not quite! Think about the conversion 🧮');
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
  }

  void _roundWrong(String message) {
    setState(() {
      _phase = _Phase.wrongAnswer;
      _resultMessage = message;
      if (_roundAttempts >= 2) _roundStars = max(1, _roundStars - 1);
    });
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
            'Drag the ${_v1Object!.name} all the way down to the ruler. '
            'Look where its right end stops — that number is the length! '
            'The ${_v1Object!.name} is about ${_v1Object!.cm} cm.';
      case 'L-V2':
        hint =
            'Compare the two objects side by side. Which one reaches further to the right?';
      case 'L-V3':
        if (_v3GivenUnit == 'mm') {
          hint = '10 mm = 1 cm! So divide by 10: '
              '${_v3GivenValue.round()} mm ÷ 10 = ${_v3Correct} cm. You can do it! 🧮';
        } else {
          hint = '1 m = 100 cm! So multiply by 100: '
              '${_v3GivenValue.toStringAsFixed(2)} m × 100 = ${_v3Correct} cm. You can do it! 🧮';
        }
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
    if (_round >= _totalRounds) {
      _completeGame();
    } else {
      setState(() => _round++);
      _generateRound();
      _startTimer();
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
        (_targetSeconds[widget.variant] ?? 60) * _totalRounds.toDouble();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('student_id') ?? 'student_001';

    try {
      await GamesApiService.evaluateSession(
        userId: userId,
        domain: 'length',
        attempts: (_totalAttempts / _totalRounds).round(),
        time: sessionDuration,
        targetTime: targetTime,
        hints: _totalHints,
      );
    } catch (_) {}

    // If player passed, save the unlocked variant locally so the hub
    // reflects it immediately even before the backend response refreshes.
    final maxStars = _totalRounds * 3;
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
                    Text('Round $_round of $_totalRounds',
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
          // Round progress dots
          Row(
            children: List.generate(_totalRounds, (i) {
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
          ),
        ],
      ),
    );
  }

  String get _variantTitle {
    switch (widget.variant) {
      case 'L-V1':
        return '📏 Ruler Explorer';
      case 'L-V2':
        return '⚖️ Compare & Win';
      case 'L-V3':
        return '🧮 Calculate & Win';
      case 'L-V4':
        return '🌉 Build a Bridge';
      default:
        return '📏 Length Game';
    }
  }

  // ─── game area router ─────────────────────────────────────────────────────

  Widget _buildGameArea() {
    switch (widget.variant) {
      case 'L-V1':
        return _buildV1(_v1Object);
      case 'L-V2':
        return _buildV2(_v2ObjA, _v2ObjB);
      case 'L-V3':
        return _buildV3(_v3Object);
      case 'L-V4':
        return _buildV4();
      default:
        return const Center(child: Text('Unknown variant'));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // L-V1: Measure 1 Object
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildV1(_Obj? obj) {
    if (obj == null) return const SizedBox();
    return LayoutBuilder(builder: (context, constraints) {
      // ── scale so the ruler fills the available width exactly ──────────
      // Only extend 2-3 cm past the object so each cm mark is large
      // and kids can count them one by one.
      final int rulerMaxCm  = obj.cm + 3;
      final double availW   = constraints.maxWidth - 40.0; // 20px pad each side
      final double pxPerCm  = availW / rulerMaxCm;
      final double objBarW  = (obj.cm * pxPerCm).clamp(20.0, availW);
      final double objStartX = (availW - objBarW) / 2.0; // centre in bench

      // ── near-ruler detection for visual feedback ──────────────────────
      final bool isNearRuler =
          !_v1Snapped && _v1DragOffset.dy >= _v1SnapThreshY - 35;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── instruction banner ──────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _v1Snapped ? KidsColors.successLight : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: KidsShadows.soft,
                border: Border.all(
                  color: _v1Snapped
                      ? KidsColors.success.withOpacity(0.45)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Text(_v1Snapped ? '🎉' : '📏',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _v1Snapped
                              ? 'Count the marks and pick the length! 👇'
                              : 'Drag the ${obj.name} to the ruler!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _v1Snapped
                                ? KidsColors.successDark
                                : KidsColors.textPrimary,
                          ),
                        ),
                        if (!_v1Snapped)
                          const Text(
                            'Drop it at the 0 mark to measure',
                            style: TextStyle(
                              fontSize: 12,
                              color: KidsColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── measuring bench ─────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _kBenchH,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isNearRuler
                      ? KidsColors.success
                      : _v1Snapped
                          ? KidsColors.lengthColor.withOpacity(0.35)
                          : const Color(0xFFD8E4FF),
                  width: isNearRuler ? 3 : 2,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── ruler at the bottom of the bench ──────────────
                  Positioned(
                    left: 8, right: 8,
                    top: _kRulerTopY,
                    height: 60,
                    child: _buildInteractiveRuler(
                      pxPerCm: pxPerCm,
                      maxCm: rulerMaxCm,
                      highlightCm: _v1Snapped ? obj.cm : 0,
                      obj: obj,
                    ),
                  ),

                  // ── drop-zone arrow guide ──────────────────────────
                  if (!_v1Snapped)
                    Positioned(
                      left: 0, right: 0,
                      top: _kRulerTopY - 28,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 15,
                            color: isNearRuler
                                ? KidsColors.success
                                : KidsColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isNearRuler ? 'Let go! 🎯' : 'drop here',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isNearRuler
                                  ? KidsColors.success
                                  : KidsColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── draggable object (before snap) ────────────────
                  if (!_v1Snapped)
                    Positioned(
                      left: objStartX + _v1DragOffset.dx,
                      top: _kObjBarStartY + _v1DragOffset.dy,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          setState(() {
                            _v1IsDragging = true;
                            _v1DragOffset += d.delta;
                            // clamp horizontally within bench
                            final dx = _v1DragOffset.dx.clamp(
                              -objStartX + 8,
                              availW - objBarW - objStartX - 8,
                            );
                            // clamp vertically: don't go above start, stop at ruler
                            final dy = _v1DragOffset.dy.clamp(
                              -(_kObjBarStartY - 8),
                              _kRulerTopY - _kObjBarStartY - _kObjVisualH + 14,
                            );
                            _v1DragOffset = Offset(dx, dy);
                          });
                        },
                        onPanEnd: (_) {
                          setState(() {
                            _v1IsDragging = false;
                            if (_v1DragOffset.dy >= _v1SnapThreshY) {
                              _v1Snapped = true;
                            } else {
                              // spring back to start
                              _v1DragOffset = Offset.zero;
                            }
                          });
                        },
                        child: _buildObjectBar(
                          obj, pxPerCm,
                          isDragging: _v1IsDragging,
                          isPlaced: false,
                        ),
                      ),
                    ),

                  // ── object placed on ruler (after snap) ───────────
                  if (_v1Snapped)
                    Positioned(
                      left: 9, // aligns with ruler 0 mark
                      top: _kRulerTopY - _kObjVisualH - 2,
                      child: _buildObjectBar(
                        obj, pxPerCm,
                        isDragging: false,
                        isPlaced: true,
                      ),
                    ),

                  // ── "hold & drag" bounce hint ─────────────────────
                  if (!_v1Snapped && !_v1IsDragging)
                    Positioned(
                      left: 0, right: 0,
                      top: _kObjBarStartY + _kObjVisualH + 10,
                      child: AnimatedBuilder(
                        animation: _bounceAnim,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, _bounceAnim.value * 0.6),
                          child: const Center(
                            child: Text(
                              'Hold & drag it down ↓',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: KidsColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── answer choices (only after object is placed) ─────────────
            if (_v1Snapped) ...[  
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: _v1Choices
                    .map((c) => _choiceBtn('$c cm', () => _submitV1(c)))
                    .toList(),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── draggable object visual ────────────────────────────────────────────
  //
  // Shows the SVG illustration of the object. Width is still proportional
  // to obj.cm * pxPerCm so it aligns with the ruler marks.
  Widget _buildObjectBar(
    _Obj obj,
    double pxPerCm, {
    bool isDragging = false,
    bool isPlaced   = false,
  }) {
    final double w = (obj.cm * pxPerCm).clamp(20.0, 500.0);

    return SizedBox(
      width: w,
      height: _kObjVisualH,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── SVG object illustration ────────────────────────────────
          // Only constrain height so the SVG keeps its natural proportions.
          // The SizedBox width (= obj.cm * pxPerCm) still dictates how wide
          // the draggable hit-area is so it aligns with the ruler.
          SvgPicture.asset(
            obj.svg,
            height: _kObjVisualH - 14,
            fit: BoxFit.contain,
          ),
          // ── object name label ─────────────────────────────────────
          if (w > 50)
            Positioned(
              bottom: 0,
              child: Text(
                obj.name,
                style: TextStyle(
                  fontSize: w > 100 ? 11 : 9,
                  fontWeight: FontWeight.w700,
                  color: KidsColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // ── drag handle (hidden once placed) ──────────────────────
          if (!isPlaced && !isDragging)
            Positioned(
              bottom: 0, right: 0,
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 14,
                color: KidsColors.textTertiary.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  // ── interactive ruler ──────────────────────────────────────────────────
  //
  // Shows a yellow ruler with tick marks. Every cm gets a numbered label so
  // kids can count one-by-one. No measurement bubble — the child must count
  // the marks themselves and pick the answer from the choices.
  Widget _buildInteractiveRuler({
    required double pxPerCm,
    required int    maxCm,
    required int    highlightCm,
    required _Obj   obj,
  }) {
    // When pxPerCm is large enough show every‐cm labels,
    // otherwise fall back to every 2 cm to avoid overlap.
    final int labelEvery = pxPerCm >= 18 ? 1 : 2;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC02), width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── highlight fill (no number, just colour) ─────────────
          if (highlightCm > 0)
            Positioned(
              left: 2, top: 2, bottom: 2,
              width: max(0.0, highlightCm * pxPerCm - 4),
              child: Container(
                decoration: BoxDecoration(
                  color: obj.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),

          // ── 0-mark label always visible ──────────────────────────
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF795548),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ── ticks & every-cm labels ──────────────────────────────
          ...List.generate(maxCm + 1, (i) {
            final bool showLabel = i > 0 && i % labelEvery == 0;
            final bool isMajor  = i > 0 && i % 5 == 0;
            final double tickH  = isMajor ? 26 : (showLabel ? 20 : 12);
            return Positioned(
              left: i * pxPerCm,
              top: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showLabel)
                    Text(
                      '$i',
                      style: TextStyle(
                        fontSize: isMajor ? 12 : 10,
                        fontWeight:
                            isMajor ? FontWeight.w800 : FontWeight.w600,
                        color: const Color(0xFF795548),
                      ),
                    )
                  else
                    SizedBox(height: isMajor ? 14 : 12),
                  Container(
                    width: isMajor ? 2.0 : 1.5,
                    height: tickH,
                    color: const Color(0xFF795548),
                  ),
                ],
              ),
            );
          }),

          // ── "count the marks!" nudge when placed ────────────────
          if (highlightCm > 0)
            Positioned(
              right: 6,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF795548).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'count! 👆',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF795548),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // L-V2: Compare 2 Objects
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildV2(_Obj? a, _Obj? b) {
    if (a == null || b == null) return const SizedBox();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: KidsShadows.soft,
            ),
            child: Column(
              children: [
                const Text('Which one is LONGER?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: KidsColors.textPrimary)),
                const SizedBox(height: 24),
                // Two objects with visual length bars
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _buildObjectCompareCard(a, 'A')),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        width: 2,
                        height: 80,
                        color: const Color(0xFFE0E0E0),
                      ),
                    ),
                    Expanded(child: _buildObjectCompareCard(b, 'B')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Tap to choose 👇',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: KidsColors.textSecondary.withOpacity(0.7))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _choiceBtnColored('A: ${a.name}', a.color, () => _submitV2('A')),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _choiceBtnColored('B: ${b.name}', b.color, () => _submitV2('B')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _choiceBtnColored(
              '🤝 They\'re the same!', const Color(0xFF9C27B0),
              () => _submitV2('same')),
        ],
      ),
    );
  }

  Widget _buildObjectCompareCard(_Obj obj, String label) {
    // The maximum cm among all objects (spoon = 18 cm).
    const double _maxObjCm = 18.0;

    return LayoutBuilder(builder: (ctx, cons) {
      final maxBarW = cons.maxWidth - 32.0; // 16px pad each side
      final barW    = (obj.cm / _maxObjCm * maxBarW).clamp(12.0, maxBarW);

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
            child: Column(
              children: [
                // ── Object SVG at natural proportions ───────────────────
                SvgPicture.asset(
                  obj.svg,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Text(
                  obj.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KidsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Proportional length bar ─────────────────────────────
                // Background track (full width)
                Container(
                  width: maxBarW,
                  height: 18,
                  decoration: BoxDecoration(
                    color: obj.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: barW,
                    height: 18,
                    decoration: BoxDecoration(
                      color: obj.color,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: obj.color.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${obj.cm} cm',
                      style: TextStyle(
                        fontSize: barW > 36 ? 11 : 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                // Label badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: obj.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: obj.color.withOpacity(0.4)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: obj.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // L-V3: Calculate & Win (unit conversion)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildV3(_Obj? obj) {
    if (obj == null) return const SizedBox();
    final givenDisplay = _v3GivenUnit == 'mm'
        ? '${_v3GivenValue.round()} mm'
        : '${_v3GivenValue.toStringAsFixed(2)} m';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          // Object card with measurement
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: KidsShadows.soft,
            ),
            child: Column(
              children: [
                Text(
                  'This is a ${obj.name}!',
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: KidsColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SvgPicture.asset(obj.svg, height: 90, fit: BoxFit.contain),
                const SizedBox(height: 20),
                // Measurement badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: KidsColors.lengthColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: KidsColors.lengthColor, width: 2.5),
                  ),
                  child: Text(
                    givenDisplay,
                    style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: KidsColors.lengthColor,
                        letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '→ How many cm is the ${obj.name}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: KidsColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 2×2 answer choices
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.8,
            children: _v3Choices.map((cm) {
              return GestureDetector(
                onTap: () => _submitV3(cm),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: KidsShadows.soft,
                    border: Border.all(
                        color: KidsColors.lengthColor.withOpacity(0.35), width: 2),
                  ),
                  child: Text(
                    '$cm cm',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: KidsColors.textPrimary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
                    _round < _totalRounds ? '➡️ Next Round!' : '🏁 Finish!',
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
    final maxStars = _totalRounds * 3;
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
          Text('You finished all $_totalRounds rounds!',
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
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── primary action: unlock next level OR play again ─────────────
          Builder(builder: (_) {
            final maxStars = _totalRounds * 3;
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
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🏆 All Levels Complete!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
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
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text('← Back to Games',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: KidsColors.textSecondary)),
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

  Widget _choiceBtnColored(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }

  Widget _bigPlayBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }

}
