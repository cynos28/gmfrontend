/// Area Architect Game Screen (A-V2)
/// Design custom carpets with IRT adaptive difficulty.
/// Levels are dynamically generated based on the student's ability (theta).

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';

// Level type enum
enum _AreaLevelType { fillRectangle, formulaRectangle, mysterySide, lShapeDemo }

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

// Dynamic level configuration
class _AreaLevelConfig {
  final String name;
  final String clientRequest;
  final int roomRows;
  final int roomCols;
  final int targetWidth;
  final int targetHeight;
  final _AreaLevelType type;
  final _AreaUnit unit;

  const _AreaLevelConfig({
    required this.name,
    required this.clientRequest,
    required this.roomRows,
    required this.roomCols,
    required this.targetWidth,
    required this.targetHeight,
    required this.type,
    required this.unit,
  });

  int get targetArea => targetWidth * targetHeight;
}

// Phase for game state
enum _Phase { playing, complete }

class AreaArchitectGameScreen extends StatefulWidget {
  const AreaArchitectGameScreen({super.key});

  @override
  State<AreaArchitectGameScreen> createState() =>
      _AreaArchitectGameScreenState();
}

class _AreaArchitectGameScreenState extends State<AreaArchitectGameScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();

  // Game state
  _Phase _phase = _Phase.playing;
  int _currentLevelIndex = 0;
  final int _totalLevels = 5;
  List<_AreaLevelConfig> _levels = [];

  // Rug dimensions in grid units
  int _rugWidth = 1;
  int _rugHeight = 1;

  // For Level 4 split view
  bool _showSplit = false;

  // For drag interaction
  bool _dragging = false;

  // Per-level tracking
  int _levelAttempts = 0;
  int _levelStars = 3;
  int _totalStarsEarned = 0;
  int _totalAttempts = 0;
  int _totalHints = 0;
  int _hintsUsedThisLevel = 0;
  int _hintsAllowed = 2;
  late DateTime _sessionStart;
  bool _submitting = false;

  // IRT adaptive state
  double _irtTheta = 0.0;
  int _irtDifficultyLevel = 1;
  int _irtRoundsPlayed = 0;
  String _userId = 'student_001';
  Map<String, dynamic> _params = {};
  
  // Track used questions to avoid repetition
  final Set<String> _usedQuestions = {};

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
    _loadAndStart();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  // Init: fetch IRT state and generate levels
  Future<void> _loadAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _userId = prefs.getString('student_id') ?? 'student_001';

    // Fetch IRT state
    final irtState = await GamesApiService.getIRTState(
      studentId: _userId,
      domain: 'area',
      variant: 'A-V2',
    );
    if (!mounted) return;
    setState(() {
      _irtTheta = (irtState['theta'] as num?)?.toDouble() ?? 0.0;
      _irtDifficultyLevel =
          (irtState['difficulty_level'] as num?)?.toInt() ?? 1;
      _irtRoundsPlayed =
          (irtState['rounds_played'] as num?)?.toInt() ?? 0;
    });

    // Fetch adaptive params
    _params = await GamesApiService.getParameters(
      'area',
      studentId: _userId,
      variant: 'A-V2',
    );
    if (!mounted) return;
    _hintsAllowed = (_params['hints'] as int?) ?? 2;

    // Generate levels from IRT params
    _generateLevels();
    _resetForLevel();
  }

  /// Generate [_totalLevels] levels from IRT-adapted params
  void _generateLevels() {
    final rowRange = _params['room_rows_range'] as List<dynamic>? ?? [4, 6];
    final colRange = _params['room_cols_range'] as List<dynamic>? ?? [5, 8];
    final typeNames =
        (_params['level_types'] as List<dynamic>?)?.cast<String>() ??
            ['formulaRectangle', 'mysterySide'];

    final minRow = (rowRange[0] as num).toInt();
    final maxRow = (rowRange[1] as num).toInt();
    final minCol = (colRange[0] as num).toInt();
    final maxCol = (colRange[1] as num).toInt();
    
    // Clear used questions at start of new session
    _usedQuestions.clear();

    // Use IRT difficulty level to determine base ranges
    final diffLevel = _irtDifficultyLevel;

    final levels = <_AreaLevelConfig>[];
    for (int i = 0; i < _totalLevels; i++) {
      final typeName = typeNames[i % typeNames.length];
      final type = _parseType(typeName);
      
      // Select unit type and ranges based on difficulty
      _AreaUnit selectedUnit;
      int minW, maxW, minH, maxH;
      
      if (diffLevel <= 1) {
        // Level 1 (Easy): Only cm², small numbers
        selectedUnit = _AreaUnit.cm2;
        minW = 2;
        maxW = 4;
        minH = 2;
        maxH = 4;  // Areas: 4-16 cm²
      } else if (diffLevel == 2) {
        // Level 2 (Medium): Mostly cm², slightly larger
        selectedUnit = _rng.nextDouble() < 0.8 ? _AreaUnit.cm2 : _AreaUnit.m2;
        if (selectedUnit == _AreaUnit.cm2) {
          minW = 3;
          maxW = 6;
          minH = 3;
          maxH = 5;  // Areas: 9-30 cm²
        } else {
          minW = 2;
          maxW = 4;
          minH = 2;
          maxH = 4;  // Areas: 4-16 m²
        }
      } else if (diffLevel == 3) {
        // Level 3 (Hard): Mix of units, moderate ranges
        final unitTypes = [_AreaUnit.cm2, _AreaUnit.m2];
        selectedUnit = unitTypes[_rng.nextInt(unitTypes.length)];
        if (selectedUnit == _AreaUnit.cm2) {
          minW = 4;
          maxW = 8;
          minH = 4;
          maxH = 7;  // Areas: 16-56 cm²
        } else {
          minW = 3;
          maxW = 6;
          minH = 3;
          maxH = 5;  // Areas: 9-30 m²
        }
      } else if (diffLevel == 4) {
        // Level 4 (Expert): All units, larger ranges
        final unitTypes = _AreaUnit.values;
        selectedUnit = unitTypes[_rng.nextInt(unitTypes.length)];
        switch (selectedUnit) {
          case _AreaUnit.mm2:
            minW = 10;
            maxW = 18;
            minH = 10;
            maxH = 15;  // Areas: 100-270 mm²
            break;
          case _AreaUnit.cm2:
            minW = 5;
            maxW = 10;
            minH = 5;
            maxH = 9;   // Areas: 25-90 cm²
            break;
          case _AreaUnit.m2:
            minW = 4;
            maxW = 7;
            minH = 4;
            maxH = 6;   // Areas: 16-42 m²
            break;
        }
      } else {
        // Level 5 (Master): All units, challenging ranges
        final unitTypes = _AreaUnit.values;
        selectedUnit = unitTypes[_rng.nextInt(unitTypes.length)];
        switch (selectedUnit) {
          case _AreaUnit.mm2:
            minW = 15;
            maxW = 22;
            minH = 12;
            maxH = 18;  // Areas: 180-396 mm²
            break;
          case _AreaUnit.cm2:
            minW = 8;
            maxW = 12;
            minH = 7;
            maxH = 10;  // Areas: 56-120 cm²
            break;
          case _AreaUnit.m2:
            minW = 5;
            maxW = 8;
            minH = 5;
            maxH = 7;   // Areas: 25-56 m²
            break;
        }
      }
      
      // Generate unique question (avoid repetition)
      int tw, th;
      String questionKey;
      int attempts = 0;
      do {
        tw = minW + _rng.nextInt(max(1, maxW - minW + 1));
        th = minH + _rng.nextInt(max(1, maxH - minH + 1));
        questionKey = '${selectedUnit.name}_${tw}_${th}_${typeName}';
        attempts++;
        if (attempts > 20) {
          // If we've tried 20 times, allow duplicates
          break;
        }
      } while (_usedQuestions.contains(questionKey));
      
      _usedQuestions.add(questionKey);
      
      final rows = max(th + 1, minRow + _rng.nextInt(max(1, maxRow - minRow + 1)));
      final cols = max(tw + 1, minCol + _rng.nextInt(max(1, maxCol - minCol + 1)));

      levels.add(_AreaLevelConfig(
        name: 'Room ${i + 1}',
        clientRequest: _requestForType(type, tw, th, selectedUnit),
        roomRows: rows,
        roomCols: cols,
        targetWidth: tw,
        targetHeight: th,
        type: type,
        unit: selectedUnit,
      ));
    }
    setState(() => _levels = levels);
  }

  _AreaLevelType _parseType(String name) {
    switch (name) {
      case 'fillRectangle':
        return _AreaLevelType.fillRectangle;
      case 'formulaRectangle':
        return _AreaLevelType.formulaRectangle;
      case 'mysterySide':
        return _AreaLevelType.mysterySide;
      case 'lShapeDemo':
        return _AreaLevelType.lShapeDemo;
      default:
        return _AreaLevelType.fillRectangle;
    }
  }

  String _requestForType(_AreaLevelType type, int w, int h, _AreaUnit unit) {
    final unitStr = unit.lengthUnit;
    final areaStr = unit.display;
    switch (type) {
      case _AreaLevelType.fillRectangle:
        return 'Fill every square!';
      case _AreaLevelType.formulaRectangle:
        return 'Make a rug $w $unitStr \u00d7 $h $unitStr';
      case _AreaLevelType.mysterySide:
        return 'Area = ${w * h} $areaStr, one side = $w $unitStr\nFind the other side!';
      case _AreaLevelType.lShapeDemo:
        return 'L-shaped room! Use Split button.';
    }
  }

  _AreaLevelConfig get _level =>
      _levels.isNotEmpty ? _levels[_currentLevelIndex] : _fallbackLevel;

  static const _fallbackLevel = _AreaLevelConfig(
    name: 'Loading\u2026',
    clientRequest: '',
    roomRows: 4,
    roomCols: 5,
    targetWidth: 3,
    targetHeight: 3,
    type: _AreaLevelType.fillRectangle,
    unit: _AreaUnit.cm2,
  );

  void _resetForLevel() {
    setState(() {
      _showSplit = false;
      _dragging = false;
      _levelAttempts = 0;
      _levelStars = 3;
      _hintsUsedThisLevel = 0;
      _rugWidth = min(2, _level.roomCols);
      _rugHeight = min(2, _level.roomRows);
    });
  }

  int get _currentArea => _rugWidth * _rugHeight;
  bool get _isCorrectArea => _currentArea == _level.targetArea;

  Color get _areaColor {
    if (_currentArea == 0) return Colors.grey.shade500;
    if (_isCorrectArea) return const Color(0xFF34C759);
    if (_currentArea > _level.targetArea) return const Color(0xFFD32F2F);
    return const Color(0xFF007AFF);
  }

  void _onDragRug(Offset localPosition, Size gridSize) {
    final cellWidth = gridSize.width / _level.roomCols;
    final cellHeight = gridSize.height / _level.roomRows;
    if (cellWidth <= 0 || cellHeight <= 0) return;

    final col =
        (localPosition.dx / cellWidth).clamp(0, _level.roomCols.toDouble());
    final row =
        (localPosition.dy / cellHeight).clamp(0, _level.roomRows.toDouble());

    final newWidth = max(1, col.ceil());
    final newHeight = max(1, row.ceil());

    setState(() {
      _dragging = true;
      _rugWidth = newWidth.clamp(1, _level.roomCols);
      _rugHeight = newHeight.clamp(1, _level.roomRows);
    });
  }

  // Level completion
  void _onCheckArea() {
    setState(() => _levelAttempts++);

    if (_isCorrectArea) {
      final stars = _calcStars(_levelAttempts, _hintsUsedThisLevel);
      setState(() {
        _levelStars = stars;
        _totalStarsEarned += stars;
        _totalAttempts += _levelAttempts;
        _totalHints += _hintsUsedThisLevel;
      });
      _submitRoundToIRT(true, stars);
      _showWinDialog();
    } else {
      if (_levelAttempts >= 2) {
        setState(() => _levelStars = max(1, _levelStars - 1));
      }
      if (_levelAttempts >= 3) {
        _submitRoundToIRT(false, 0);
      }
      _showTryAgainSnack();
    }
  }

  int _calcStars(int attempts, int hints) {
    if (attempts == 1 && hints == 0) return 3;
    if (attempts <= 2 && hints <= 1) return 2;
    return 1;
  }

  void _goNextLevel() {
    if (_currentLevelIndex < _levels.length - 1) {
      setState(() => _currentLevelIndex++);
      _resetForLevel();
    } else {
      _completeGame();
    }
  }

  Future<void> _completeGame() async {
    setState(() {
      _phase = _Phase.complete;
      _submitting = true;
    });

    final sessionDuration =
        DateTime.now().difference(_sessionStart).inSeconds.toDouble();

    try {
      await GamesApiService.evaluateSession(
        userId: _userId,
        domain: 'area',
        attempts: _totalLevels > 0
            ? (_totalAttempts / _totalLevels).round()
            : _totalAttempts,
        time: sessionDuration,
        targetTime: 60.0 * _totalLevels,
        hints: _totalHints,
      );
    } catch (_) {}

    if (mounted) setState(() => _submitting = false);
  }

  /// Fire-and-forget: send round result to backend IRT engine
  Future<void> _submitRoundToIRT(bool correct, int stars) async {
    try {
      final result = await GamesApiService.submitRoundResult(
        studentId: _userId,
        domain: 'area',
        variant: 'A-V2',
        correct: correct,
        attempts: _levelAttempts,
        hintsUsed: _hintsUsedThisLevel,
        timeSeconds: 0,
        starsEarned: stars,
      );
      if (!mounted) return;
      setState(() {
        _irtTheta = (result['theta'] as num?)?.toDouble() ?? _irtTheta;
        _irtDifficultyLevel =
            (result['difficulty_level'] as num?)?.toInt() ?? _irtDifficultyLevel;
        _irtRoundsPlayed =
            (result['rounds_played'] as num?)?.toInt() ?? _irtRoundsPlayed;
      });
      final nextParams = result['next_params'] as Map<String, dynamic>?;
      if (nextParams != null) {
        _params.addAll(nextParams);
        _hintsAllowed = (_params['hints'] as int?) ?? _hintsAllowed;
      }
    } catch (_) {}
  }

  void _useHint() {
    if (_hintsUsedThisLevel >= _hintsAllowed) {
      Get.snackbar('No more hints!', 'You used all your hints for this room',
          backgroundColor: KidsColors.warning,
          colorText: KidsColors.textPrimary,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 16);
      return;
    }
    setState(() => _hintsUsedThisLevel++);

    final level = _level;
    String hint;
    switch (level.type) {
      case _AreaLevelType.fillRectangle:
        hint =
            'Drag the rug to cover all ${level.targetArea} squares!\nRows \u00d7 Columns = Area';
      case _AreaLevelType.formulaRectangle:
        hint =
            'Make the rug ${level.targetWidth} ${level.unit.lengthUnit} wide and ${level.targetHeight} ${level.unit.lengthUnit} tall.\n${level.targetWidth} \u00d7 ${level.targetHeight} = ${level.targetArea} ${level.unit.display}';
      case _AreaLevelType.mysterySide:
        hint =
            'Area = ${level.targetArea} ${level.unit.display}, one side = ${level.targetWidth} ${level.unit.lengthUnit}\n${level.targetArea} \u00f7 ${level.targetWidth} = ${level.targetHeight} ${level.unit.lengthUnit}';
      case _AreaLevelType.lShapeDemo:
        hint =
            'Try splitting the L-shape into rectangles.\nAdd their areas together!';
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
              child: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
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
            style: const TextStyle(
                fontSize: 16, height: 1.5, color: Color(0xFF5D4037))),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: KidsColors.areaColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Get.back(),
            child: const Text('Got it!',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    if (_levels.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0FFF4),
        body: Center(
          child: CircularProgressIndicator(color: KidsColors.areaColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _phase == _Phase.complete
                  ? _buildCompleteScreen()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLevelCard(),
                          const SizedBox(height: 16),
                          _buildClientRequest(),
                          const SizedBox(height: 16),
                          _buildRoomWithRug(),
                          const SizedBox(height: 16),
                          _buildAreaPanel(),
                          if (_level.type == _AreaLevelType.lShapeDemo) ...[
                            const SizedBox(height: 12),
                            _buildSplitFormula(_level.targetArea),
                          ],
                          const SizedBox(height: 20),
                          _buildBottomButtons(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Area Architect',
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Room ${_currentLevelIndex + 1} of $_totalLevels',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildIRTBadge(),
                      ],
                    ),
                  ],
                ),
              ),
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
                  child: const Center(
                      child: Icon(Icons.lightbulb_outline, color: Colors.amber, size: 22)),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -_bounceAnim.value),
                  child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIRTBadge() {
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF9C27B0)
    ];
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

  Widget _buildLevelCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: KidsColors.areaColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.square_foot, color: KidsColors.areaColor, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _level.name,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: KidsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Room: ${_level.roomCols} \u00d7 ${_level.roomRows} squares',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: KidsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Stars for this level
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Icon(
                i < _levelStars
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: i < _levelStars
                    ? const Color(0xFFFFD700)
                    : Colors.grey.shade300,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientRequest() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.description_outlined, color: Colors.brown, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _level.clientRequest,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: Colors.brown.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomWithRug() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB2DFDB), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Room Blueprint',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: KidsColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Drag from top-left corner!',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  color: KidsColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: _level.roomCols / max(1, _level.roomRows),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onPanStart: (d) => _onDragRug(d.localPosition, gridSize),
                  onPanUpdate: (d) => _onDragRug(d.localPosition, gridSize),
                  onPanEnd: (_) => setState(() => _dragging = false),
                  child: Stack(
                    children: [
                      _buildGridBackground(),
                      _buildRugOverlay(),
                      _buildEdgeLabels(),
                      if (_currentArea > _level.targetArea)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 16, color: Color(0xFFD32F2F)),
                                const SizedBox(width: 4),
                                Text('Rug is bunching up!',
                                    style: GoogleFonts.fredoka(
                                        fontSize: 11,
                                        color: const Color(0xFFD32F2F))),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return LayoutBuilder(builder: (context, constraints) {
      final cellW = constraints.maxWidth / _level.roomCols;
      final cellH = constraints.maxHeight / _level.roomRows;
      return CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _GridPainter(
            rows: _level.roomRows,
            cols: _level.roomCols,
            cellWidth: cellW,
            cellHeight: cellH),
      );
    });
  }

  Widget _buildRugOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final cellW = constraints.maxWidth / _level.roomCols;
      final cellH = constraints.maxHeight / _level.roomRows;
      return Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: cellW * _rugWidth,
          height: cellH * _rugHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7E57C2), Color(0xFFE1BEE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.shade900, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: CustomPaint(
              painter: _RugPatternPainter(cols: _rugWidth, rows: _rugHeight)),
        ),
      );
    });
  }

  Widget _buildEdgeLabels() {
    return Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: LayoutBuilder(builder: (context, constraints) {
            final cellW = constraints.maxWidth / _level.roomCols;
            return Row(
              children: List.generate(_rugWidth, (i) => SizedBox(
                width: cellW,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
            );
          }),
        ),
        Positioned(
          top: 0, bottom: 0, left: 0,
          child: LayoutBuilder(builder: (context, constraints) {
            final cellH = constraints.maxHeight / _level.roomRows;
            return Column(
              children: List.generate(_rugHeight, (i) => SizedBox(
                height: cellH,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAreaPanel() {
    final targetArea = _level.targetArea;
    final unit = _level.unit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Target Area: $targetArea ${unit.display}',
                style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade800)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildFormulaBadge(
                      '$_rugWidth \u00d7 $_rugHeight = $_currentArea ${unit.display}',
                      _isCorrectArea
                          ? const Color(0xFF2E7D32)
                          : _currentArea > targetArea
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: GoogleFonts.fredoka(
              fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildSplitFormula(int targetArea) {
    final totalWidth = _level.targetWidth;
    final height = _level.targetHeight;
    final b = totalWidth > 3 ? 2 : 1;
    final a = totalWidth - b;
    final leftArea = a * height;
    final rightArea = b * height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          ElevatedButton.icon(
            onPressed: () => setState(() => _showSplit = !_showSplit),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7043),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.content_cut_rounded, size: 18),
            label: Text(_showSplit ? 'Hide Split' : 'Split the Rug',
                style: GoogleFonts.fredoka(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          crossFadeState:
              _showSplit ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 220),
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$height \u00d7 ($a + $b) = ($height \u00d7 $a) + ($height \u00d7 $b)',
                  style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: KidsColors.textPrimary)),
              const SizedBox(height: 4),
              Text('$leftArea + $rightArea = $targetArea',
                  style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32))),
            ],
          ),
          secondChild: Text(
              'Tap "Split the Rug" to break the area into two smaller rectangles.',
              style: GoogleFonts.fredoka(
                  fontSize: 13, color: KidsColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final correct = _isCorrectArea;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _resetForLevel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: KidsColors.textPrimary,
              side: const BorderSide(color: Color(0xFFB0BEC5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: Text('Reset Rug',
                style: GoogleFonts.fredoka(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _onCheckArea,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  correct ? const Color(0xFF43A047) : KidsColors.areaColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(correct ? 'Perfect! \u2714' : 'Check Area',
                style: GoogleFonts.fredoka(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\ud83c\udf1f Style Stars Earned!',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text('Your carpet fits the room perfectly!',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      i < _levelStars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i < _levelStars
                          ? const Color(0xFFFFD700)
                          : Colors.grey.shade300,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _resetForLevel();
                      },
                      child: const Text('Replay'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _goNextLevel();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KidsColors.areaColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                          _currentLevelIndex < _levels.length - 1
                              ? 'Next Room'
                              : 'Finish!'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTryAgainSnack() {
    final over = _currentArea > _level.targetArea;
    final message = over
        ? 'Your rug is too big \u2013 it\'s bunching against the walls!'
        : 'Your rug is too small \u2013 there are still empty squares!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            over ? const Color(0xFFD32F2F) : KidsColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Complete screen
  Widget _buildCompleteScreen() {
    if (_submitting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: KidsColors.areaColor),
            SizedBox(height: 16),
            Text('Saving your progress\u2026',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32))),
          ],
        ),
      );
    }

    final maxStars = _totalLevels * 3;
    final percent =
        maxStars > 0 ? (_totalStarsEarned / maxStars * 100).round() : 0;

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
                const Icon(Icons.celebration, color: Color(0xFFFFD700), size: 56),
                const SizedBox(height: 16),
                const Text('All Rooms Done!',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32))),
                const SizedBox(height: 8),
                Text('A-V2 \u2022 Area Architect',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KidsColors.textTertiary)),
                const SizedBox(height: 24),

                // Stats grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBubble(Icons.star_rounded, '$_totalStarsEarned/$maxStars',
                        'Stars', const Color(0xFFFFD700)),
                    _statBubble(Icons.track_changes, '$percent%', 'Score',
                        KidsColors.success),
                    _statBubble(Icons.refresh, '$_totalAttempts', 'Attempts',
                        const Color(0xFF4285F4)),
                  ],
                ),
                const SizedBox(height: 16),

                // IRT stats
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _irtStatChip(
                          'Level', '$_irtDifficultyLevel', const Color(0xFF9C27B0)),
                      _irtStatChip('Ability', _irtTheta.toStringAsFixed(2),
                          const Color(0xFF1565C0)),
                      _irtStatChip(
                          'Rounds', '$_irtRoundsPlayed', const Color(0xFF2E7D32)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Play Again
                Material(
                  color: KidsColors.areaColor,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  shadowColor: KidsColors.areaColor.withOpacity(0.35),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _phase = _Phase.playing;
                        _currentLevelIndex = 0;
                        _totalStarsEarned = 0;
                        _totalAttempts = 0;
                        _totalHints = 0;
                        _sessionStart = DateTime.now();
                      });
                      _generateLevels();
                      _resetForLevel();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: const Text('\ud83d\udd04 Play Again!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to hub
                Material(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Get.back(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Text('\u2190 Back to Games',
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
          ),
        ],
      ),
    );
  }

  Widget _statBubble(IconData icon, String value, String label, Color color) {
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
              Icon(icon, color: color, size: 20),
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
}

// Custom painters
class _GridPainter extends CustomPainter {
  final int rows, cols;
  final double cellWidth, cellHeight;

  _GridPainter(
      {required this.rows,
      required this.cols,
      required this.cellWidth,
      required this.cellHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0F2F1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(18)),
        paint);
    final gridPaint = Paint()
      ..color = const Color(0xFFB2DFDB)
      ..strokeWidth = 1.1;
    for (int c = 0; c <= cols; c++) {
      final x = c * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int r = 0; r <= rows; r++) {
      final y = r * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter o) =>
      rows != o.rows ||
      cols != o.cols ||
      cellWidth != o.cellWidth ||
      cellHeight != o.cellHeight;
}

class _RugPatternPainter extends CustomPainter {
  final int rows, cols;
  _RugPatternPainter({required this.rows, required this.cols});

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols;
    final ch = size.height / rows;
    final p = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.2;
    for (int r = 0; r <= rows; r++) {
      final y = r * ch;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    for (int c = 0; c <= cols; c++) {
      final x = c * cw;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant _RugPatternPainter o) =>
      rows != o.rows || cols != o.cols;
}
