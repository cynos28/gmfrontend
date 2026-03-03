/// Area Game Play Screen
/// Renders area game variants (A-V1, A-V3, A-V4) with kids-friendly UI,
/// adaptive difficulty, and backend integration.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { playing, wrongAnswer, showResult, complete }

/// Per-variant target times (seconds per round)
const Map<String, int> _targetSeconds = {
  'A-V1': 60,
  'A-V3': 90,
  'A-V4': 90,
};

/// L-shape definition for V4
class _LShape {
  final List<List<bool>> grid; // true = filled
  final int totalArea;
  final List<Rect> rectangles; // valid split rectangles
  _LShape({required this.grid, required this.totalArea, required this.rectangles});
}



// ─────────────────────────────────────────────────────────────────────────────
// WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class AreaGamePlayScreen extends StatefulWidget {
  final String variant; // 'A-V1' | 'A-V3' | 'A-V4'
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

  // ─── V3 state: Fill the Shape (Drag & Drop) ───────────────────────────────
  int _v3GridW = 0;
  int _v3GridH = 0;
  List<List<bool>> _v3Silhouette = [];
  List<List<int>> _v3Board = [];
  int _v3TargetArea = 0;
  int _v3FilledArea = 0;
  String _v3ShapeName = '';
  int _v3HintsUsed = 0;
  int _v3PieceIdCounter = 1;
  List<Map<String, dynamic>> _v3Pieces = [];
  int _v3DraggingIndex = -1;
  int? _v3HoverX;
  int? _v3HoverY;
  bool _v3CanPlace = false;

  // ─── V4 state: L‑Shaped Rooms (Distributive Property) ─────────────────────
  _LShape? _v4Shape;
  List<int> _v4PartAreas = [];
  List<int> _v4Choices = [];
  int _v4SelectedTotal = 0;

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
    _params = await GamesApiService.getParameters('area');
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
    final maxSize = (_params['max_rect_size'] as num?)?.toInt() ?? 6;
    final minSize = (_params['min_rect_size'] as num?)?.toInt() ?? 2;

    final w = minSize + _rng.nextInt(maxSize - minSize + 1);
    final h = minSize + _rng.nextInt(maxSize - minSize + 1);
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
      _v1ShowGrid = gridVisible;
      _v1GridW = gw;
      _v1GridH = gh;
      _v1Grid = List.generate(gh, (_) => List.generate(gw, (_) => false));
      _v1FilledCount = 0;
    });
  }

  // ─── V3 generation: Fill the Shape (Drag & Drop) ───────────────────────

  void _genV3() {


    // Generate a kid-friendly silhouette to fill with pieces
    final shapes = ['house', 'rocket', 'tree', 'robot', 'car', 'boat'];
    final shapeType = shapes[_rng.nextInt(shapes.length)];
    
    late List<List<bool>> silhouette;
    late String shapeName;
    
    switch (shapeType) {
      case 'house':
        silhouette = _generateHouseSilhouette();
        shapeName = 'House 🏠';
        break;
      case 'rocket':
        silhouette = _generateRocketSilhouette();
        shapeName = 'Rocket 🚀';
        break;
      case 'tree':
        silhouette = _generateTreeSilhouette();
        shapeName = 'Tree 🌳';
        break;
      case 'robot':
        silhouette = _generateRobotSilhouette();
        shapeName = 'Robot 🤖';
        break;
      case 'car':
        silhouette = _generateCarSilhouette();
        shapeName = 'Car 🚗';
        break;
      default:
        silhouette = _generateBoatSilhouette();
        shapeName = 'Boat ⛵';
    }
    
    // Count target area
    int targetArea = 0;
    for (final row in silhouette) {
      for (final cell in row) {
        if (cell) targetArea++;
      }
    }
    
    // Generate piece tray based on difficulty
    final pieces = _generateV3Pieces(targetArea);
    
    setState(() {
      _v3GridH = silhouette.length;
      _v3GridW = silhouette.isNotEmpty ? silhouette[0].length : 8;
      _v3Silhouette = silhouette;
      _v3Board = List.generate(_v3GridH, (_) => List.generate(_v3GridW, (_) => 0));
      _v3TargetArea = targetArea;
      _v3FilledArea = 0;
      _v3ShapeName = shapeName;
      _v3HintsUsed = 0;
      _v3PieceIdCounter = 1;
      _v3Pieces = pieces;
      _v3DraggingIndex = -1;
      _v3HoverX = null;
      _v3HoverY = null;
      _v3CanPlace = false;
    });
  }
  
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

  void _genV4() {
    final maxParts = (_params['max_parts'] as num?)?.toInt() ?? 2;
    
    // Generate an L-shape or T-shape
    final shape = _generateLShape(maxParts);

    // Create choices (correct total + decoys)
    final decoys = <int>{};
    while (decoys.length < 3) {
      final d = (shape.totalArea + (_rng.nextInt(10) - 5)).clamp(4, 60);
      if (d != shape.totalArea) decoys.add(d);
    }
    final choices = [shape.totalArea, ...decoys]..shuffle(_rng);

    setState(() {
      _v4Shape = shape;
      _v4PartAreas = shape.rectangles.map((r) => (r.width * r.height).toInt()).toList();
      _v4Choices = choices;
      _v4SelectedTotal = 0;
    });
  }

  _LShape _generateLShape(int maxParts) {
    // Create a simple L-shape on a grid
    final baseW = 3 + _rng.nextInt(3); // 3-5
    final baseH = 2 + _rng.nextInt(2); // 2-3
    final extW = 2 + _rng.nextInt(2);  // 2-3
    final extH = 2 + _rng.nextInt(2);  // 2-3

    final totalW = baseW;
    final totalH = baseH + extH;
    final grid = List.generate(totalH, (_) => List.generate(totalW, (_) => false));

    // Bottom rectangle (full width)
    for (int y = extH; y < totalH; y++) {
      for (int x = 0; x < totalW; x++) {
        grid[y][x] = true;
      }
    }
    // Top-left extension
    for (int y = 0; y < extH; y++) {
      for (int x = 0; x < extW; x++) {
        grid[y][x] = true;
      }
    }

    int total = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell) total++;
      }
    }

    final rects = [
      Rect.fromLTWH(0, 0, extW.toDouble(), extH.toDouble()),
      Rect.fromLTWH(0, extH.toDouble(), totalW.toDouble(), baseH.toDouble()),
    ];

    return _LShape(grid: grid, totalArea: total, rectangles: rects);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANSWER HANDLING
  // ─────────────────────────────────────────────────────────────────────────

  void _submitV1Check() {
    if (_phase != _Phase.playing) return;
    setState(() => _roundAttempts++);
    if (_v1FilledCount == _v1Correct) {
      _roundCorrect('🟩 Correct! ${_v1Width} × ${_v1Height} = $_v1Correct cm²!');
    } else if (_v1FilledCount < _v1Correct) {
      _roundWrong('Not enough tiles! ${_v1Width} × ${_v1Height} = ? 🔢');
    } else {
      _roundWrong('Too many tiles! You placed $_v1FilledCount but need $_v1Correct 🔢');
    }
  }



  void _submitV3() {
    if (_phase != _Phase.playing) return;
    setState(() => _roundAttempts++);

    // Check if shape is completely filled
    if (_v3FilledArea < _v3TargetArea) {
      final remaining = _v3TargetArea - _v3FilledArea;
      _roundWrong('Not finished! Fill $remaining more squares! 🧩');
      return;
    }

    // Check for gaps (any silhouette cell not filled)
    bool hasGaps = false;
    for (int y = 0; y < _v3GridH; y++) {
      for (int x = 0; x < _v3GridW; x++) {
        if (_v3Silhouette[y][x] && _v3Board[y][x] == 0) {
          hasGaps = true;
          break;
        }
      }
      if (hasGaps) break;
    }
    
    if (hasGaps) {
      _roundWrong('There are empty holes! Fill all the white spaces! 🕳️');
      return;
    }

    // Calculate stars based on hints used, piece count
    int stars = 3;
    if (_v3HintsUsed >= 2 || _roundAttempts > 3) {
      stars = 1;
    } else if (_v3HintsUsed == 1 || _roundAttempts > 1) {
      stars = 2;
    }

    _roundCorrect('🎉 You filled the $_v3ShapeName!\nTotal Area = $_v3TargetArea square units!');
  }

  /// Check if piece can be placed at position
  bool _canPlaceV3Piece(int pieceIndex, int gridX, int gridY) {
    if (pieceIndex < 0 || pieceIndex >= _v3Pieces.length) return false;
    final piece = _v3Pieces[pieceIndex];
    final cells = piece['cells'] as List<List<int>>;
    
    for (final cell in cells) {
      final x = gridX + cell[0];
      final y = gridY + cell[1];
      
      // Check bounds
      if (x < 0 || x >= _v3GridW || y < 0 || y >= _v3GridH) return false;
      
      // Check if inside silhouette
      if (!_v3Silhouette[y][x]) return false;
      
      // Check if not already occupied
      if (_v3Board[y][x] != 0) return false;
    }
    return true;
  }
  
  /// Place piece on board
  void _placeV3Piece(int pieceIndex, int gridX, int gridY) {
    if (!_canPlaceV3Piece(pieceIndex, gridX, gridY)) return;
    
    final piece = _v3Pieces[pieceIndex];
    final cells = piece['cells'] as List<List<int>>;
    final pieceId = _v3PieceIdCounter++;
    final area = piece['area'] as int;
    
    setState(() {
      for (final cell in cells) {
        final x = gridX + cell[0];
        final y = gridY + cell[1];
        _v3Board[y][x] = pieceId;
      }
      _v3FilledArea += area;
      _v3Pieces.removeAt(pieceIndex);
      _v3DraggingIndex = -1;
      _v3HoverX = null;
      _v3HoverY = null;
      _v3CanPlace = false;
    });
  }
  
  /// Remove piece from board (tap to remove)
  void _removeV3Piece(int gridX, int gridY) {
    if (_phase != _Phase.playing) return;
    final pieceId = _v3Board[gridY][gridX];
    if (pieceId == 0) return;
    
    // Find all cells with this piece ID
    final cells = <List<int>>[];
    int minX = _v3GridW, minY = _v3GridH;
    
    for (int y = 0; y < _v3GridH; y++) {
      for (int x = 0; x < _v3GridW; x++) {
        if (_v3Board[y][x] == pieceId) {
          cells.add([x, y]);
          minX = min(minX, x);
          minY = min(minY, y);
        }
      }
    }
    
    // Reconstruct piece cells relative to origin
    final relativeCells = cells.map((c) => [c[0] - minX, c[1] - minY]).toList();
    final area = cells.length;
    
    // Determine piece color (cycle through)
    final colors = [
      const Color(0xFFFF6B6B), const Color(0xFF4ECDC4), const Color(0xFFFFE66D),
      const Color(0xFF95E1D3), const Color(0xFFF38181), const Color(0xFFAA96DA),
    ];
    
    setState(() {
      // Remove from board
      for (final cell in cells) {
        _v3Board[cell[1]][cell[0]] = 0;
      }
      _v3FilledArea -= area;
      
      // Add back to pieces
      _v3Pieces.add({
        'cells': relativeCells,
        'area': area,
        'color': colors[_rng.nextInt(colors.length)],
        'name': _getPieceName(relativeCells),
      });
    });
  }
  
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
  void _showV3Hint() {
    setState(() => _v3HintsUsed++);
    
    // Find empty cells in silhouette
    int emptyCount = 0;
    for (int y = 0; y < _v3GridH; y++) {
      for (int x = 0; x < _v3GridW; x++) {
        if (_v3Silhouette[y][x] && _v3Board[y][x] == 0) {
          emptyCount++;
        }
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💡 $emptyCount empty squares left! Fill them with pieces.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Clear all pieces from V3 board
  void _clearV3Board() {
    setState(() {
      // Return all pieces to tray
      final colors = [
        const Color(0xFFFF6B6B), const Color(0xFF4ECDC4), const Color(0xFFFFE66D),
        const Color(0xFF95E1D3), const Color(0xFFF38181), const Color(0xFFAA96DA),
      ];
      
      // Clear board
      _v3Board = List.generate(_v3GridH, (_) => List.generate(_v3GridW, (_) => 0));
      _v3FilledArea = 0;
      _v3PieceIdCounter = 1;
      
      // Regenerate pieces
      _v3Pieces = _generateV3Pieces(_v3TargetArea);
    });
  }

  void _submitV4(int choice) {
    if (_phase != _Phase.playing) return;
    final shape = _v4Shape;
    if (shape == null) return;
    setState(() => _roundAttempts++);
    if (choice == shape.totalArea) {
      _roundCorrect('✂️ Correct! ${_v4PartAreas.join(' + ')} = ${shape.totalArea} cm²!');
    } else {
      _roundWrong('Split the shape and add the areas! ✂️➕');
    }
  }

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
                    Text(
                      'Round $_round of $_totalRounds',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8)),
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
        return '🟩 Tile Rectangle';
      case 'A-V3':
        return '📐 Build to Target';
      case 'A-V4':
        return '✂️ Split & Add';
      default:
        return '📐 Area Game';
    }
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
                _dimensionBadge('${_v1Width} cm', const Color(0xFF4285F4)),
                const Text(' × ',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF424242))),
                _dimensionBadge('${_v1Height} cm', const Color(0xFF34C759)),
                const Text(' = ',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF424242))),
                _dimensionBadge('? cm²', const Color(0xFFFF9500)),
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
                      Text(
                        'Target Area: $_v1Correct units²',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.brown.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fill every square!',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.brown.shade600,
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

          // Grid size info
          Text(
            'Grid: ${_v1GridW} × ${_v1GridH} = ${_v1GridW * _v1GridH} tiles available',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KidsColors.textTertiary,
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

  Widget _buildV3() {
    if (_v3Silhouette.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final isFilled = _v3FilledArea >= _v3TargetArea;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Instruction
          _instructionChip('🧩 Drag pieces to fill the shape!'),
          const SizedBox(height: 12),

          // Header with shape name and area meter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6BCB77), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Fill the $_v3ShapeName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Area meter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Area: $_v3FilledArea / $_v3TargetArea',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'sq units',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width * 0.85 * 
                      (_v3TargetArea > 0 ? _v3FilledArea / _v3TargetArea : 0.0).clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6BCB77), Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Center(
                  child: Text(
                    '${((_v3FilledArea / max(_v3TargetArea, 1)) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shape grid (drop target)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: KidsShadows.soft,
              border: Border.all(
                color: _v3CanPlace ? Colors.green.shade400 : Colors.grey.shade300,
                width: _v3CanPlace ? 3 : 1,
              ),
            ),
            child: _buildV3Grid(),
          ),
          const SizedBox(height: 12),

          // Piece tray
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🧩 Piece Tray (drag to fill):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: _v3Pieces.isEmpty
                      ? const Center(
                          child: Text('All pieces used!', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _v3Pieces.length,
                          itemBuilder: (context, index) => _buildV3PieceItem(index),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _bigPlayBtn(
                  '🗑 Clear All',
                  Colors.grey,
                  _v3FilledArea > 0 ? _clearV3Board : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _bigPlayBtn(
                  '💡 Hint',
                  Colors.amber,
                  _showV3Hint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: _bigPlayBtn(
              isFilled ? '✅ Check' : '🧩 Keep filling...',
              isFilled ? const Color(0xFF4CAF50) : Colors.grey.shade400,
              isFilled ? _submitV3 : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Build V3 grid (silhouette with placed pieces)
  Widget _buildV3Grid() {
    final cellSize = min(280.0 / _v3GridW, 36.0);

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        return true;
      },
      onAcceptWithDetails: (details) {
        if (_v3HoverX != null && _v3HoverY != null && _v3CanPlace) {
          _placeV3Piece(details.data, _v3HoverX!, _v3HoverY!);
        }
      },
      onLeave: (_) {
        setState(() {
          _v3HoverX = null;
          _v3HoverY = null;
          _v3CanPlace = false;
        });
      },
      onMove: (details) {
        // Calculate grid position from drag position
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.offset);
        
        // Estimate cell position (this is approximate)
        final gridX = ((localPos.dx - 40) / cellSize).floor().clamp(0, _v3GridW - 1);
        final gridY = ((localPos.dy - 300) / cellSize).floor().clamp(0, _v3GridH - 1);
        
        final canPlace = _canPlaceV3Piece(_v3DraggingIndex, gridX, gridY);
        
        if (gridX != _v3HoverX || gridY != _v3HoverY || canPlace != _v3CanPlace) {
          setState(() {
            _v3HoverX = gridX;
            _v3HoverY = gridY;
            _v3CanPlace = canPlace;
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_v3GridH, (y) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_v3GridW, (x) {
                final isSilhouette = _v3Silhouette[y][x];
                final pieceId = _v3Board[y][x];
                final isHover = _v3HoverX == x && _v3HoverY == y && _v3DraggingIndex >= 0;
                
                // Determine cell color
                Color cellColor;
                if (pieceId > 0) {
                  // Filled with a piece - get piece color
                  cellColor = _getPieceColorById(pieceId);
                } else if (isSilhouette) {
                  // Empty silhouette cell
                  if (isHover && _v3CanPlace) {
                    cellColor = Colors.green.shade200;
                  } else if (isHover) {
                    cellColor = Colors.red.shade200;
                  } else {
                    cellColor = Colors.white;
                  }
                } else {
                  // Outside silhouette
                  cellColor = Colors.grey.shade100;
                }

                return GestureDetector(
                  onTap: () {
                    if (pieceId > 0) {
                      _removeV3Piece(x, y);
                    }
                  },
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: cellColor,
                      border: Border.all(
                        color: isSilhouette 
                            ? (pieceId > 0 ? Colors.grey.shade400 : const Color(0xFF4CAF50))
                            : Colors.grey.shade200,
                        width: isSilhouette && pieceId == 0 ? 1.5 : 0.5,
                      ),
                    ),
                    child: pieceId > 0
                        ? const Center(child: Text('■', style: TextStyle(fontSize: 8, color: Colors.white70)))
                        : null,
                  ),
                );
              }),
            )),
          ),
        );
      },
    );
  }

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
  Widget _buildV3PieceItem(int index) {
    final piece = _v3Pieces[index];
    final cells = piece['cells'] as List<List<int>>;
    final area = piece['area'] as int;
    final color = piece['color'] as Color;
    final name = piece['name'] as String;

    // Calculate piece dimensions
    int maxX = 0, maxY = 0;
    for (final cell in cells) {
      maxX = max(maxX, cell[0]);
      maxY = max(maxY, cell[1]);
    }
    final pieceW = maxX + 1;
    final pieceH = maxY + 1;
    const miniCellSize = 16.0;

    return Draggable<int>(
      data: index,
      onDragStarted: () {
        setState(() {
          _v3DraggingIndex = index;
        });
      },
      onDragEnd: (_) {
        setState(() {
          _v3DraggingIndex = -1;
          _v3HoverX = null;
          _v3HoverY = null;
          _v3CanPlace = false;
        });
      },
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: _buildPiecePreview(cells, color, miniCellSize * 1.5),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildPieceTile(pieceW, pieceH, cells, color, name, area, miniCellSize),
      ),
      child: _buildPieceTile(pieceW, pieceH, cells, color, name, area, miniCellSize),
    );
  }

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

  Widget _buildV4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _instructionChip('Split the L-shape into rectangles and find the total area!'),
          const SizedBox(height: 16),

          // L-Shape display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: KidsShadows.soft,
            ),
            child: Column(
              children: [
                _buildLShapeGrid(),
                const SizedBox(height: 16),

                // Split guidance
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFAF52DE).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('✂️ Split into rectangles:',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6A1B9A))),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < _v4PartAreas.length; i++) ...[
                              if (i > 0) ...[
                                const SizedBox(width: 6),
                                const Text('+',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF6A1B9A))),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _partColor(i),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _v4Shape == null
                                      ? '…'
                                      : '${_v4Shape!.rectangles[i].width.toInt()}×${_v4Shape!.rectangles[i].height.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < _v4PartAreas.length; i++) ...[
                              if (i > 0) ...[
                                const SizedBox(width: 6),
                                const Text('+',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF6A1B9A))),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '${_v4PartAreas[i]}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _partColor(i),
                                ),
                              ),
                            ],
                            const Text(' = ?',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF6A1B9A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Question
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFAF52DE).withOpacity(0.1),
                  const Color(0xFFF3E5F5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFAF52DE).withOpacity(0.3)),
            ),
            child: const Text(
              'What is the TOTAL area of this shape? 📐',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6A1B9A)),
            ),
          ),
          const SizedBox(height: 16),

          // Choice buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _v4Choices
                .map((c) => _choiceBtn('$c cm²', () => _submitV4(c)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Color _partColor(int i) {
    const colors = [
      Color(0xFF9C27B0),
      Color(0xFF1E88E5),
      Color(0xFFE65100),
    ];
    return colors[i % colors.length];
  }

  Widget _buildLShapeGrid() {
    final shape = _v4Shape;
    if (shape == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final gridH = shape.grid.length;
    final gridW = shape.grid[0].length;
    final cellSize = min(240.0 / max(gridW, gridH), 44.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(gridH, (y) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(gridW, (x) {
            final isFilled = shape.grid[y][x];
            // Determine which rectangle this cell belongs to
            int partIdx = -1;
            if (isFilled) {
              for (int i = 0; i < shape.rectangles.length; i++) {
                final r = shape.rectangles[i];
                if (x >= r.left && x < r.right && y >= r.top && y < r.bottom) {
                  partIdx = i;
                  break;
                }
              }
            }

            return Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: !isFilled
                    ? Colors.transparent
                    : partIdx >= 0
                        ? _partColor(partIdx).withOpacity(0.3)
                        : const Color(0xFFE1BEE7),
                border: isFilled
                    ? Border.all(color: const Color(0xFFAF52DE), width: 1)
                    : null,
              ),
              child: isFilled
                  ? Center(
                      child: Container(
                        width: cellSize * 0.6,
                        height: cellSize * 0.6,
                        decoration: BoxDecoration(
                          color: partIdx >= 0
                              ? _partColor(partIdx).withOpacity(0.5)
                              : const Color(0xFFCE93D8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    )
                  : null,
            );
          }),
        )),
      ),
    );
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
          border: Border.all(color: tileColor.withOpacity(0.4), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(height, (y) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(width, (x) {
              final filled = tiles[y][x];
              return GestureDetector(
                onTap: () => onTap(x, y),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: filled
                        ? tileColor
                        : tileColor.withOpacity(0.08),
                    border: showGrid
                        ? Border.all(
                            color: tileColor.withOpacity(0.25), width: 0.5)
                        : null,
                  ),
                  child: filled
                      ? Center(
                          child: Text('1',
                              style: TextStyle(
                                  fontSize: cellSize * 0.35,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withOpacity(0.8))),
                        )
                      : showGrid
                          ? Center(
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: tileColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
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

