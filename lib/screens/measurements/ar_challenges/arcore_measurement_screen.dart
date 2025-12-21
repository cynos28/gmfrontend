/// ARCore Measurement Screen - Pure ARCore implementation
/// 
/// This screen allows students to:
/// 1. Use ARCore to measure objects accurately
/// 2. Generate personalized questions about their measurement

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/ar_measurement.dart';
import '../../services/ar_learning_service.dart';
import '../../widgets/measurements/arcore_measurement_widget.dart';
import '../../utils/constants.dart';
import 'ar_questions_screen.dart';

class ARCoreMeasurementScreen extends StatefulWidget {
  const ARCoreMeasurementScreen({Key? key}) : super(key: key);

  @override
  State<ARCoreMeasurementScreen> createState() => _ARCoreMeasurementScreenState();
}

class _ARCoreMeasurementScreenState extends State<ARCoreMeasurementScreen> {
  final ARLearningService _arService = ARLearningService();
  final TextEditingController _objectController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  
  late MeasurementType _measurementType;
  MeasurementUnit? _selectedUnit;
  bool _isProcessing = false;
  String? _sessionId;
  bool _showARView = true;
  
  late Color _primaryColor;
  late Color _borderColor;

  @override
  void initState() {
    super.initState();
    
    // Get measurement type from route arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final typeString = args?['type'] as String? ?? 'length';
    
    _measurementType = _parseMeasurementType(typeString);
    _selectedUnit = MeasurementUnit.cm; // Default to cm
    _primaryColor = _getTypeColor();
    _borderColor = _primaryColor.withOpacity(0.3);
    
    // Start AR session
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _objectController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Color _getTypeColor() {
    switch (_measurementType) {
      case MeasurementType.length:
        return Colors.blue;
      case MeasurementType.capacity:
        return Colors.orange;
      case MeasurementType.weight:
        return Colors.green;
      case MeasurementType.area:
        return Colors.purple;
    }
  }

  void _onARMeasurementComplete(double value, String objectName, String? photoPath) {
    setState(() {
      _objectController.text = objectName;
      _valueController.text = value.toStringAsFixed(1);
      _showARView = false;
    });
    
    Get.snackbar(
      'Measurement Complete',
      '$objectName: ${value.toStringAsFixed(1)} cm',
      backgroundColor: _primaryColor.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
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

  Future<void> _generateQuestions() async {
    if (_objectController.text.isEmpty || _valueController.text.isEmpty) {
      Get.snackbar(
        'Missing Information',
        'Please complete the measurement first',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final value = double.parse(_valueController.text);
      final unit = _selectedUnit ?? MeasurementUnit.cm;

      final measurement = ARMeasurement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        value: value,
        unit: unit,
        objectName: _objectController.text,
      );

      // Generate questions (simplified - direct navigation)
      setState(() => _isProcessing = false);
      
      Get.snackbar(
        'Success',
        'Measurement saved! Questions feature coming soon.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // TODO: Integrate with question generation service
      // final questions = await _arService.generateQuestions(...);
      // Get.toNamed('/ar-questions', arguments: {'questions': questions});
    } catch (e) {
      setState(() => _isProcessing = false);
      Get.snackbar(
        'Error',
        'Failed to generate questions: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Measure ${_measurementType.displayName}'),
        backgroundColor: _primaryColor,
        actions: [
          if (!_showARView)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                setState(() => _showARView = true);
              },
              tooltip: 'Measure Again',
            ),
        ],
      ),
      body: SafeArea(
        child: _showARView
            ? ARCoreMeasurementWidget(
                onMeasurementComplete: _onARMeasurementComplete,
                primaryColor: _primaryColor,
                measurementType: _measurementType,
              )
            : _buildResultsView(),
      ),
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: _primaryColor, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'Measurement Complete!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_objectController.text}: ${_valueController.text} cm',
                  style: TextStyle(
                    fontSize: 18,
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Object name
          Text(
            'Object',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _objectController,
            decoration: InputDecoration(
              hintText: 'Object name',
              filled: true,
              fillColor: const Color(0xFFF7FAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor, width: 1.5),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Value
          Text(
            'Measurement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Value',
              suffixText: 'cm',
              filled: true,
              fillColor: const Color(0xFFF7FAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor, width: 1.5),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Generate questions button
          ElevatedButton(
            onPressed: _isProcessing ? null : _generateQuestions,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                : const Text(
                    'Generate Questions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
