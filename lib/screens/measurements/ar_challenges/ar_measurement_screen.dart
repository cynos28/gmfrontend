/// Measurement Screen - Capture measurements and generate contextual questions
/// 
/// This screen allows students to:
/// 1. Select what they're measuring (object name)
/// 2. Enter measurement value and unit
/// 3. Generate personalized questions about their measurement

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/models/ar_measurement.dart';
import 'package:ganithamithura/services/ar_learning_service.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/user_service.dart';
import 'package:ganithamithura/widgets/cute_character.dart';
import 'ar_questions_screen.dart';
import 'object_capture_yolo_screen.dart';
import 'ar_length_measure_screen.dart';
import 'ar_area_measure_screen.dart';

class ARMeasurementScreen extends StatefulWidget {
  const ARMeasurementScreen({Key? key}) : super(key: key);

  @override
  State<ARMeasurementScreen> createState() => _ARMeasurementScreenState();
}

class _ARMeasurementScreenState extends State<ARMeasurementScreen> {
  final ARLearningService _arService = ARLearningService();
  final TextEditingController _objectController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  
  late MeasurementType _measurementType;
  MeasurementUnit? _selectedUnit;
  bool _isProcessing = false;
  String? _sessionId;
  
  // Unit options per measurement type
  Map<MeasurementType, List<MeasurementUnit>> unitOptions = {
    MeasurementType.length: [
      MeasurementUnit.mm,
      MeasurementUnit.cm,
      MeasurementUnit.m,
      MeasurementUnit.km,
    ],
    MeasurementType.capacity: [
      MeasurementUnit.ml,
      MeasurementUnit.l,
    ],
    MeasurementType.weight: [
      MeasurementUnit.g,
      MeasurementUnit.kg,
    ],
    MeasurementType.area: [
      MeasurementUnit.cm2,
      MeasurementUnit.m2,
    ],
  };
  
  @override
  void initState() {
    super.initState();
    // Get measurement type from route arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final typeString = args?['type'] as String? ?? 'length';
    
    _measurementType = _parseMeasurementType(typeString);
    _selectedUnit = unitOptions[_measurementType]?.first;
    
    // Start AR session
    final session = _arService.startSession(
      studentId: 'student_123', // TODO: Get from auth
      type: _measurementType,
    );
    _sessionId = session.sessionId;
    
    print('📱 AR Session started: ${_measurementType.displayName}');
  }
  
  @override
  void dispose() {
    _objectController.dispose();
    _valueController.dispose();
    if (_sessionId != null) {
      _arService.endSession(_sessionId!);
    }
    super.dispose();
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Opens the AR measurement screen and sets the value if returned
  Future<void> _openARMeasurement() async {
    // Only allow for length and area types
    if (_measurementType != MeasurementType.length && _measurementType != MeasurementType.area) {
      _showSnackBar('AR measurement is only available for length and area.', backgroundColor: Colors.orange);
      return;
    }
    
    // Use different screens for length vs area
    final result = await Get.to<String?>(
      _measurementType == MeasurementType.length
          ? () => ARLengthMeasureScreen()
          : () => const ARAreaMeasureScreen(),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _valueController.text = result;
      });
      final unit = _measurementType == MeasurementType.length ? 'cm' : 'cm²';
      _showSnackBar('Measurement captured: $result $unit', backgroundColor: Colors.green);
    }
  }

  /// Opens the object detection screen using camera
  /// The detected object name will be auto-filled in the text field
 Future<void> _openObjectDetection() async {
  final result = await Get.to<String?>(
    () => const ObjectCaptureYoloScreen(),
  );

  if (result != null && result.trim().isNotEmpty) {
    final formattedName = result
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

    setState(() => _objectController.text = formattedName);

    _showSnackBar(
      'Object detected: $formattedName',
      backgroundColor: Colors.green,
    );
  }
}
  MeasurementType _parseMeasurementType(String type) {
    switch (type.toLowerCase()) {
      case 'length':
        return MeasurementType.length;
      case 'capacity':
        return MeasurementType.capacity;
      case 'weight':
        return MeasurementType.weight;
      case 'area':
        return MeasurementType.area;
      default:
        return MeasurementType.length;
    }
  }
  
  Color get _primaryColor {
    switch (_measurementType) {
      case MeasurementType.length:
        return KidsColors.lengthColor;
      case MeasurementType.capacity:
        return KidsColors.capacityColor;
      case MeasurementType.weight:
        return KidsColors.weightColor;
      case MeasurementType.area:
        return KidsColors.areaColor;
    }
  }
  
  Color get _borderColor {
    switch (_measurementType) {
      case MeasurementType.length:
        return KidsColors.lengthColor;
      case MeasurementType.capacity:
        return KidsColors.capacityColor;
      case MeasurementType.weight:
        return KidsColors.weightColor;
      case MeasurementType.area:
        return KidsColors.areaColor;
    }
  }
  
  Future<void> _generateQuestions() async {
    // Validate inputs
    if (_objectController.text.trim().isEmpty) {
      _showSnackBar(
        'Please enter what you are measuring',
        backgroundColor: Colors.orange,
      );
      return;
    }
    
    final value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      _showSnackBar(
        'Please enter a valid measurement value',
        backgroundColor: Colors.orange,
      );
      return;
    }
    
    if (_selectedUnit == null) {
      _showSnackBar(
        'Please select a measurement unit',
        backgroundColor: Colors.orange,
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      print('🔄 Processing AR measurement...');
      
      final grade = await UserService.getGrade();
      final measurement = await _arService.processARMeasurement(
        sessionId: _sessionId!,
        value: value,
        unit: _selectedUnit!,
        objectName: _objectController.text.trim(),
        studentId: 'student_123', // TODO: Get from auth
        grade: grade,
        numQuestions: 5,
      );
      
      print('✅ Generated ${measurement.questions.length} questions');
      
      // Navigate to questions screen
      Get.to(() => const ARQuestionsScreen(), arguments: {
        'measurement': measurement,
        'measurementType': _measurementType,
      });
      
    } catch (e) {
      print('❌ Error: $e');
      _showSnackBar(
        'Failed to generate questions: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: KidsShadows.soft,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: KidsColors.textPrimary,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => Get.back(),
            ),
          ),
        ),
        title: Text(
          _measurementType.displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: KidsColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildManualMode(),
      ),
    );
  }
  
  Color _getBackgroundColor() {
    switch (_measurementType) {
      case MeasurementType.length:
        return KidsColors.lengthBackground;
      case MeasurementType.capacity:
        return KidsColors.capacityBackground;
      case MeasurementType.weight:
        return KidsColors.weightBackground;
      case MeasurementType.area:
        return KidsColors.areaBackground;
    }
  }
  
  Widget _buildManualMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cute character with greeting
          _buildCharacterGreeting(),
          const SizedBox(height: 24),
          
          // Instructions Card
          _buildInstructionsCard(),
          const SizedBox(height: 24),
          
          // Object Name Input
          _buildObjectNameInput(),
          const SizedBox(height: 20),
          
          // Measurement Value Input
          _buildMeasurementInput(),
          const SizedBox(height: 20),
          
          // Unit Selection
          _buildUnitSelector(),
          const SizedBox(height: 32),
          
          // Generate Questions Button
          _buildGenerateButton(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
  
  Widget _buildCharacterGreeting() {
    return CuteCard(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CuteCharacter(
                color: _primaryColor,
                size: 60,
                animate: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hello, Friend!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: KidsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Let's measure together!",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KidsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstructionsCard() {
    IconData getIcon() {
      switch (_measurementType) {
        case MeasurementType.length:
          return Icons.straighten_rounded;
        case MeasurementType.capacity:
          return Icons.local_drink_rounded;
        case MeasurementType.weight:
          return Icons.scale_rounded;
        case MeasurementType.area:
          return Icons.grid_on_rounded;
      }
    }

    return CuteCard(
      backgroundColor: _primaryColor.withOpacity(0.1),
      borderColor: _primaryColor.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor,
                  _primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              getIcon(),
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What to do?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _borderColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Measure something and tell me about it!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KidsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildObjectNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.inventory_2_rounded,
              size: 22,
              color: KidsColors.textPrimary,
            ),
            const SizedBox(width: 8),
            const Text(
              'What are you measuring?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: KidsColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _objectController,
            decoration: InputDecoration(
              hintText: 'e.g., pencil, water bottle',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(
                Icons.edit_rounded,
                color: _borderColor,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: _borderColor, size: 20),
                ),
                tooltip: 'Use camera',
                onPressed: _openObjectDetection,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMeasurementInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.straighten_rounded,
              size: 22,
              color: KidsColors.textPrimary,
            ),
            const SizedBox(width: 8),
            const Text(
              'How much did you measure?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: KidsColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Enter number',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18),
              prefixIcon: Icon(
                Icons.tag_rounded,
                color: _borderColor,
                size: 20,
              ),
              suffixIcon: (_measurementType == MeasurementType.length || _measurementType == MeasurementType.area)
                  ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.camera_alt, color: _borderColor, size: 20),
                      ),
                      tooltip: _measurementType == MeasurementType.length ? 'AR Measure' : 'AR Measure Area',
                      onPressed: _openARMeasurement,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUnitSelector() {
    final units = unitOptions[_measurementType] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.square_foot_rounded,
              size: 22,
              color: KidsColors.textPrimary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Choose a unit:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: KidsColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: units.map((unit) {
            final isSelected = _selectedUnit == unit;
            return PillButton(
              text: unit.displayName,
              onPressed: () => setState(() => _selectedUnit = unit),
              color: _borderColor,
              isSelected: isSelected,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _borderColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _generateQuestions,
        style: ElevatedButton.styleFrom(
          backgroundColor: _borderColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_rounded, size: 26),
                  SizedBox(width: 12),
                  Text(
                    "Let's Start!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
