import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/services/api/number_api_service.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/services/camera_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ========================================================================
// SelectQuestionWidget - Multiple choice (select one answer)
// ========================================================================
class SelectQuestionWidget extends StatefulWidget {
  final ProgressTestQuestion question;
  final Function(bool isCorrect, String answer) onAnswered;

  const SelectQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<SelectQuestionWidget> createState() => _SelectQuestionWidgetState();
}

class _SelectQuestionWidgetState extends State<SelectQuestionWidget> {
  String? _selectedAnswer;
  bool? _isCorrect;

  void _selectAnswer(String answer) {
    if (_selectedAnswer != null) return; // Already answered
    final correct = answer == widget.question.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _isCorrect = correct;
    });
    widget.onAnswered(correct, answer);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Question text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Emoji / visual if available
        if (widget.question.objectEmoji != null) ...[
          Text(
            // Repeat emoji for objectCount
            List.generate(
              widget.question.objectCount ?? 1,
              (_) => widget.question.objectEmoji!,
            ).join(' '),
            style: const TextStyle(fontSize: 36),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],

        const Spacer(),

        // Options
        ...?widget.question.options?.map((option) {
          final isSelected = _selectedAnswer == option;
          final isCorrectOption = option == widget.question.correctAnswer;
          Color? bgColor;
          Color? borderColor;

          if (_selectedAnswer != null) {
            if (isCorrectOption) {
              bgColor = Colors.green.withOpacity(0.15);
              borderColor = Colors.green;
            } else if (isSelected && !_isCorrect!) {
              bgColor = Colors.red.withOpacity(0.15);
              borderColor = Colors.red;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap:
                  _selectedAnswer == null ? () => _selectAnswer(option) : null,
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: bgColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor ?? Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedAnswer != null && isCorrectOption)
                      const Icon(Icons.check_circle, color: Colors.green),
                    if (isSelected && !(_isCorrect ?? true))
                      const Icon(Icons.cancel, color: Colors.red),
                  ],
                ),
              ),
            ),
          );
        }),

        const Spacer(),
      ],
    );
  }
}

// ========================================================================
// ImageCountingWidget - Show emojis/image, ask to count
// ========================================================================
class ImageCountingWidget extends StatefulWidget {
  final ProgressTestQuestion question;
  final Function(bool isCorrect, String answer) onAnswered;

  const ImageCountingWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<ImageCountingWidget> createState() => _ImageCountingWidgetState();
}

class _ImageCountingWidgetState extends State<ImageCountingWidget> {
  String? _selectedAnswer;
  bool? _isCorrect;

  @override
  Widget build(BuildContext context) {
    final count = widget.question.objectCount ?? 1;
    final emoji = widget.question.objectEmoji ?? '🔵';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),

        // Display objects in a grid-like arrangement
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(
              count,
              (i) => Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Options as grid of number buttons
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            shrinkWrap: true,
            children: widget.question.options?.map((option) {
                  final isSelected = _selectedAnswer == option;
                  final isCorrectOption =
                      option == widget.question.correctAnswer;
                  Color bgColor = Colors.white;
                  Color borderColor = Colors.grey.shade300;

                  if (_selectedAnswer != null) {
                    if (isCorrectOption) {
                      bgColor = Colors.green.shade50;
                      borderColor = Colors.green;
                    } else if (isSelected) {
                      bgColor = Colors.red.shade50;
                      borderColor = Colors.red;
                    }
                  }

                  return InkWell(
                    onTap: _selectedAnswer == null
                        ? () {
                            final correct =
                                option == widget.question.correctAnswer;
                            setState(() {
                              _selectedAnswer = option;
                              _isCorrect = correct;
                            });
                            widget.onAnswered(correct, option);
                          }
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _selectedAnswer != null && isCorrectOption
                              ? Colors.green
                              : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList() ??
                [],
          ),
        ),
      ],
    );
  }
}

// ========================================================================
// MatchingQuestionWidget - Draw lines to match left items to right items
// ========================================================================
class MatchingQuestionWidget extends StatefulWidget {
  final ProgressTestQuestion question;
  final Function(bool isCorrect) onAnswered;

  const MatchingQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<MatchingQuestionWidget> createState() => _MatchingQuestionWidgetState();
}

class _MatchingQuestionWidgetState extends State<MatchingQuestionWidget> {
  final Map<String, String> _matches = {};
  String? _selectedLeft;
  bool? _isCorrect;
  bool _submitted = false;

  void _onLeftTap(String item) {
    if (_submitted) return;
    setState(() {
      _selectedLeft = item;
    });
  }

  void _onRightTap(String item) {
    if (_submitted || _selectedLeft == null) return;
    // Check if this right item is already matched
    final existingLeft = _matches.entries
        .where((e) => e.value == item)
        .map((e) => e.key)
        .toList();
    for (final left in existingLeft) {
      _matches.remove(left);
    }

    setState(() {
      _matches[_selectedLeft!] = item;
      _selectedLeft = null;
    });

    // Check if all items are matched
    if (_matches.length == (widget.question.leftItems?.length ?? 0)) {
      _submitMatches();
    }
  }

  void _submitMatches() {
    final correctPairs = widget.question.correctPairs ?? {};
    bool allCorrect = true;

    for (final entry in _matches.entries) {
      if (correctPairs[entry.key] != entry.value) {
        allCorrect = false;
        break;
      }
    }

    setState(() {
      _isCorrect = allCorrect;
      _submitted = true;
    });

    widget.onAnswered(allCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final leftItems = widget.question.leftItems ?? [];
    final rightItems = widget.question.rightItems ?? [];
    final correctPairs = widget.question.correctPairs ?? {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.question.instruction != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.question.instruction!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: leftItems.map((item) {
                    final isSelected = _selectedLeft == item;
                    final isMatched = _matches.containsKey(item);
                    final matchedTo = _matches[item];
                    bool? isPairCorrect;
                    if (_submitted && isMatched) {
                      isPairCorrect = correctPairs[item] == matchedTo;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _onLeftTap(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6B7FFF).withOpacity(0.2)
                                : isMatched
                                    ? (_submitted
                                        ? (isPairCorrect!
                                            ? Colors.green.withOpacity(0.15)
                                            : Colors.red.withOpacity(0.15))
                                        : Colors.blue.withOpacity(0.1))
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6B7FFF)
                                  : isMatched
                                      ? (_submitted
                                          ? (isPairCorrect!
                                              ? Colors.green
                                              : Colors.red)
                                          : Colors.blue)
                                      : Colors.grey.shade300,
                              width: isSelected || isMatched ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Connection indicator
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.compare_arrows,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                  ],
                ),
              ),

              // Right column
              Expanded(
                child: Column(
                  children: rightItems.map((item) {
                    final matchedLeft = _matches.entries
                        .where((e) => e.value == item)
                        .map((e) => e.key)
                        .firstOrNull;
                    final isMatched = matchedLeft != null;
                    bool? isPairCorrect;
                    if (_submitted && isMatched) {
                      isPairCorrect = correctPairs[matchedLeft] == item;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _onRightTap(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isMatched
                                ? (_submitted
                                    ? (isPairCorrect!
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.red.withOpacity(0.15))
                                    : Colors.blue.withOpacity(0.1))
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMatched
                                  ? (_submitted
                                      ? (isPairCorrect!
                                          ? Colors.green
                                          : Colors.red)
                                      : Colors.blue)
                                  : Colors.grey.shade300,
                              width: isMatched ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Feedback
        if (_submitted)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCorrect! ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect! ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect!
                      ? 'All matched correctly!'
                      : 'Some pairs are wrong',
                  style: TextStyle(
                    color: _isCorrect! ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ========================================================================
// DragDropOrderWidget - Reorder items by dragging
// ========================================================================
class DragDropOrderWidget extends StatefulWidget {
  final ProgressTestQuestion question;
  final Function(bool isCorrect, String answer) onAnswered;

  const DragDropOrderWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<DragDropOrderWidget> createState() => _DragDropOrderWidgetState();
}

class _DragDropOrderWidgetState extends State<DragDropOrderWidget> {
  late List<String> _currentOrder;
  bool _submitted = false;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _currentOrder = List<String>.from(widget.question.items ?? []);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_submitted) return;
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
    });
  }

  void _submit() {
    final correctOrder = widget.question.correctOrder ?? [];
    final correct = _listEquals(_currentOrder, correctOrder);

    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });

    widget.onAnswered(correct, _currentOrder.join(', '));
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.question.instruction != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.question.instruction!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 8),

        // Hint: drag to reorder
        if (!_submitted)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.drag_indicator, color: Colors.grey[400], size: 20),
              const SizedBox(width: 4),
              Text(
                'Hold and drag to reorder',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        const SizedBox(height: 12),

        // Reorderable list
        Expanded(
          child: ReorderableListView(
            onReorder: _onReorder,
            buildDefaultDragHandles: !_submitted,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(14),
                child: child,
              );
            },
            children: [
              for (int i = 0; i < _currentOrder.length; i++)
                Container(
                  key: ValueKey('${_currentOrder[i]}_$i'),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: _submitted
                        ? (_currentOrder[i] ==
                                (widget.question.correctOrder ?? [])[i]
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15))
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _submitted
                          ? (_currentOrder[i] ==
                                  (widget.question.correctOrder ?? [])[i]
                              ? Colors.green
                              : Colors.red)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (!_submitted)
                        ReorderableDragStartListener(
                          index: i,
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.grey[400],
                          ),
                        ),
                      if (!_submitted) const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B7FFF).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7FFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _currentOrder[i],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_submitted)
                        Icon(
                          _currentOrder[i] ==
                                  (widget.question.correctOrder ?? [])[i]
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _currentOrder[i] ==
                                  (widget.question.correctOrder ?? [])[i]
                              ? Colors.green
                              : Colors.red,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Submit button
        if (!_submitted)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7FFF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Check Order',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        // Feedback
        if (_submitted)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCorrect! ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect! ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect! ? 'Perfect order!' : 'Not quite right',
                  style: TextStyle(
                    color: _isCorrect! ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ========================================================================
// DragDropCountWidget - Drag objects into a box to reach target count
// ========================================================================
class DragDropCountWidget extends StatefulWidget {
  final ProgressTestQuestion question;
  final Function(bool isCorrect, String answer) onAnswered;

  const DragDropCountWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<DragDropCountWidget> createState() => _DragDropCountWidgetState();
}

class _DragDropCountWidgetState extends State<DragDropCountWidget> {
  final List<int> _droppedItems = [];
  late Set<int> _availableItems;
  bool _submitted = false;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _availableItems = Set<int>.from(
      List.generate(widget.question.availableCount ?? 10, (i) => i),
    );
  }

  void _submit() {
    final correct = _droppedItems.length == (widget.question.correctCount ?? 0);
    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });
    widget.onAnswered(correct, _droppedItems.length.toString());
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.question.objectEmoji ?? '🔵';
    final targetCount = widget.question.correctCount ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),

        // Drop target area
        DragTarget<int>(
          onAcceptWithDetails: (details) {
            if (_submitted) return;
            setState(() {
              _droppedItems.add(details.data);
              _availableItems.remove(details.data);
            });
          },
          builder: (context, candidateData, rejectedData) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty
                    ? const Color(0xFF6B7FFF).withOpacity(0.1)
                    : _submitted
                        ? (_isCorrect!
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1))
                        : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: candidateData.isNotEmpty
                      ? const Color(0xFF6B7FFF)
                      : _submitted
                          ? (_isCorrect! ? Colors.green : Colors.red)
                          : Colors.grey.shade300,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
              ),
              child: _droppedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 36,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Drop here',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _droppedItems.map((item) {
                          return GestureDetector(
                            onTap: _submitted
                                ? null
                                : () {
                                    setState(() {
                                      _droppedItems.remove(item);
                                      _availableItems.add(item);
                                    });
                                  },
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            );
          },
        ),

        // Count display
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Count: ${_droppedItems.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _submitted
                      ? (_isCorrect! ? Colors.green : Colors.red)
                      : const Color(0xFF6B7FFF),
                ),
              ),
              Text(
                '',
                // ' / Target: $targetCount',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Available items to drag
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _availableItems.map((item) {
                return Draggable<int>(
                  data: item,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Text(emoji, style: const TextStyle(fontSize: 44)),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: Text(emoji, style: const TextStyle(fontSize: 36)),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 36)),
                );
              }).toList(),
            ),
          ),
        ),

        // Submit button
        if (!_submitted)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _droppedItems.isNotEmpty ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7FFF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Check Count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        // Feedback
        if (_submitted)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCorrect! ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect! ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect!
                      ? 'Correct count!'
                      : 'Needed $targetCount, got ${_droppedItems.length}',
                  style: TextStyle(
                    color: _isCorrect! ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ========================================================================
// PatternFillWidget - Fill in the blank in a number pattern
// ========================================================================
class PatternFillWidget extends StatefulWidget {
  final ProgressTestQuestion question;
  final Function(bool isCorrect, String answer) onAnswered;

  const PatternFillWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<PatternFillWidget> createState() => _PatternFillWidgetState();
}

class _PatternFillWidgetState extends State<PatternFillWidget> {
  String? _selectedAnswer;
  bool? _isCorrect;

  @override
  Widget build(BuildContext context) {
    final displaySeq = widget.question.displaySequence ?? [];
    final blankPos = widget.question.blankPosition ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.question.instruction != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.question.instruction!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 16),

        // Pattern display (horizontally scrollable)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < displaySeq.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  if (displaySeq[i] == '___')
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _selectedAnswer != null
                            ? (_isCorrect!
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15))
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedAnswer != null
                              ? (_isCorrect! ? Colors.green : Colors.red)
                              : const Color(0xFF6B7FFF),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _selectedAnswer ?? '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _selectedAnswer != null
                              ? (_isCorrect! ? Colors.green : Colors.red)
                              : const Color(0xFF6B7FFF),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        displaySeq[i],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),

        const Spacer(),

        // Options
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: widget.question.options?.map((option) {
                final isSelected = _selectedAnswer == option;
                final isCorrectOption = option == widget.question.correctAnswer;
                Color bgColor = Colors.white;
                Color borderColor = Colors.grey.shade300;

                if (_selectedAnswer != null) {
                  if (isCorrectOption) {
                    bgColor = Colors.green.shade50;
                    borderColor = Colors.green;
                  } else if (isSelected) {
                    bgColor = Colors.red.shade50;
                    borderColor = Colors.red;
                  }
                }

                return InkWell(
                  onTap: _selectedAnswer == null
                      ? () {
                          final correct =
                              option == widget.question.correctAnswer;
                          setState(() {
                            _selectedAnswer = option;
                            _isCorrect = correct;
                          });
                          widget.onAnswered(correct, option);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _selectedAnswer != null && isCorrectOption
                            ? Colors.green
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList() ??
              [],
        ),

        const Spacer(),
      ],
    );
  }
}

// ========================================================================
// TraceQuestionWidget - Drawing/tracing a number
// ========================================================================
class TraceQuestionWidget extends StatefulWidget {
  final ProgressTestQuestion question;
  final Function(bool isCorrect, String answer) onAnswered;

  const TraceQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<TraceQuestionWidget> createState() => _TraceQuestionWidgetState();
}

class _TraceQuestionWidgetState extends State<TraceQuestionWidget> {
  final _apiService = NumApiService.instance;
  final GlobalKey _canvasKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _submitted = false;
  bool _isRecognizing = false;
  bool? _isCorrect;
  String? _feedback;
  int? _predictedDigit;

  /// Capture the drawing canvas as a PNG image with proper formatting
  /// Converts to BLACK background with WHITE strokes for MNIST model
  Future<Uint8List?> _captureCanvas() async {
    try {
      // Get the actual render box size
      final RenderBox? renderBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        debugPrint('Error: Could not get render box');
        return null;
      }

      final size = renderBox.size;
      debugPrint('Canvas size: ${size.width} x ${size.height}');

      // Create a custom painter with BLACK background and WHITE strokes
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw BLACK background (MNIST expects white digits on black)
      final backgroundPaint = Paint()..color = Colors.black;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        backgroundPaint,
      );

      // Draw strokes in WHITE
      final strokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 28.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // Draw all completed strokes
      for (final stroke in _strokes) {
        if (stroke.length < 2) continue;
        final path = Path();
        path.moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, strokePaint);
      }

      // Draw current stroke if any
      if (_currentStroke.length >= 2) {
        final path = Path();
        path.moveTo(_currentStroke[0].dx, _currentStroke[0].dy);
        for (int i = 1; i < _currentStroke.length; i++) {
          path.lineTo(_currentStroke[i].dx, _currentStroke[i].dy);
        }
        canvas.drawPath(path, strokePaint);
      }

      final picture = recorder.endRecording();

      // Use the actual canvas size for the image
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    final hasDrawn = _strokes.isNotEmpty || _currentStroke.isNotEmpty;
    if (!hasDrawn) return;

    setState(() {
      _isRecognizing = true;
    });

    try {
      // Capture the canvas as image bytes
      final imageBytes = await _captureCanvas();

      if (imageBytes != null) {
        // Send to digit recognition API
        final result = await _apiService
            .recognizeDigit(
              imageBytes: imageBytes,
              expectedDigit: widget.question.expectedNumber,
              confidenceThreshold: 0.5,
            )
            .timeout(const Duration(seconds: 3));

        final correct = result.isCorrect ?? false;

        setState(() {
          _submitted = true;
          _isRecognizing = false;
          _isCorrect = correct;
          _predictedDigit = result.predictedDigit;
          _feedback = result.feedback ??
              (correct
                  ? 'Great drawing!'
                  : 'That looks like ${result.predictedDigit}. Expected ${widget.question.expectedNumber}.');
        });

        widget.onAnswered(
            correct, widget.question.expectedNumber?.toString() ?? '');
      } else {
        setState(() {
          _isRecognizing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to capture drawing. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Digit recognition error: $e');
      setState(() {
        _isRecognizing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recognition failed. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final number = widget.question.expectedNumber ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Show the target number as reference
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$number',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7FFF),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '(${widget.question.word ?? ''})',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Drawing canvas with RepaintBoundary for capture
        Expanded(
          child: Center(
            child: SizedBox(
              width: 350,
              height: 350,
              child: RepaintBoundary(
                key: _canvasKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _submitted
                          ? (_isCorrect! ? Colors.green : Colors.red)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GestureDetector(
                      onPanStart: _submitted
                          ? null
                          : (details) {
                              setState(() {
                                _currentStroke = [details.localPosition];
                              });
                            },
                      onPanUpdate: _submitted
                          ? null
                          : (details) {
                              setState(() {
                                _currentStroke.add(details.localPosition);
                              });
                            },
                      onPanEnd: _submitted
                          ? null
                          : (details) {
                              setState(() {
                                _strokes.add(List.from(_currentStroke));
                                _currentStroke = [];
                              });
                            },
                      child: CustomPaint(
                        painter: _DrawingPainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Action buttons
        if (!_submitted && !_isRecognizing)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _strokes.isNotEmpty || _currentStroke.isNotEmpty
                      ? _submit
                      : null,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Submit Drawing',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7FFF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),

        // Recognizing indicator
        if (_isRecognizing)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Recognizing your drawing...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

        if (_submitted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCorrect! ? Icons.check_circle : Icons.cancel,
                      color: _isCorrect! ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _feedback ?? '',
                        style: TextStyle(
                          color: _isCorrect! ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (_predictedDigit != null && !_isCorrect!) ...[
                  const SizedBox(height: 4),
                  Text(
                    'AI detected: $_predictedDigit',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Simple drawing painter for trace widget
class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _DrawingPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B7FFF)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

// ========================================================================
// SayQuestionWidget - Speech recognition answer
// ========================================================================
class SayQuestionWidget extends StatefulWidget {
  final ProgressTestQuestion question;
  final Function(bool isCorrect, String answer) onAnswered;

  const SayQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<SayQuestionWidget> createState() => _SayQuestionWidgetState();
}

class _SayQuestionWidgetState extends State<SayQuestionWidget> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  bool _submitted = false;
  bool? _isCorrect;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      // Cancel any previous session before re-initializing
      await _speech.cancel();
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          // When the engine stops (e.g. pauseFor timeout), submit whatever was
          // captured so far — otherwise single-word results get dropped.
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
              _stopListeningAndCheck();
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          _isListening = false;
          if (mounted) {
            setState(() {
              _isListening = false;
              // If speech fails, still allow number pad fallback
              if (error.permanent) {
                _speechAvailable = false;
              }
            });
          }
        },
      );
    } catch (e) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  void _startListening() async {
    if (!_speechAvailable) {
      // Fallback: show number pad for manual entry
      _showNumberPad();
      return;
    }

    // Cancel any lingering session before starting fresh
    await _speech.cancel();
    await Future.delayed(const Duration(milliseconds: 100));

    // Provide haptic feedback when starting microphone
    HapticFeedback.heavyImpact();

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        }
        if (result.finalResult) {
          _stopListeningAndCheck();
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(milliseconds: 2000),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  void _stopListeningAndCheck() async {
    if (!_isListening || _submitted) return; // guard against double-invocation

    // Provide haptic feedback when stopping microphone
    HapticFeedback.heavyImpact();

    await _speech.stop();
    setState(() {
      _isListening = false;
    });

    if (_recognizedText.isNotEmpty && !_submitted) {
      _checkAnswer(_recognizedText.toLowerCase().trim());
    }
  }

  void _checkAnswer(String answer) {
    final alternatives = widget.question.alternatives ?? [];
    final correctAnswer = widget.question.correctAnswer ?? '';

    // Normalize: speech engines often return digits ("7") instead of words
    // ("seven"). Convert digit strings to their word equivalent before comparing.
    final asInt = int.tryParse(answer);
    if (asInt != null) {
      final asWord = NumberWords.getWord(asInt);
      if (asWord.isNotEmpty) answer = asWord;
    }

    final isCorrect = answer == correctAnswer ||
        alternatives.any((alt) => alt.toLowerCase() == answer);

    setState(() {
      _submitted = true;
      _isCorrect = isCorrect;
    });

    widget.onAnswered(isCorrect, answer);
  }

  Future<void> _resetSpeech() async {
    try {
      // Cancel current session
      await _speech.cancel();

      // Reset state
      setState(() {
        _isListening = false;
        _recognizedText = '';
      });

      // Wait a bit before reinitializing
      await Future.delayed(const Duration(milliseconds: 300));

      // Reinitialize speech
      await _initSpeech();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition reset'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error resetting speech: $e');
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  void _showNumberPad() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tap the correct number',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                shrinkWrap: true,
                children: List.generate(10, (i) {
                  final num = i + 1;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _recognizedText = '$num';
                      });
                      _checkAnswer('$num');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$num',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.question.objectEmoji ?? '🔵';
    final count = widget.question.objectCount ?? 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Show objects
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(
              count,
              (i) => Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
        ),

        const Spacer(),

        // Recognized text display
        if (_recognizedText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: _submitted
                  ? (_isCorrect!
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1))
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_submitted)
                  Icon(
                    _isCorrect! ? Icons.check_circle : Icons.cancel,
                    color: _isCorrect! ? Colors.green : Colors.red,
                  ),
                if (_submitted) const SizedBox(width: 8),
                Text(
                  'You said: "$_recognizedText"',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _submitted
                        ? (_isCorrect! ? Colors.green : Colors.red)
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

        const Spacer(),

        // Microphone button or number pad
        if (!_submitted)
          Column(
            children: [
              GestureDetector(
                onTap: _isListening ? _stopListeningAndCheck : _startListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.red : const Color(0xFF6B7FFF),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isListening
                    ? 'Listening...'
                    : (_speechAvailable
                        ? 'Tap to speak'
                        : 'Tap to enter number'),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              if (!_speechAvailable) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showNumberPad,
                  child: const Text('Use number pad instead'),
                ),
              ],
              // Reset button for speech issues
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _resetSpeech,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset Microphone'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
            ],
          ),

        if (_submitted)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _isCorrect!
                  ? 'Correct!'
                  : 'The answer was ${widget.question.correctAnswer}',
              style: TextStyle(
                color: _isCorrect! ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ============================================================
// ObjectDetectionQuestionWidget - Camera-based object counting
// ============================================================

class ObjectDetectionQuestionWidget extends StatefulWidget {
  final ProgressTestQuestion question;
  final Function(bool isCorrect, String answer) onAnswered;

  const ObjectDetectionQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<ObjectDetectionQuestionWidget> createState() =>
      _ObjectDetectionQuestionWidgetState();
}

class _ObjectDetectionQuestionWidgetState
    extends State<ObjectDetectionQuestionWidget> {
  final _apiService = NumApiService.instance;
  final _cameraService = CameraService.instance;

  bool _cameraInitialized = false;
  bool _cameraError = false;
  String _errorMessage = '';
  bool _isDetecting = false;
  bool _submitted = false;
  bool? _isCorrect;
  int _detectedCount = 0;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _cameraError = true;
          _errorMessage = 'Camera permission denied';
        });
        return;
      }

      await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _cameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _cameraError = true;
          _errorMessage = 'Could not access camera';
        });
      }
    }
  }

  Future<void> _captureAndDetect() async {
    if (_isDetecting || _submitted) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      final imageBytes =
          await _cameraService.captureCompressedFrame(quality: 85);
      if (imageBytes == null) {
        setState(() {
          _isDetecting = false;
        });
        return;
      }

      final targetObject = widget.question.objectName ?? 'any';
      final expectedCount = widget.question.objectCount ?? 1;

      final result = await _apiService
          .detectObjects(
            imageBytes: imageBytes,
            targetObject: targetObject,
            expectedCount: expectedCount,
            confidenceThreshold: 0.4,
          )
          .timeout(const Duration(seconds: 20));

      // Check if validated correctly
      final isCorrect = result.validation?.isCorrect ?? false;
      final detected = result.validation?.detectedCount ?? result.totalCount;

      setState(() {
        _submitted = true;
        _isDetecting = false;
        _isCorrect = isCorrect;
        _detectedCount = detected;
        _feedback = isCorrect
            ? 'Great! Found $detected ${targetObject == 'any' ? 'objects' : targetObject}(s)!'
            : 'Found $detected, expected $expectedCount ${targetObject == 'any' ? 'objects' : targetObject}(s). ${result.validation?.feedback ?? ''}';
      });

      widget.onAnswered(isCorrect, detected.toString());
    } catch (e) {
      debugPrint('Detection error: $e');
      setState(() {
        _isDetecting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detection failed. Try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
    _submitted = false;
  }

  @override
  Widget build(BuildContext context) {
    final expectedCount = widget.question.objectCount ?? 1;
    final targetObject = widget.question.objectName ?? 'objects';

    return Column(
      children: [
        // Question text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Instruction
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt, color: Color(0xFF6B7FFF), size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Point camera at $expectedCount $targetObject and capture!',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7FFF),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Camera preview or error/loading
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _submitted
                      ? (_isCorrect! ? Colors.green : Colors.red)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: _buildCameraContent(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Capture button
        if (_cameraInitialized && !_submitted && !_isDetecting)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _captureAndDetect,
              icon: const Icon(Icons.camera, color: Colors.white, size: 24),
              label: const Text(
                'Capture & Detect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7FFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

        // Detecting indicator
        if (_isDetecting)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Detecting objects...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

        // Result feedback
        if (_submitted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCorrect! ? Icons.check_circle : Icons.cancel,
                      color: _isCorrect! ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _feedback,
                        style: TextStyle(
                          color: _isCorrect! ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Detected: $_detectedCount | Expected: $expectedCount',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCameraContent() {
    if (_cameraError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _initCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_cameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Starting camera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return CameraPreview(_cameraService.controller!);
  }
}
