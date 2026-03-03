import 'package:flutter/material.dart';
import 'package:ganithamithura/widgets/shapes/match_shapes_2d_widgets.dart';

class TestShapesGameScreen extends StatefulWidget {
  const TestShapesGameScreen({Key? key}) : super(key: key);

  @override
  State<TestShapesGameScreen> createState() => _TestShapesGameScreenState();
}

class _TestShapesGameScreenState extends State<TestShapesGameScreen> {
  // Define targets (image path + correct label)
  final List<Map<String, String>> _targets = [
    {'image': 'assets/images/circle.png', 'name': 'Circle'},
    {'image': 'assets/images/triangle.png', 'name': 'Triangle'},
    {'image': 'assets/images/square.png', 'name': 'Square'},
  ];

  // Track dropped answers per target index
  late List<String?> _dropped;

  // All shape names for the word pool
  late List<String> _allNames;

  @override
  void initState() {
    super.initState();
    _dropped = List<String?>.filled(_targets.length, null);
    _allNames = _targets.map((t) => t['name']!).toList();
  }

  void _onShapeDropped(int index, String name) {
    setState(() {
      // If another card already has this name, remove it from there
      final otherIndex = _dropped.indexWhere((val) => val == name);
      if (otherIndex != -1) _dropped[otherIndex] = null;
      _dropped[index] = name;
    });
  }

  bool _isCorrect(int index) {
    final expected = _targets[index]['name'];
    return _dropped[index] != null && _dropped[index] == expected;
  }

  void _reset() {
    setState(() {
      _dropped = List<String?>.filled(_targets.length, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Available names for word pool are those not already dropped
    final availableNames = _allNames
        .where((n) => !_dropped.contains(n))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Match the Shapes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D4059),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Reset',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    try {
                      // Validate target entries and log any malformed data
                      for (final t in _targets) {
                        if (t['image'] == null || t['name'] == null) {
                          debugPrint(
                            'Invalid target entry in TestShapesGameScreen: $t',
                          );
                        }
                      }

                      final isWide = constraints.maxWidth > 600;
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Cards area
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: _targets.asMap().entries.map((entry) {
                                final index = entry.key;
                                final target = entry.value;
                                final imagePath = target['image'] ?? '';

                                return SizedBox(
                                  width: isWide
                                      ? (constraints.maxWidth - 48) /
                                            _targets.length
                                      : constraints.maxWidth - 32,
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      MatchShapesGameCard(
                                        cardIndex: index,
                                        imagePath: imagePath,
                                        droppedShape: _dropped[index],
                                        onShapeDropped: _onShapeDropped,
                                      ),
                                      if (_dropped[index] != null)
                                        Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor: _isCorrect(index)
                                                ? const Color(0xFF36D399)
                                                : const Color(0xFFE57A7A),
                                            child: Icon(
                                              _isCorrect(index)
                                                  ? Icons.check
                                                  : Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 18),

                            // Instruction
                            const Text(
                              'Drag the shape names from the pool to the matching picture below:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2D4059),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Word pool
                            Center(
                              child: MatchShapesWordPool(
                                shapeNames: availableNames,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Feedback / progress
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_dropped.where((d) => d != null).length}/${_targets.length} matched',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2D4059),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _dropped.contains(null)
                                      ? null
                                      : () {
                                          final correctCount = List.generate(
                                            _targets.length,
                                            (i) => _isCorrect(i),
                                          ).where((v) => v).length;
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Results'),
                                              content: Text(
                                                'You matched $correctCount of ${_targets.length} correctly.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  child: const Text('Check'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    } catch (e, st) {
                      // Log the error and show fallback UI instead of crashing
                      debugPrint('Error building TestShapesGameScreen: $e');
                      debugPrint('$st');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'An unexpected error occurred while building this screen.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
