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
import 'package:ganithamithura/services/user_service.dart';
import 'package:ganithamithura/widgets/cute_character.dart';
import 'ar_questions_screen.dart';
import 'object_capture_yolo_screen.dart';
import 'ar_length_measure_screen.dart';

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

  /// Opens the AR length measurement screen and sets the value if returned
  Future<void> _openARLengthMeasurement() async {
    // Only allow for length type
    if (_measurementType != MeasurementType.length) {
      _showSnackBar('AR measurement is only available for length.', backgroundColor: Colors.orange);
      return;
    }
    final result = await Get.to<String?>(
      () => ARLengthMeasureScreen(),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _valueController.text = result;
      });
      _showSnackBar('Measurement captured: $result cm', backgroundColor: Colors.green);
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
        return const Color(AppColors.numberColor);
      case MeasurementType.capacity:
        return const Color(AppColors.symbolColor);
      case MeasurementType.weight:
        return const Color(AppColors.shapeColor);
      case MeasurementType.area:
        return const Color(AppColors.measurementColor);
    }
  }
  
  Color get _borderColor {
    switch (_measurementType) {
      case MeasurementType.length:
        return const Color(AppColors.numberBorder);
      case MeasurementType.capacity:
        return const Color(AppColors.symbolBorder);
      case MeasurementType.weight:
        return const Color(AppColors.shapeBorder);
      case MeasurementType.area:
        return const Color(AppColors.measurementBorder);
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
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Color(AppColors.textBlack), size: 20),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _measurementType.displayName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textBlack),
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
        return const Color(0xFFE3F2FD); // Light blue
      case MeasurementType.capacity:
        return const Color(0xFFF3E5F5); // Light purple
      case MeasurementType.weight:
        return const Color(0xFFFFF9C4); // Light yellow
      case MeasurementType.area:
        return const Color(0xFFE8F5E9); // Light green
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(AppColors.textBlack),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Let's measure together!",
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(AppColors.textBlack).withOpacity(0.7),
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
    return CuteCard(
      backgroundColor: _primaryColor.withOpacity(0.1),
      borderColor: _primaryColor.withOpacity(0.3),
      child: Row(
        children: [
          Text(
            _measurementType.icon,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What to do?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _borderColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Measure something and tell me about it!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.textBlack),
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
              size: 20,
              color: const Color(AppColors.textBlack),
            ),
            const SizedBox(width: 8),
            const Text(
              'What are you measuring?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textBlack),
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
              size: 20,
              color: const Color(AppColors.textBlack),
            ),
            const SizedBox(width: 8),
            const Text(
              'How much did you measure?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textBlack),
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
              suffixIcon: _measurementType == MeasurementType.length
                  ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.camera_alt, color: _borderColor, size: 20),
                      ),
                      tooltip: 'AR Measure',
                      onPressed: _openARLengthMeasurement,
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
              size: 20,
              color: const Color(AppColors.textBlack),
            ),
            const SizedBox(width: 8),
            const Text(
              'Choose a unit:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textBlack),
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
                  Icon(Icons.rocket_launch_rounded, size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Let's Start!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
