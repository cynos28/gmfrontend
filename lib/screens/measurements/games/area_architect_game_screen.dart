import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/utils/kids_theme.dart';

enum _AreaLevelType { fillRectangle, formulaRectangle, mysterySide, lShapeDemo }

class _AreaLevelConfig {
  final String name;
  final String clientRequest;
  final int roomRows;
  final int roomCols;
  final int targetWidth;
  final int targetHeight;
  final _AreaLevelType type;

  const _AreaLevelConfig({
    required this.name,
    required this.clientRequest,
    required this.roomRows,
    required this.roomCols,
    required this.targetWidth,
    required this.targetHeight,
    required this.type,
  });

  int get targetArea => targetWidth * targetHeight;
}

const List<_AreaLevelConfig> _levels = [
  _AreaLevelConfig(
    name: 'Level 1: Cozy Starter Room',
    clientRequest: 'Fill every square!',
    roomRows: 4,
    roomCols: 5,
    targetWidth: 4,
    targetHeight: 3,
    type: _AreaLevelType.fillRectangle,
  ),
  _AreaLevelConfig(
    name: 'Level 2: Exact Measurements',
    clientRequest: 'Make a rug 6 units × 3 units',
    roomRows: 5,
    roomCols: 8,
    targetWidth: 6,
    targetHeight: 3,
    type: _AreaLevelType.formulaRectangle,
  ),
  _AreaLevelConfig(
    name: 'Level 3: Mystery Side',
    clientRequest: 'Area = 20, one side = 4\nFind the other side!',
    roomRows: 5,
    roomCols: 7,
    targetWidth: 5,
    targetHeight: 4,
    type: _AreaLevelType.mysterySide,
  ),
  _AreaLevelConfig(
    name: 'Level 4: L‑Shaped Room',
    clientRequest: 'L-shaped room! Use Split button.',
    roomRows: 6,
    roomCols: 8,
    targetWidth: 7,
    targetHeight: 4,
    type: _AreaLevelType.lShapeDemo,
  ),
];

class AreaArchitectGameScreen extends StatefulWidget {
  const AreaArchitectGameScreen({super.key});

  @override
  State<AreaArchitectGameScreen> createState() => _AreaArchitectGameScreenState();
}

class _AreaArchitectGameScreenState extends State<AreaArchitectGameScreen>
    with SingleTickerProviderStateMixin {
  int _currentLevelIndex = 0;

  // Rug dimensions in grid units
  int _rugWidth = 1;
  int _rugHeight = 1;

  // For Level 4 split view
  bool _showSplit = false;

  // For drag interaction
  bool _dragging = false;

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
    _resetForLevel();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  _AreaLevelConfig get _level => _levels[_currentLevelIndex];

  void _resetForLevel() {
    setState(() {
      _showSplit = false;
      _dragging = false;
      // Start rug as 1×1 in top‑left
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

    final col = (localPosition.dx / cellWidth).clamp(0, _level.roomCols.toDouble());
    final row = (localPosition.dy / cellHeight).clamp(0, _level.roomRows.toDouble());

    final newWidth = max(1, col.ceil());
    final newHeight = max(1, row.ceil());

    setState(() {
      _dragging = true;
      _rugWidth = newWidth.clamp(1, _level.roomCols);
      _rugHeight = newHeight.clamp(1, _level.roomRows);
    });
  }

  void _goNextLevel() {
    if (_currentLevelIndex < _levels.length - 1) {
      setState(() {
        _currentLevelIndex++;
      });
      _resetForLevel();
    } else {
      // Finished all levels – simple celebration snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You completed all Area Architect levels! 🎉'),
          backgroundColor: KidsColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
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
          colors: [
            Color(0xFF7C4DFF),
            Color(0xFF512DA8),
          ],
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
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
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
                    Text(
                      'Custom Carpets Studio',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -_bounceAnim.value),
                  child: const Text(
                    '🧶',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ],
          ),
        ],
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
              child: Text(
                '📐',
                style: TextStyle(fontSize: 28),
              ),
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
                  'Room: ${_level.roomCols} × ${_level.roomRows} squares',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: KidsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_currentLevelIndex + 1}/${_levels.length}',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KidsColors.areaColor,
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
          const Text('📜', style: TextStyle(fontSize: 26)),
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
                'Drag the rug from the top‑left corner!',
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
                final gridSize = Size(constraints.maxWidth, constraints.maxHeight);

                return GestureDetector(
                  onPanStart: (details) =>
                      _onDragRug(details.localPosition, gridSize),
                  onPanUpdate: (details) =>
                      _onDragRug(details.localPosition, gridSize),
                  onPanEnd: (_) {
                    setState(() {
                      _dragging = false;
                    });
                  },
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
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Color(0xFFD32F2F),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Rug is bunching up!',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 11,
                                    color: const Color(0xFFD32F2F),
                                  ),
                                ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / _level.roomCols;
        final cellHeight = constraints.maxHeight / _level.roomRows;

        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _GridPainter(
            rows: _level.roomRows,
            cols: _level.roomCols,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
          ),
        );
      },
    );
  }

  Widget _buildRugOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / _level.roomCols;
        final cellHeight = constraints.maxHeight / _level.roomRows;

        return Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: cellWidth * _rugWidth,
            height: cellHeight * _rugHeight,
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
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _RugPatternPainter(
                cols: _rugWidth,
                rows: _rugHeight,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEdgeLabels() {
    final ticksTop = List.generate(_rugWidth, (i) => i + 1);
    final ticksSide = List.generate(_rugHeight, (i) => i + 1);

    return Stack(
      children: [
        // Top edge labels
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / _level.roomCols;
              return Row(
                children: List.generate(_rugWidth, (i) {
                  return SizedBox(
                    width: cellWidth,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${ticksTop[i]}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        // Left edge labels
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellHeight = constraints.maxHeight / _level.roomRows;
              return Column(
                children: List.generate(_rugHeight, (i) {
                  return SizedBox(
                    height: cellHeight,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${ticksSide[i]}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAreaPanel() {
    final targetArea = _level.targetArea;

    return Container(
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
          Text(
            'Target Area: $targetArea units²',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _level.clientRequest,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.brown.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaRow({
    required int a,
    required int b,
    required int target,
    bool knownAIsGiven = false,
  }) {
    final product = a * b;
    final correct = product == target;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            knownAIsGiven ? '$a' : '$a',
            style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          const Text('×'),
          const SizedBox(width: 4),
          Text(
            '$b',
            style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          const Text('='),
          const SizedBox(width: 4),
          Text(
            '$product',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: correct ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            correct ? '✓' : '',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    ).animate(target: 1).scale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildSplitFormula(int targetArea) {
    // A simple demo split: use targetWidth = a + b with b = 2 (if possible)
    final totalWidth = _level.targetWidth;
    final height = _level.targetHeight;
    final b = totalWidth > 3 ? 2 : 1;
    final a = totalWidth - b;

    final leftArea = a * height;
    final rightArea = b * height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showSplit = !_showSplit;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.content_cut_rounded, size: 18),
              label: Text(
                _showSplit ? 'Hide Split' : 'Split the Rug',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          crossFadeState:
              _showSplit ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 220),
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '8 × (5 + 2) = (8 × 5) + (8 × 2)',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: KidsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$height × ($a + $b) = ($height × $a) + ($height × $b)',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: KidsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$leftArea + $rightArea = $targetArea',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          secondChild: Text(
            'Tap “Split the Rug” to see how one big area can be broken into two smaller ones.',
            style: GoogleFonts.fredoka(
              fontSize: 13,
              color: KidsColors.textSecondary,
            ),
          ),
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
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Reset Rug',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (correct) {
                _showWinDialog();
              } else {
                _showTryAgainSnack();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: correct ? const Color(0xFF43A047) : KidsColors.areaColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              correct ? 'Perfect! ✔️' : 'Check Area',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🌟 Style Stars Earned!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your carpet fits the room perfectly!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Text('⭐', style: TextStyle(fontSize: 26)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetForLevel();
                      },
                      child: const Text('Replay'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _goNextLevel();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KidsColors.areaColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Next Room'),
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
        ? 'Your rug is too big – it’s bunching against the walls!'
        : 'Your rug is too small – there are still empty squares!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: over ? const Color(0xFFD32F2F) : KidsColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double cellWidth;
  final double cellHeight;

  _GridPainter({
    required this.rows,
    required this.cols,
    required this.cellWidth,
    required this.cellHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0F2F1)
      ..style = PaintingStyle.fill;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(18),
      ),
      paint,
    );

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
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return rows != oldDelegate.rows ||
        cols != oldDelegate.cols ||
        cellWidth != oldDelegate.cellWidth ||
        cellHeight != oldDelegate.cellHeight;
  }
}

class _RugPatternPainter extends CustomPainter {
  final int rows;
  final int cols;

  _RugPatternPainter({required this.rows, required this.cols});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.2;

    // Simple woven pattern
    for (int r = 0; r <= rows; r++) {
      final y = r * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), borderPaint);
    }
    for (int c = 0; c <= cols; c++) {
      final x = c * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RugPatternPainter oldDelegate) {
    return rows != oldDelegate.rows || cols != oldDelegate.cols;
  }
}

