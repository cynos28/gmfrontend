/// Area Game Play Screen
/// Renders A-V1 (Tile Rectangle) with kids-friendly UI,
/// adaptive difficulty, and backend integration.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { playing, wrongAnswer, showResult, complete }

/// Unit types for area measurements
enum _AreaUnit { 
  mm2, // millimeters squared
  cm2, // centimeters squared (default)
  m2,  // meters squared
}

extension _AreaUnitExt on _AreaUnit {
  String get display {
    switch (this) {
      case _AreaUnit.mm2: return 'mm²';
      case _AreaUnit.cm2: return 'cm²';
      case _AreaUnit.m2: return 'm²';
    }
  }
  String get lengthUnit {
    switch (this) {
      case _AreaUnit.mm2: return 'mm';
      case _AreaUnit.cm2: return 'cm';
      case _AreaUnit.m2: return 'm';
    }
  }
}

/// Per-variant target times (seconds per round)
const Map<String, int> _targetSeconds = {
  'A-V1': 60,
};

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class AreaGamePlayScreen extends StatefulWidget {
  final String variant; // 'A-V1'
  const AreaGamePlayScreen({super.key, required this.variant});

  @override
  State<AreaGamePlayScreen> createState() => _AreaGamePlayScreenState();
}

class _AreaGamePlayScreenState extends State<AreaGamePlayScreen>
    with TickerProviderStateMixin {
  final _rng = Random();

  // ─── Common state ──────────────────────────────────────────────────────
  Map<String, dynamic> _params = {};
  _Phase _phase = _Phase.playing;
  int _round = 1;
  final int _totalRounds = 5;
  int _roundAttempts = 0;
  int _roundStars = 3;
  int _totalAttempts = 0;
  int _totalHints = 0;
  int _totalStarsEarned = 0;
  int _hintsAllowed = 2;
  int _hintsUsedThisRound = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  late DateTime _sessionStart;
  String _resultMessage = '';
  bool _submitting = false;

  // ─── Animations ────────────────────────────────────────────────────────
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _starCtrl;
  late Animation<double> _starAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // ─── V1 state: Tile Rectangle ──────────────────────────────────────────
  int _v1Width = 0;  // rectangle width (answer)
  int _v1Height = 0; // rectangle height (answer)
  int _v1Correct = 0; // width * height
  int _v1GridW = 0;  // big grid width (more tiles than needed)
  int _v1GridH = 0;  // big grid height
  List<List<bool>> _v1Grid = [];
  bool _v1ShowGrid = true;
  int _v1FilledCount = 0;
  _AreaUnit _v1Unit = _AreaUnit.cm2; // Current unit for this round
  
  // Track used questions to avoid repetition
  final Set<String> _usedQuestions = {};

  // ─── IRT adaptive state ────────────────────────────────────────────────
  double _irtTheta = 0.0;
  int _irtDifficultyLevel = 1;
  int _irtRoundsPlayed = 0;
  String _userId = 'student_001';

  // ─── Unlock progression ────────────────────────────────────────────────
  static const int _passPercent = 60;
  static const List<String> _variantOrder = ['A-V1'];
  String? get _nextVariantCode {
    final idx = _variantOrder.indexOf(widget.variant);
    return idx < _variantOrder.length - 1 ? _variantOrder[idx + 1] : null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

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
    // Load user ID
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _userId = prefs.getString('student_id') ?? 'student_001';

    // Fetch IRT state for this variant
    final irtState = await GamesApiService.getIRTState(
      studentId: _userId,
      domain: 'area',
      variant: widget.variant,
    );
    if (!mounted) return;
    setState(() {
      _irtTheta = (irtState['theta'] as num?)?.toDouble() ?? 0.0;
      _irtDifficultyLevel = (irtState['difficulty_level'] as num?)?.toInt() ?? 1;
      _irtRoundsPlayed = (irtState['rounds_played'] as num?)?.toInt() ?? 0;
    });

    // Fetch game parameters (IRT-adapted if session exists)
    _params = await GamesApiService.getParameters(
      'area',
      studentId: _userId,
      variant: widget.variant,
    );
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
      _shakeCtrl.reset();
    });

    switch (widget.variant) {
      case 'A-V1':
        _genV1();
    }
  }

  // ─── V1 generation: Tile Rectangle ─────────────────────────────────────

  void _genV1() {
    final gridVisible = (_params['grid_visible'] as bool?) ?? true;
    
    // Use IRT difficulty level to determine appropriate ranges
    final diffLevel = _irtDifficultyLevel;
    
    // Select unit type based on difficulty
    _AreaUnit selectedUnit;
    int minSize, maxSize;
    
    if (diffLevel <= 1) {
      // Level 1 (Easy): Only cm², very small numbers, simple areas
      selectedUnit = _AreaUnit.cm2;
      minSize = 2;
      maxSize = 4;  // Areas: 4-16 cm²
    } else if (diffLevel == 2) {
      // Level 2 (Medium): Mostly cm², slightly larger
      selectedUnit = _rng.nextDouble() < 0.8 ? _AreaUnit.cm2 : _AreaUnit.m2;
      minSize = selectedUnit == _AreaUnit.cm2 ? 3 : 2;
      maxSize = selectedUnit == _AreaUnit.cm2 ? 6 : 4;  // Areas: 9-36 cm² or 4-16 m²
    } else if (diffLevel == 3) {
      // Level 3 (Hard): Mix of units, moderate ranges
      final unitTypes = [_AreaUnit.cm2, _AreaUnit.m2];
      selectedUnit = unitTypes[_rng.nextInt(unitTypes.length)];
      switch (selectedUnit) {
        case _AreaUnit.cm2:
          minSize = 4;
          maxSize = 8;  // Areas: 16-64 cm²
          break;
        case _AreaUnit.m2:
          minSize = 3;
          maxSize = 6;  // Areas: 9-36 m²
          break;
        case _AreaUnit.mm2:
          minSize = 10;
          maxSize = 15;
          break;
      }
    } else if (diffLevel == 4) {
      // Level 4 (Expert): All units, larger ranges
      final unitTypes = _AreaUnit.values;
      selectedUnit = unitTypes[_rng.nextInt(unitTypes.length)];
      switch (selectedUnit) {
        case _AreaUnit.mm2:
          minSize = 10;
          maxSize = 20;  // Areas: 100-400 mm²
          break;
        case _AreaUnit.cm2:
          minSize = 5;
          maxSize = 10;  // Areas: 25-100 cm²
          break;
        case _AreaUnit.m2:
          minSize = 4;
          maxSize = 7;   // Areas: 16-49 m²
          break;
      }
    } else {
      // Level 5 (Master): All units, largest ranges
      final unitTypes = _AreaUnit.values;
      selectedUnit = unitTypes[_rng.nextInt(unitTypes.length)];
      switch (selectedUnit) {
        case _AreaUnit.mm2:
          minSize = 15;
          maxSize = 25;  // Areas: 225-625 mm²
          break;
        case _AreaUnit.cm2:
          minSize = 8;
          maxSize = 12;  // Areas: 64-144 cm²
          break;
        case _AreaUnit.m2:
          minSize = 5;
          maxSize = 8;   // Areas: 25-64 m²
          break;
      }
    }
    
    // Override with params if provided (but respect difficulty scaling)
    final paramMax = (_params['max_rect_size'] as num?)?.toInt();
    final paramMin = (_params['min_rect_size'] as num?)?.toInt();
    if (paramMax != null && paramMax < maxSize) maxSize = paramMax;
    if (paramMin != null && paramMin > minSize) minSize = paramMin;
    
    // Generate unique question (avoid repetition)
    int w, h;
    String questionKey;
    int attempts = 0;
    do {
      w = minSize + _rng.nextInt(max(1, maxSize - minSize + 1));
      h = minSize + _rng.nextInt(max(1, maxSize - minSize + 1));
      questionKey = '${selectedUnit.name}_${w}_$h';
      attempts++;
      if (attempts > 20) {
        // If we've tried 20 times, clear some history to allow new questions
        _usedQuestions.clear();
        break;
      }
    } while (_usedQuestions.contains(questionKey));
    
    _usedQuestions.add(questionKey);
    final correct = w * h;

    // Make the grid BIGGER than the rectangle so there are more tiles
    // than the correct answer — kids must place exactly the right count.
    final extraCols = 1 + _rng.nextInt(3); // 1-3 extra columns
    final extraRows = 1 + _rng.nextInt(3); // 1-3 extra rows
    final gw = w + extraCols;
    final gh = h + extraRows;

    setState(() {
      _v1Width = w;
      _v1Height = h;
      _v1Correct = correct;
      _v1Unit = selectedUnit;
      _v1ShowGrid = gridVisible;
      _v1GridW = gw;
      _v1GridH = gh;
      _v1Grid = List.generate(gh, (_) => List.generate(gw, (_) => false));
      _v1FilledCount = 0;
    });
  }

  // ─── V3 generation: Fill the Shape (Drag & Drop) ───────────────────────

  /// Generate house silhouette (area ~16-20)
  List<List<bool>> _generateHouseSilhouette() {
    // 8x8 grid with house shape
    final grid = List.generate(8, (_) => List.generate(8, (_) => false));
    
    // Roof (triangle-ish) - rows 0-2
    grid[0][3] = true; grid[0][4] = true;
    grid[1][2] = true; grid[1][3] = true; grid[1][4] = true; grid[1][5] = true;
    grid[2][1] = true; grid[2][2] = true; grid[2][3] = true; grid[2][4] = true; grid[2][5] = true; grid[2][6] = true;
    
    // Body (rectangle) - rows 3-7
    for (int y = 3; y < 8; y++) {
      for (int x = 2; x < 6; x++) {
        grid[y][x] = true;
      }
    }
    
    return grid;
  }
  
  /// Generate rocket silhouette (area ~18)
  List<List<bool>> _generateRocketSilhouette() {
    final grid = List.generate(9, (_) => List.generate(6, (_) => false));
    
    // Nose - rows 0-1
    grid[0][2] = true; grid[0][3] = true;
    grid[1][2] = true; grid[1][3] = true;
    
    // Body - rows 2-6
    for (int y = 2; y < 7; y++) {
      grid[y][1] = true; grid[y][2] = true; grid[y][3] = true; grid[y][4] = true;
    }
    
    // Fins - rows 7-8
    grid[7][0] = true; grid[7][1] = true; grid[7][2] = true; grid[7][3] = true; grid[7][4] = true; grid[7][5] = true;
    grid[8][0] = true; grid[8][5] = true;
    
    return grid;
  }
  
  /// Generate tree silhouette (area ~15)
  List<List<bool>> _generateTreeSilhouette() {
    final grid = List.generate(8, (_) => List.generate(7, (_) => false));
    
    // Top leaves - rows 0-2
    grid[0][3] = true;
    grid[1][2] = true; grid[1][3] = true; grid[1][4] = true;
    grid[2][1] = true; grid[2][2] = true; grid[2][3] = true; grid[2][4] = true; grid[2][5] = true;
    
    // Middle leaves - rows 3-4
    grid[3][2] = true; grid[3][3] = true; grid[3][4] = true;
    grid[4][1] = true; grid[4][2] = true; grid[4][3] = true; grid[4][4] = true; grid[4][5] = true;
    
    // Trunk - rows 5-7
    for (int y = 5; y < 8; y++) {
      grid[y][3] = true;
    }
    
    return grid;
  }
  
  /// Generate robot silhouette (area ~20)
  List<List<bool>> _generateRobotSilhouette() {
    final grid = List.generate(8, (_) => List.generate(7, (_) => false));
    
    // Head - rows 0-1
    grid[0][2] = true; grid[0][3] = true; grid[0][4] = true;
    grid[1][2] = true; grid[1][3] = true; grid[1][4] = true;
    
    // Body - rows 2-5
    for (int y = 2; y < 6; y++) {
      grid[y][1] = true; grid[y][2] = true; grid[y][3] = true; grid[y][4] = true; grid[y][5] = true;
    }
    
    // Legs - rows 6-7
    grid[6][1] = true; grid[6][2] = true; grid[6][4] = true; grid[6][5] = true;
    grid[7][1] = true; grid[7][2] = true; grid[7][4] = true; grid[7][5] = true;
    
    return grid;
  }
  
  /// Generate car silhouette (area ~16)
  List<List<bool>> _generateCarSilhouette() {
    final grid = List.generate(5, (_) => List.generate(9, (_) => false));
    
    // Cabin top - row 0
    grid[0][3] = true; grid[0][4] = true; grid[0][5] = true;
    
    // Cabin/body - rows 1-2
    for (int x = 1; x < 8; x++) {
      grid[1][x] = true;
      grid[2][x] = true;
    }
    
    // Body - row 3
    for (int x = 0; x < 9; x++) {
      grid[3][x] = true;
    }
    
    // Wheels - row 4 (just the top part)
    grid[4][1] = true; grid[4][2] = true;
    grid[4][6] = true; grid[4][7] = true;
    
    return grid;
  }
  
  /// Generate boat silhouette (area ~14)
  List<List<bool>> _generateBoatSilhouette() {
    final grid = List.generate(6, (_) => List.generate(8, (_) => false));
    
    // Sail - rows 0-3
    grid[0][4] = true;
    grid[1][3] = true; grid[1][4] = true;
    grid[2][2] = true; grid[2][3] = true; grid[2][4] = true;
    grid[3][1] = true; grid[3][2] = true; grid[3][3] = true; grid[3][4] = true;
    
    // Boat body - rows 4-5
    for (int x = 0; x < 8; x++) {
      grid[4][x] = true;
    }
    grid[5][1] = true; grid[5][2] = true; grid[5][3] = true; grid[5][4] = true; grid[5][5] = true; grid[5][6] = true;
    
    return grid;
  }
  
  /// Generate pieces for V3 based on target area
  List<Map<String, dynamic>> _generateV3Pieces(int targetArea) {
    final pieces = <Map<String, dynamic>>[];
    final colors = [
      const Color(0xFFFF6B6B), const Color(0xFF4ECDC4), const Color(0xFFFFE66D),
      const Color(0xFF95E1D3), const Color(0xFFF38181), const Color(0xFFAA96DA),
      const Color(0xFF6BCB77), const Color(0xFFFF9671), const Color(0xFF845EC2),
    ];
    int colorIdx = 0;
    
    // Always include unit squares
    int squaresNeeded = targetArea ~/ 2;  // Half as unit squares
    for (int i = 0; i < squaresNeeded + 3; i++) {
      pieces.add({
        'cells': [[0, 0]],
        'area': 1,
        'color': colors[colorIdx++ % colors.length],
        'name': '1×1',
      });
    }
    
    // Add 1×2 dominoes
    int dominoesNeeded = targetArea ~/ 4;
    for (int i = 0; i < dominoesNeeded + 2; i++) {
      pieces.add({
        'cells': [[0, 0], [1, 0]],
        'area': 2,
        'color': colors[colorIdx++ % colors.length],
        'name': '1×2',
      });
    }
    
    // Add 2×1 dominoes
    for (int i = 0; i < dominoesNeeded + 1; i++) {
      pieces.add({
        'cells': [[0, 0], [0, 1]],
        'area': 2,
        'color': colors[colorIdx++ % colors.length],
        'name': '2×1',
      });
    }
    
    // Add 2×2 squares if target is larger
    if (targetArea >= 12) {
      int bigSquares = targetArea ~/ 8;
      for (int i = 0; i < bigSquares + 1; i++) {
        pieces.add({
          'cells': [[0, 0], [1, 0], [0, 1], [1, 1]],
          'area': 4,
          'color': colors[colorIdx++ % colors.length],
          'name': '2×2',
        });
      }
    }
    
    // Add 1×3 rectangles
    if (targetArea >= 15) {
      pieces.add({
        'cells': [[0, 0], [1, 0], [2, 0]],
        'area': 3,
        'color': colors[colorIdx++ % colors.length],
        'name': '1×3',
      });
    }
    
    // Shuffle pieces
    pieces.shuffle(_rng);
    
    return pieces;
  }

  // ─── V4 generation: Composite Area ─────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────
  // ANSWER HANDLING
  // ─────────────────────────────────────────────────────────────────────────

  void _submitV1Check() {
    if (_phase != _Phase.playing) return;
    setState(() => _roundAttempts++);
    if (_v1FilledCount == _v1Correct) {
      _roundCorrect('🟩 Correct! ${_v1Width} × ${_v1Height} = $_v1Correct ${_v1Unit.display}!');
    } else if (_v1FilledCount < _v1Correct) {
      _roundWrong('Not enough tiles! ${_v1Width} × ${_v1Height} = ? 🔢');
    } else {
      _roundWrong('Too many tiles! You placed $_v1FilledCount but need $_v1Correct 🔢');
    }
  }

  /// Check if piece can be placed at position
  
  /// Place piece on board
  
  /// Remove piece from board (tap to remove)
  
  String _getPieceName(List<List<int>> cells) {
    if (cells.length == 1) return '1×1';
    if (cells.length == 2) {
      // Check orientation
      if (cells[0][1] == cells[1][1]) return '1×2';
      return '2×1';
    }
    if (cells.length == 4) return '2×2';
    if (cells.length == 3) return '1×3';
    return '${cells.length}';
  }

  /// Show hint for V3 - highlight missing cells

  /// Clear all pieces from V3 board

  // ─── Common answer helpers ─────────────────────────────────────────────

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
    _submitRoundToIRT(true, stars);
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
    // After 3 failed attempts, record as wrong for IRT
    if (_roundAttempts >= 3) {
      _submitRoundToIRT(false, 0);
    }
  }

  /// Fire-and-forget: send round result to backend IRT engine
  Future<void> _submitRoundToIRT(bool correct, int stars) async {
    try {
      final result = await GamesApiService.submitRoundResult(
        studentId: _userId,
        domain: 'area',
        variant: widget.variant,
        correct: correct,
        attempts: _roundAttempts,
        hintsUsed: _hintsUsedThisRound,
        timeSeconds: _elapsedSeconds.toDouble(),
        starsEarned: stars,
      );
      if (!mounted) return;
      setState(() {
        _irtTheta = (result['theta'] as num?)?.toDouble() ?? _irtTheta;
        _irtDifficultyLevel = (result['difficulty_level'] as num?)?.toInt() ?? _irtDifficultyLevel;
        _irtRoundsPlayed = (result['rounds_played'] as num?)?.toInt() ?? _irtRoundsPlayed;
      });
      // Merge next_params into _params for next round
      final nextParams = result['next_params'] as Map<String, dynamic>?;
      if (nextParams != null) {
        _params.addAll(nextParams);
        _hintsAllowed = (_params['hints'] as int?) ?? _hintsAllowed;
      }
    } catch (_) {
      // silently fail — game continues with current params
    }
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
      case 'A-V1':
        hint = 'Think: $_v1Width columns × $_v1Height rows = ?\n'
            'Place exactly that many tiles! 🧮';
      default:
        hint = 'Think carefully! You can do this! 💪';
    }
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFFF8E1),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: KidsColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('💡', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            const Text('Hint',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5D4037))),
          ],
        ),
        content: Text(hint,
            style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF5D4037))),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: KidsColors.areaColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Get.back(),
            child: const Text('Got it!', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── Round progression ─────────────────────────────────────────────────

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
        domain: 'area',
        attempts: (_totalAttempts / _totalRounds).round(),
        time: sessionDuration,
        targetTime: targetTime,
        hints: _totalHints,
      );
    } catch (_) {}

    final maxStars = _totalRounds * 3;
    final percent = (_totalStarsEarned / maxStars * 100).round();
    if (percent >= _passPercent) {
      final next = _nextVariantCode;
      if (next != null) {
        await prefs.setString('area_unlocked_variant', next);
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
      backgroundColor: const Color(0xFFF0FFF4),
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
            // Wrong-answer shake overlay
            if (_phase == _Phase.wrongAnswer)
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(sin(_shakeAnim.value * 3 * pi) * 10, 0),
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Text(_resultMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                  ),
                ),
              ),
            // Show-result overlay
            if (_phase == _Phase.showResult)
              Positioned.fill(
                child: _buildResultOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF1B8A3E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_variantTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Round $_round of $_totalRounds',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildIRTBadge(),
                      ],
                    ),
                  ],
                ),
              ),
              // Stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        i < _roundStars ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: i < _roundStars
                            ? const Color(0xFFFFD700)
                            : Colors.white.withOpacity(0.4),
                        size: 20,
                      ),
                    ),
                  ),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('💡', style: TextStyle(fontSize: 20))),
                ),
              ),
              const SizedBox(width: 8),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⏱ ${_elapsedSeconds}s',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _variantTitle {
    switch (widget.variant) {
      case 'A-V1':
        return '🟩 Tile Rectangle';default:
        return '📐 Area Game';
    }
  }

  Widget _buildIRTBadge() {
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    const colors = [Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFFE91E63), Color(0xFF9C27B0)];
    final idx = (_irtDifficultyLevel - 1).clamp(0, 4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors[idx].withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors[idx].withOpacity(0.6), width: 1),
      ),
      child: Text(
        labels[idx],
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colors[idx],
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
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KidsColors.textTertiary)),
      ],
    );
  }

  // ─── Game area router ──────────────────────────────────────────────────

  Widget _buildGameArea() {
    switch (widget.variant) {
      case 'A-V1':
        return _buildV1();
      default:
        return const Center(child: Text('This game mode is unavailable'));
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  V1: TILE RECTANGLE
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildV1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Instruction chip
          _instructionChip(
            'The rectangle is ${_v1Width} cm × ${_v1Height} cm.\n'
            'Place exactly the right number of tiles on the grid!',
          ),
          const SizedBox(height: 16),

          // Dimension labels
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _dimensionBadge('${_v1Width} ${_v1Unit.lengthUnit}', const Color(0xFF4285F4)),
                const Text(' × ',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF424242))),
                _dimensionBadge('${_v1Height} ${_v1Unit.lengthUnit}', const Color(0xFF34C759)),
                const Text(' = ',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF424242))),
                _dimensionBadge('? ${_v1Unit.display}', const Color(0xFFFF9500)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bigger grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: KidsShadows.soft,
            ),
            child: Column(
              children: [
                // Target area question
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Target Area: $_v1Correct ${_v1Unit.display}',
                          style: GoogleFonts.fredoka(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.brown.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Fill ${_v1Width} × ${_v1Height} ${_v1Unit.lengthUnit} rectangle!',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.brown.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Interactive grid — bigger than the rectangle
                _buildTileGrid(
                  width: _v1GridW,
                  height: _v1GridH,
                  tiles: _v1Grid,
                  showGrid: _v1ShowGrid,
                  tileColor: const Color(0xFF34C759),
                  onTap: (x, y) {
                    if (_phase != _Phase.playing) return;
                    setState(() {
                      _v1Grid[y][x] = !_v1Grid[y][x];
                      _v1FilledCount += _v1Grid[y][x] ? 1 : -1;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Clear button
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (int y = 0; y < _v1GridH; y++) {
                        for (int x = 0; x < _v1GridW; x++) {
                          _v1Grid[y][x] = false;
                        }
                      }
                      _v1FilledCount = 0;
                    });
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tile counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _v1FilledCount == _v1Correct
                  ? const Color(0xFFE8F5E9)
                  : _v1FilledCount > _v1Correct
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _v1FilledCount == _v1Correct
                    ? const Color(0xFF66BB6A)
                    : _v1FilledCount > _v1Correct
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFFFCA28),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset('assets/images/tile1.jpg',
                      width: 20, height: 20, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_v1FilledCount / $_v1Correct tiles placed',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _v1FilledCount == _v1Correct
                        ? const Color(0xFF2E7D32)
                        : _v1FilledCount > _v1Correct
                            ? const Color(0xFFC62828)
                            : Colors.brown.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Check button
          _bigPlayBtn(
            '✅ Check My Tiles!',
            KidsColors.areaColor,
            _submitV1Check,
          ),
        ],
      ),
    );
  }

  /// Build a shape widget (rectangle, circle, or triangle)
  Widget _buildShapeWidget(Map<String, dynamic> part, {required bool showLabel}) {
    final type = part['type'] as String;
    final width = part['width'] as double;
    final height = part['height'] as double;
    final color = part['color'] as Color;
    final label = part['label'] as String;
    
    Widget shapeWidget;
    
    if (type == 'rect') {
      // Rectangle with rounded corners and border
      shapeWidget = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black87, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
    } else if (type == 'circle') {
      // Circle with border
      shapeWidget = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black87, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
    } else if (type == 'triangle') {
      // Triangle with border using CustomPaint
      shapeWidget = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          size: Size(width, height),
          painter: _TrianglePainter(color: color),
        ),
      );
    } else {
      // Fallback
      shapeWidget = Container();
    }
    
    // Wrap with label overlay if needed
    if (showLabel) {
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            shapeWidget,
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black87, width: 1.5),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return shapeWidget;
    }
  }

  Widget _buildGhostOutline(Map<String, dynamic> part, double width, double height, {double opacity = 0.65}) {
    final outlineColor = Colors.grey.shade700.withOpacity(opacity);
    final markerSize = max(8.0, min(width, height) * 0.12);
    final type = part['type'] as String;

    Widget outline;
    if (type == 'rect') {
      outline = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: outlineColor, width: 2),
        ),
      );
    } else if (type == 'circle') {
      outline = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: outlineColor, width: 2),
        ),
      );
    } else if (type == 'triangle') {
      outline = CustomPaint(
        size: Size(width, height),
        painter: _TriangleOutlinePainter(color: outlineColor, strokeWidth: 2.2),
      );
    } else {
      outline = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: outlineColor, width: 2),
        ),
      );
    }

    return IgnorePointer(
      child: Stack(
        children: [
          outline,
          Positioned.fill(
            child: Center(
              child: Container(
                width: markerSize,
                height: markerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: outlineColor, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
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

  // ═════════════════════════════════════════════════════════════════════════
  //  V3: FILL THE SHAPE (Drag & Drop)
  // ═════════════════════════════════════════════════════════════════════════

  /// Build V3 grid (silhouette with placed pieces)

  /// Get piece color by ID on board (cycle through colors)
  Color _getPieceColorById(int pieceId) {
    final colors = [
      const Color(0xFFFF6B6B), const Color(0xFF4ECDC4), const Color(0xFFFFE66D),
      const Color(0xFF95E1D3), const Color(0xFFF38181), const Color(0xFFAA96DA),
      const Color(0xFF6BCB77), const Color(0xFFFF9671), const Color(0xFF845EC2),
    ];
    return colors[(pieceId - 1) % colors.length];
  }

  /// Build draggable piece item

  /// Build piece tile for tray
  Widget _buildPieceTile(int pieceW, int pieceH, List<List<int>> cells, Color color, String name, int area, double cellSize) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPiecePreview(cells, color, cellSize),
          const SizedBox(height: 4),
          Text(
            '$area',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build piece preview grid
  Widget _buildPiecePreview(List<List<int>> cells, Color color, double cellSize) {
    // Find bounds
    int maxX = 0, maxY = 0;
    for (final cell in cells) {
      maxX = max(maxX, cell[0]);
      maxY = max(maxY, cell[1]);
    }
    final pieceW = maxX + 1;
    final pieceH = maxY + 1;

    // Create grid
    final grid = List.generate(pieceH, (_) => List.generate(pieceW, (_) => false));
    for (final cell in cells) {
      grid[cell[1]][cell[0]] = true;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pieceH, (y) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(pieceW, (x) => Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            color: grid[y][x] ? color : Colors.transparent,
            border: grid[y][x] ? Border.all(color: color.withOpacity(0.8), width: 1) : null,
            borderRadius: BorderRadius.circular(2),
          ),
        )),
      )),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  V4: COMPOSITE AREA (Split & Add)
  // ═════════════════════════════════════════════════════════════════════════

  Color _partColor(int i) {
    const colors = [
      Color(0xFF9C27B0),
      Color(0xFF1E88E5),
      Color(0xFFE65100),
    ];
    return colors[i % colors.length];
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  SHARED UI COMPONENTS
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildTileGrid({
    required int width,
    required int height,
    required List<List<bool>> tiles,
    required bool showGrid,
    required Color tileColor,
    required void Function(int x, int y) onTap,
  }) {
    final cellSize = min(280.0 / max(width, height), 52.0);

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5E6CA),
          border: Border.all(color: const Color(0xFF8D6E63), width: 3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(height, (y) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(width, (x) {
              final filled = tiles[y][x];
              return GestureDetector(
                onTap: () => onTap(x, y),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: cellSize,
                  height: cellSize,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: filled
                        ? Colors.transparent
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: filled
                          ? tileColor.withOpacity(0.6)
                          : const Color(0xFFD7CCC8),
                      width: filled ? 2 : 1,
                    ),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: tileColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: filled
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'assets/images/tile1.jpg',
                            width: cellSize,
                            height: cellSize,
                            fit: BoxFit.cover,
                          ),
                        )
                      : showGrid
                          ? Center(
                              child: Icon(
                                Icons.add_rounded,
                                size: cellSize * 0.35,
                                color: const Color(0xFFBCAAA4),
                              ),
                            )
                          : null,
                ),
              );
            }),
          )),
        ),
      ),
    );
  }

  Widget _instructionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KidsColors.areaColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('📋', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                  height: 1.4,
                )),
          ),
        ],
      ),
    );
  }

  Widget _dimensionBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          )),
    );
  }

  Widget _choiceBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _phase == _Phase.playing ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: KidsColors.areaColor.withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: KidsColors.areaColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E7D32),
            )),
      ),
    );
  }

  Widget _bigPlayBtn(String label, Color color, VoidCallback? onTap) {
    final isDisabled = onTap == null;
    final effectiveColor = isDisabled ? Colors.grey.shade400 : color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [effectiveColor, effectiveColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDisabled ? [] : [
            BoxShadow(
              color: effectiveColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDisabled ? Colors.grey.shade600 : Colors.white,
            )),
      ),
    );
  }

  // ─── Result overlay ────────────────────────────────────────────────────

  Widget _buildResultOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: ScaleTransition(
          scale: _starAnim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: KidsColors.areaColor.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _roundStars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i < _roundStars
                            ? const Color(0xFFFFD700)
                            : Colors.grey.shade300,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_resultMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    )),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _nextRound,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34C759), Color(0xFF1B8A3E)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _round >= _totalRounds ? '🏆 Finish!' : '▶ Next Round',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
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

  // ─── Complete screen ───────────────────────────────────────────────────

  Widget _buildCompleteScreen() {
    if (_submitting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: KidsColors.areaColor),
            SizedBox(height: 16),
            Text('Saving your progress…',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32))),
          ],
        ),
      );
    }

    final maxStars = _totalRounds * 3;
    final percent = (_totalStarsEarned / maxStars * 100).round();
    final passed = percent >= _passPercent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: KidsColors.areaColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(passed ? '🎉' : '💪',
                    style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  passed ? 'Amazing Work!' : 'Good Try!',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.variant} • $_variantTitle',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: KidsColors.textTertiary),
                ),
                const SizedBox(height: 24),

                // Stats grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBubble('⭐', '$_totalStarsEarned/$maxStars',
                        'Stars', const Color(0xFFFFD700)),
                    _statBubble('🎯', '$percent%', 'Score',
                        passed ? KidsColors.success : KidsColors.warning),
                    _statBubble('🔄', '$_totalAttempts', 'Attempts',
                        const Color(0xFF4285F4)),
                  ],
                ),
                const SizedBox(height: 16),

                // IRT adaptive stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _irtStatChip('Level', '$_irtDifficultyLevel', const Color(0xFF9C27B0)),
                      _irtStatChip('Ability', _irtTheta.toStringAsFixed(2), const Color(0xFF1565C0)),
                      _irtStatChip('Rounds', '$_irtRoundsPlayed', const Color(0xFF2E7D32)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Pass/fail banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: passed
                        ? KidsColors.success.withOpacity(0.1)
                        : KidsColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(passed ? '🔓' : '🔒',
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          passed
                              ? _nextVariantCode != null
                                  ? '$_nextVariantCode Unlocked!'
                                  : 'All levels completed!'
                              : 'Need ${_passPercent}% to unlock next level',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: passed
                                ? KidsColors.success
                                : KidsColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                _bigPlayBtn('🔄 Play Again', KidsColors.areaColor, () {
                  setState(() {
                    _phase = _Phase.playing;
                    _round = 1;
                    _roundAttempts = 0;
                    _roundStars = 3;
                    _totalAttempts = 0;
                    _totalHints = 0;
                    _totalStarsEarned = 0;
                    _hintsUsedThisRound = 0;
                    _sessionStart = DateTime.now();
                  });
                  _generateRound();
                  _startTimer();
                }),
                const SizedBox(height: 12),

                // Play Next Level (only if passed and there IS a next level)
                if (passed && _nextVariantCode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _bigPlayBtn(
                      '▶ Play ${_nextVariantCode}',
                      const Color(0xFF007AFF),
                      () {
                        Get.off(
                          () => AreaGamePlayScreen(variant: _nextVariantCode!),
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                  ),

                _bigPlayBtn('🏠 Back to Hub', const Color(0xFF757575), () {
                  Get.back();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBubble(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KidsColors.textTertiary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRIANGLE PAINTER - Custom painter for triangle shapes
// ─────────────────────────────────────────────────────────────────────────────

class _TriangleOutlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _TriangleOutlinePainter({required this.color, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_TriangleOutlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  
  _TrianglePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    
    final path = Path();
    // Triangle pointing up: top vertex, bottom left, bottom right
    path.moveTo(size.width / 2, 0);           // Top vertex
    path.lineTo(0, size.height);              // Bottom left
    path.lineTo(size.width, size.height);     // Bottom right
    path.close();
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }
  
  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => oldDelegate.color != color;
}

