import 'dart:math' as math;

enum ComponentType { number, fixedOp, questionMark }

class EquationComponent {
  final ComponentType type;
  final String text;
  EquationComponent(this.type, this.text);
}

class SymbolQuestion {
  final List<EquationComponent> components;
  final String correctOperation;
  final List<String> options;

  SymbolQuestion({
    required this.components,
    required this.correctOperation,
    required this.options,
  });
}

class SymbolCurriculum {
  static final _random = math.Random();

  static SymbolQuestion generateFor(int grade, int level) {
    if (grade == 1) {
      return _generateGrade1(level);
    } else if (grade == 2) {
      return _generateGrade2(level);
    } else {
      return _generateGrade3(level);
    }
  }

  // --- Grade 1 ---
  static SymbolQuestion _generateGrade1(int level) {
    final ops = ['+', '-', '>', '<'];
    
    if (level <= 2) {
      int maxNum = level == 1 ? 5 : 10;
      bool isOp = _random.nextBool();
      if (isOp) {
        bool isAdd = _random.nextBool();
        if (isAdd) {
          int a = _random.nextInt(maxNum) + 1;
          int b = _random.nextInt(maxNum) + 1;
          return _buildFormatA_op_B_eq_C(a, '+', b, a + b, ops);
        } else {
          int a = _random.nextInt(maxNum) + 1;
          int b = _random.nextInt(a + 1);
          return _buildFormatA_op_B_eq_C(a, '-', b, a - b, ops);
        }
      } else {
        int a = _random.nextInt(maxNum) + 1;
        int b = _random.nextInt(maxNum) + 1;
        while (a == b) b = _random.nextInt(maxNum) + 1;
        return _buildFormatA_cmp_B(a, b, ops);
      }
    } else if (level == 3 || level == 4) {
      int maxNum = 15;
      bool isOp = _random.nextBool();
      if (isOp) {
        bool isAdd = _random.nextBool();
        if (isAdd) {
          int a = _random.nextInt(8) + 1;
          int b = _random.nextInt(8) + 1;
          return _buildFormatA_op_B_eq_C(a, '+', b, a + b, ops);
        } else {
          int a = _random.nextInt(maxNum) + 1;
          int b = _random.nextInt(a + 1);
          return _buildFormatA_op_B_eq_C(a, '-', b, a - b, ops);
        }
      } else {
        int a = _random.nextInt(maxNum) + 1;
        int b = _random.nextInt(maxNum) + 1;
        while (a == b) b = _random.nextInt(maxNum) + 1;
        return _buildFormatA_cmp_B(a, b, ops);
      }
    } else if (level == 5) {
      // 3 numbers: A + B __ C or A - B __ C
      bool isAdd = _random.nextBool();
      int a = _random.nextInt(10) + 1;
      int b = _random.nextInt(7) + 1;
      int c = _random.nextInt(17) + 1;
      if (!isAdd && a < b) {
        int temp = a; a = b; b = temp;
      }
      String exprStr = isAdd ? '$a + $b' : '$a - $b';
      int exprVal = isAdd ? a + b : a - b;
      if (exprVal == c) c++; // avoid equality for grade 1 level 5
      String correct = exprVal > c ? '>' : '<';
      return SymbolQuestion(
        components: [
          EquationComponent(ComponentType.number, exprStr),
          EquationComponent(ComponentType.questionMark, '?'),
          EquationComponent(ComponentType.number, '$c'),
        ],
        correctOperation: correct,
        options: _getOptions(correct, ['>', '<'], 2),
      );
    } else if (level == 6) {
      // Symbol deduction A __ B = C
      bool isAdd = _random.nextBool();
      int a = _random.nextInt(10) + 1;
      int b = _random.nextInt(8) + 1;
      if (isAdd) {
        return _buildFormatA_op_B_eq_C(a, '+', b, a + b, ops);
      } else {
        if (a < b) { int temp = a; a = b; b = temp; }
        return _buildFormatA_op_B_eq_C(a, '-', b, a - b, ops);
      }
    } else {
      // Level 7: Expr __ Num
      int a = _random.nextInt(10) + 1;
      int b = _random.nextInt(10) + 1;
      int c = _random.nextInt(20) + 1;
      bool isAdd = _random.nextBool();
      if (!isAdd && a < b) { int temp = a; a = b; b = temp; }
      int exprVal = isAdd ? a + b : a - b;
      if (exprVal == c) c++;
      String correct = exprVal > c ? '>' : '<';
      return SymbolQuestion(
        components: [
          EquationComponent(ComponentType.number, isAdd ? '$a + $b' : '$a - $b'),
          EquationComponent(ComponentType.questionMark, '?'),
          EquationComponent(ComponentType.number, '$c'),
        ],
        correctOperation: correct,
        options: _getOptions(correct, ['>', '<'], 2),
      );
    }
  }

  // --- Grade 2 ---
  static SymbolQuestion _generateGrade2(int level) {
    final ops = ['+', '-', '×', '>', '<'];
    if (level <= 2) {
      if (_random.nextBool()) {
        int a = _random.nextInt(4) + 2; // 2..5
        int b = _random.nextInt(6) + 1; // 1..6
        return _buildFormatA_op_B_eq_C(a, '×', b, a * b, ops);
      } else {
        int a = _random.nextInt(15) + 1;
        int b = _random.nextInt(a + 1);
        return _buildFormatA_op_B_eq_C(a, '-', b, a - b, ops);
      }
    } else if (level == 3 || level == 4) {
      bool isExpr = _random.nextBool();
      if (isExpr) {
        int a = _random.nextInt(4) + 2;
        int b = _random.nextInt(5) + 1;
        int c = _random.nextInt(30) + 1;
        String correct = (a * b) > c ? '>' : ((a * b) < c ? '<' : '=');
        return SymbolQuestion(
          components: [
            EquationComponent(ComponentType.number, '$a × $b'),
            EquationComponent(ComponentType.questionMark, '?'),
            EquationComponent(ComponentType.number, '$c'),
          ],
          correctOperation: correct,
          options: _getOptions(correct, ['>', '<', '=']),
        );
      } else {
        int a = _random.nextInt(15) + 1;
        int b = _random.nextInt(15) + 1;
        return _buildFormatA_op_B_eq_C(a, '+', b, a + b, ops);
      }
    } else {
      // Complex expression comparisons up to 40 or 50
      int a = _random.nextInt(5) + 1;
      int b = _random.nextInt(5) + 1;
      int c = _random.nextInt(5) + 1;
      int target = _random.nextInt(30) + 5;
      int val = a * b + c;
      String correct = val > target ? '>' : (val < target ? '<' : '=');
      return SymbolQuestion(
        components: [
          EquationComponent(ComponentType.number, '$a × $b + $c'),
          EquationComponent(ComponentType.questionMark, '?'),
          EquationComponent(ComponentType.number, '$target'),
        ],
        correctOperation: correct,
        options: _getOptions(correct, ['>', '<', '=']),
      );
    }
  }

  // --- Grade 3 ---
  static SymbolQuestion _generateGrade3(int level) {
    final ops = ['+', '-', '×', '÷', '>', '<'];
    if (level <= 2) {
      bool isDiv = _random.nextBool();
      if (isDiv) {
        int b = _random.nextInt(4) + 2; // 2..5
        int c = _random.nextInt(6) + 1;
        int a = b * c;
        return _buildFormatA_op_B_eq_C(a, '÷', b, c, ops);
      } else {
        int a = _random.nextInt(8) + 2; 
        int b = _random.nextInt(6) + 1;
        return _buildFormatA_op_B_eq_C(a, '×', b, a * b, ops);
      }
    } else {
      // Mixed operations
      int a = _random.nextInt(6) + 2;
      int b = _random.nextInt(6) + 2;
      int c = _random.nextInt(10) + 1;
      int target = _random.nextInt(50) + 10;
      int val = a * b - c;
      String correct = val > target ? '>' : (val < target ? '<' : '=');
      return SymbolQuestion(
        components: [
          EquationComponent(ComponentType.number, '$a × $b - $c'),
          EquationComponent(ComponentType.questionMark, '?'),
          EquationComponent(ComponentType.number, '$target'),
        ],
        correctOperation: correct,
        options: _getOptions(correct, ['>', '<', '=']),
      );
    }
  }

  // Helpers
  static SymbolQuestion _buildFormatA_op_B_eq_C(int a, String op, int b, int c, List<String> possibleDeps) {
    final filteredOps = ['+', '-', '×', '÷'];
    if (!filteredOps.contains(op)) filteredOps.add(op);
    return SymbolQuestion(
      components: [
        EquationComponent(ComponentType.number, '$a'),
        EquationComponent(ComponentType.questionMark, '?'),
        EquationComponent(ComponentType.number, '$b'),
        EquationComponent(ComponentType.fixedOp, '='),
        EquationComponent(ComponentType.number, '$c'),
      ],
      correctOperation: op,
      options: _getOptions(op, filteredOps),
    );
  }

  static SymbolQuestion _buildFormatA_cmp_B(int a, int b, List<String> possibleDeps) {
    String correct = a > b ? '>' : '<';
    if (a == b) correct = '=';
    
    int maxOps = 2;
    List<String> deps = ['<', '>'];
    if (correct == '=' || possibleDeps.contains('=')) {
        deps = ['<', '>', '='];
        maxOps = 3;
    }

    return SymbolQuestion(
      components: [
        EquationComponent(ComponentType.number, '$a'),
        EquationComponent(ComponentType.questionMark, '?'),
        EquationComponent(ComponentType.number, '$b'),
      ],
      correctOperation: correct,
      options: _getOptions(correct, deps, maxOps),
    );
  }

  static List<String> _getOptions(String correct, List<String> possible, [int maxOpts = 3]) {
    Set<String> opts = {correct};
    final p = List<String>.from(possible)..shuffle();
    for (var op in p) {
      if (opts.length >= maxOpts) break;
      opts.add(op);
    }
    final finalOpts = opts.toList()..shuffle();
    return finalOpts;
  }
}
