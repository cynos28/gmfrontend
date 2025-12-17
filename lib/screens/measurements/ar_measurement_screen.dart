/// AR Measurement Screen - Capture measurements and generate contextual questions
/// 
/// This screen allows students to:
/// 1. Select what they're measuring (object name)
/// 2. Enter measurement value and unit
/// 3. Generate personalized questions about their measurement

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/ar_measurement.dart';
import '../../services/ar_learning_service.dart';
import '../../services/ar_camera_service.dart';
import '../../widgets/measurements/ar_camera_widget.dart';
import '../../utils/constants.dart';
import 'ar_questions_screen.dart';

class ARMeasurementScreen extends StatefulWidget {
  const ARMeasurementScreen({Key? key}) : super(key: key);

  @override
  State<ARMeasurementScreen> createState() => _ARMeasurementScreenState();
}

class _ARMeasurementScreenState extends State<ARMeasurementScreen> {
  final ARLearningService _arService = ARLearningService();
  final ARCameraService _cameraService = ARCameraService();
  final TextEditingController _objectController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  
  late MeasurementType _measurementType;
  MeasurementUnit? _selectedUnit;
  bool _isProcessing = false;
  String? _sessionId;
  
  // Camera mode
  bool _useCameraMode = false;
  bool _isCameraInitialized = false;
  String? _capturedPhotoPath;
  
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
    _cameraService.dispose();
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
  
  Future<void> _toggleCameraMode() async {
    if (!_useCameraMode) {
      // Initialize camera
      setState(() {
        _isProcessing = true;
      });
      
      try {
        await _cameraService.initialize();
        setState(() {
          _useCameraMode = true;
          _isCameraInitialized = true;
        });
      } catch (e) {
        _showSnackBar(
          'Failed to initialize camera: $e',
          backgroundColor: Colors.red,
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    } else {
      // Switch back to manual mode
      await _cameraService.dispose();
      setState(() {
        _useCameraMode = false;
        _isCameraInitialized = false;
      });
    }
  }
  
  void _onCameraMeasurementComplete(double value, String? photoPath) {
    setState(() {
      _valueController.text = value.toStringAsFixed(1);
      _capturedPhotoPath = photoPath;
      _useCameraMode = false;
    });
    
    _cameraService.dispose();
    
    _showSnackBar('Measurement Captured: ${value.toStringAsFixed(1)} cm');
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
      
      final measurement = await _arService.processARMeasurement(
        sessionId: _sessionId!,
        value: value,
        unit: _selectedUnit!,
        objectName: _objectController.text.trim(),
        studentId: 'student_123', // TODO: Get from auth
        grade: 1, // TODO: Get from student profile
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
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(AppColors.textBlack)),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Text(
              _measurementType.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              'Measure ${_measurementType.displayName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.textBlack),
              ),
            ),
          ],
        ),
        actions: [
          // Camera mode toggle
          IconButton(
            icon: Icon(
              _useCameraMode ? Icons.keyboard : Icons.camera_alt,
              color: _borderColor,
            ),
            onPressed: _toggleCameraMode,
            tooltip: _useCameraMode ? 'Manual Input' : 'Camera Mode',
          ),
        ],
      ),
      body: SafeArea(
        child: _useCameraMode && _isCameraInitialized
            ? _buildCameraMode()
            : _buildManualMode(),
      ),
    );
  }
  
  Widget _buildCameraMode() {
    return Column(
      children: [
        // Camera widget
        Expanded(
          child: ARCameraWidget(
            cameraService: _cameraService,
            onMeasurementComplete: _onCameraMeasurementComplete,
            primaryColor: _primaryColor,
            measurementType: _measurementType.displayName,
          ),
        ),
        
        // Object name input below camera
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'What are you measuring?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textBlack),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _objectController,
                decoration: InputDecoration(
                  hintText: 'e.g., pencil, water bottle, table',
                  prefixIcon: Icon(Icons.label_outline, color: _borderColor),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _borderColor, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildManualMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 16),
          
          // Example Card
          _buildExampleCard(),
        ],
      ),
    );
  }
  
  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(AppColors.infoColor),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How it works',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textBlack),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _useCameraMode 
                      ? 'Use camera to measure objects with AR!'
                      : 'Measure an object, enter the details, and get personalized questions!',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(AppColors.textBlack).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (!_useCameraMode)
            IconButton(
              icon: Icon(Icons.camera_alt, color: _borderColor),
              onPressed: _toggleCameraMode,
              tooltip: 'Use Camera',
            ),
        ],
      ),
    );
  }
  
  Widget _buildObjectNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you measuring?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textBlack),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _objectController,
          decoration: InputDecoration(
            hintText: 'e.g., pencil, water bottle, table',
            prefixIcon: Icon(Icons.label_outline, color: _borderColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor.withOpacity(0.3), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor, width: 2),
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
        const Text(
          'Measurement Value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textBlack),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter measurement',
            prefixIcon: Icon(Icons.straighten, color: _borderColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor.withOpacity(0.3), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor, width: 2),
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
        const Text(
          'Unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textBlack),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: units.map((unit) {
            final isSelected = _selectedUnit == unit;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedUnit = unit;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor.withOpacity(0.2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _borderColor : _borderColor.withOpacity(0.3),
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.check_circle,
                          color: _borderColor,
                          size: 20,
                        ),
                      ),
                    Text(
                      unit.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? _borderColor : const Color(AppColors.textBlack),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _generateQuestions,
      style: ElevatedButton.styleFrom(
        backgroundColor: _borderColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 20),
                SizedBox(width: 8),
                Text(
                  'Generate Questions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildExampleCard() {
    String example = '';
    switch (_measurementType) {
      case MeasurementType.length:
        example = 'Example: "pencil" measured as "15" "Centimeters"';
        break;
      case MeasurementType.capacity:
        example = 'Example: "water bottle" measured as "500" "Milliliters"';
        break;
      case MeasurementType.weight:
        example = 'Example: "book" measured as "250" "Grams"';
        break;
      case MeasurementType.area:
        example = 'Example: "notebook" measured as "300" "Square Centimeters"';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: _borderColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              example,
              style: TextStyle(
                fontSize: 14,
                color: const Color(AppColors.textBlack).withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
