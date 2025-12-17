/// ARCore Measurement Widget - Pure ARCore implementation
/// 
/// Features:
/// - ARCore-based accurate distance measurement
/// - Plane detection visualization
/// - 3D measurement markers
/// - No camera conflicts

import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../services/arcore_service.dart';
import '../../models/ar_measurement.dart';

class ARCoreMeasurementWidget extends StatefulWidget {
  final Function(double value, String objectName, String? photoPath) onMeasurementComplete;
  final Color primaryColor;
  final MeasurementType measurementType;
  
  const ARCoreMeasurementWidget({
    Key? key,
    required this.onMeasurementComplete,
    required this.primaryColor,
    required this.measurementType,
  }) : super(key: key);

  @override
  State<ARCoreMeasurementWidget> createState() => _ARCoreMeasurementWidgetState();
}

class _ARCoreMeasurementWidgetState extends State<ARCoreMeasurementWidget> {
  final ARCoreService _arCoreService = ARCoreService();
  
  bool _isInitializing = true;
  String _statusMessage = 'Initializing ARCore...';
  
  Offset? _measurementStart;
  Offset? _measurementEnd;
  bool _isMeasuring = false;
  double? _measuredValue;
  String _objectName = '';
  
  late ArCoreController _arCoreController;
  int _pointsPlaced = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _statusMessage = 'Initializing ARCore...';
        _isInitializing = true;
      });

      // ARCore will initialize when view is created
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Move your device to detect surfaces';
      });

      print('✅ ARCore ready');
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Error: $e';
      });
      print('❌ ARCore initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _arCoreController.dispose();
    super.dispose();
  }

  void _onARCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;
    
    try {
      _arCoreController.onPlaneDetected = _onPlaneDetected;
      _arCoreController.onPlaneTap = _onPlaneTap;
      
      setState(() {
        _statusMessage = 'Tap to place measurement points';
      });
      
      print('✅ ARCore view created successfully');
    } catch (e) {
      setState(() {
        _statusMessage = 'ARCore error: $e';
      });
      print('❌ ARCore view creation error: $e');
    }
  }

  void _onPlaneDetected(ArCorePlane plane) {
    setState(() {
      _statusMessage = 'Surface detected! Tap to measure';
    });
  }

  void _onPlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty) return;
    if (!_isMeasuring) return;

    final hit = hits.first;
    final point = hit.pose.translation;

    if (_pointsPlaced == 0) {
      // First point
      _measurementStart = Offset(point.x, point.z);
      _pointsPlaced = 1;
      
      // Add visual marker
      _addMarker(point, Colors.green);
      
      setState(() {
        _statusMessage = 'Tap second point to complete measurement';
      });
      
      print('📍 First point placed: (${point.x}, ${point.y}, ${point.z})');
    } else if (_pointsPlaced == 1) {
      // Second point
      _measurementEnd = Offset(point.x, point.z);
      _pointsPlaced = 2;
      
      // Add visual marker
      _addMarker(point, Colors.red);
      
      // Calculate distance
      final distance = _calculateDistance();
      
      setState(() {
        _measuredValue = distance;
        _isMeasuring = false;
        _statusMessage = 'Measurement: ${distance.toStringAsFixed(1)} cm';
      });
      
      print('📍 Second point placed: (${point.x}, ${point.y}, ${point.z})');
      print('📏 Distance: ${distance.toStringAsFixed(1)} cm');
      
      // Show result dialog
      _showMeasurementResult(distance);
    }
  }

  void _addMarker(vm.Vector3 position, Color color) {
    final material = ArCoreMaterial(color: color);
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 0.02,
    );
    final node = ArCoreNode(
      shape: sphere,
      position: position,
    );
    _arCoreController.addArCoreNode(node);
  }

  double _calculateDistance() {
    if (_measurementStart == null || _measurementEnd == null) return 0;

    final dx = _measurementEnd!.dx - _measurementStart!.dx;
    final dy = _measurementEnd!.dy - _measurementStart!.dy;
    final distance = (dx * dx + dy * dy).abs();
    
    // Convert to centimeters (assuming meters from ARCore)
    return distance * 100;
  }

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _pointsPlaced = 0;
      _measurementStart = null;
      _measurementEnd = null;
      _statusMessage = 'Tap first point on surface';
    });
    
    print('🎯 Starting ARCore measurement');
  }

  void _showMeasurementResult(double value) {
    // Show dialog to name the object
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name the Object'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${value.toStringAsFixed(1)} cm',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Object name',
                hintText: 'e.g., desk, pencil, book',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => _objectName = val,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isMeasuring = false;
                _pointsPlaced = 0;
                _statusMessage = 'Tap Measure to start';
              });
            },
            child: const Text('Retry'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_objectName.isEmpty) {
                _objectName = widget.measurementType.displayName;
              }
              Navigator.pop(context);
              widget.onMeasurementComplete(value, _objectName, null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: widget.primaryColor),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // ARCore camera view
        ArCoreView(
          onArCoreViewCreated: _onARCoreViewCreated,
          enableTapRecognizer: true,
        ),
        
        // Status bar at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_pointsPlaced > 0)
                    Text(
                      'Points placed: $_pointsPlaced/2',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // Controls at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Measure button
                  if (!_isMeasuring)
                    ElevatedButton.icon(
                      onPressed: _startMeasurement,
                      icon: const Icon(Icons.straighten),
                      label: const Text('Start Measurement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  
                  // Cancel button while measuring
                  if (_isMeasuring)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isMeasuring = false;
                          _pointsPlaced = 0;
                          _statusMessage = 'Tap Measure to start';
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
