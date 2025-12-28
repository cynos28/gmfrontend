import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

// AR plugin (updated fork)
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';

class ARLengthMeasureScreen extends StatefulWidget {
  const ARLengthMeasureScreen({Key? key}) : super(key: key);

  @override
  State<ARLengthMeasureScreen> createState() => _ARLengthMeasureScreenState();
}

class _ARLengthMeasureScreenState extends State<ARLengthMeasureScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  Vector3? startPoint;
  Vector3? endPoint;
  double? lengthMeters;

  bool isStartPointSet = false;

  // Nodes to visually mark start and end points
  ARNode? startNode;
  ARNode? endNode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("AR Length Measure"),
        backgroundColor: Colors.black,
        actions: [
          if (isStartPointSet)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // Instructions overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _getInstructionText(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Point at a flat surface to detect planes",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Measurement result
          if (lengthMeters != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Measured Length",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${(lengthMeters! * 100).toStringAsFixed(1)} cm",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${lengthMeters!.toStringAsFixed(3)} meters",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: lengthMeters != null
          ? FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check),
        label: const Text("Use Measurement"),
        onPressed: _confirmMeasurement,
      )
          : null,
    );
  }

  String _getInstructionText() {
    if (!isStartPointSet) {
      return "Tap on a detected plane to set start point";
    } else if (lengthMeters == null) {
      return "Tap again to set end point and measure";
    } else {
      return "Measurement complete! Tap confirm to use";
    }
  }

  void _onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    this.arObjectManager!.onInitialize();

    // Handle taps on planes
    this.arSessionManager!.onPlaneOrPointTap = _onPlaneTapped;
  }

  void _onPlaneTapped(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty) {
      _showSnackBar('No surface detected. Try pointing at a flat surface.');
      return;
    }

    final hitResult = hitTestResults.first;

    // Extract position from world transform
    final position = Vector3(
      hitResult.worldTransform.getColumn(3).x,
      hitResult.worldTransform.getColumn(3).y,
      hitResult.worldTransform.getColumn(3).z,
    );

    if (!isStartPointSet) {
      await _setStartPoint(position);
    } else {
      await _setEndPoint(position);
    }
  }

  Future<void> _setStartPoint(Vector3 point) async {
    // Remove previous start node if exists
    if (startNode != null) {
      await arObjectManager?.removeNode(startNode!);
      startNode = null;
    }

    // Create a small sphere marker for the start point
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/models/ar/sphere.gltf",
      scale: Vector3.all(0.02), // small sphere
      position: point,
    );

    final didAdd = await arObjectManager?.addNode(node) ?? false;
    if (!didAdd) {
      _showSnackBar('Failed to place start point marker');
      return;
    }

    setState(() {
      startPoint = point;
      isStartPointSet = true;
      lengthMeters = null;
      endPoint = null;
      startNode = node;

      // If you want end marker cleared as well
      endNode = null;
    });

    _showSnackBar('Start point set. Tap again for end point.', isSuccess: true);
  }

  Future<void> _setEndPoint(Vector3 point) async {
    if (startPoint == null) {
      _showSnackBar('Start point not set');
      return;
    }

    // Remove previous end node if exists
    if (endNode != null) {
      await arObjectManager?.removeNode(endNode!);
      endNode = null;
    }

    // Create a small sphere marker for the end point
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/models/ar/sphere.gltf",
      scale: Vector3.all(0.02),
      position: point,
    );

    final didAdd = await arObjectManager?.addNode(node) ?? false;
    if (!didAdd) {
      _showSnackBar('Failed to place end point marker');
      return;
    }

    setState(() {
      endPoint = point;
      endNode = node;

      // Calculate distance in meters
      final dx = endPoint!.x - startPoint!.x;
      final dy = endPoint!.y - startPoint!.y;
      final dz = endPoint!.z - startPoint!.z;

      lengthMeters = math.sqrt(dx * dx + dy * dy + dz * dz);
    });

    _showSnackBar(
      'Measurement: ${(lengthMeters! * 100).toStringAsFixed(1)} cm',
      isSuccess: true,
    );
  }

  void _reset() async {
    // Remove markers from AR scene
    if (startNode != null) {
      await arObjectManager?.removeNode(startNode!);
      startNode = null;
    }
    if (endNode != null) {
      await arObjectManager?.removeNode(endNode!);
      endNode = null;
    }

    setState(() {
      startPoint = null;
      endPoint = null;
      lengthMeters = null;
      isStartPointSet = false;
    });

    _showSnackBar('Measurement reset. Tap to start again.');
  }

  void _confirmMeasurement() {
    if (lengthMeters == null) {
      _showSnackBar('No measurement to confirm');
      return;
    }

    final valueInCm = (lengthMeters! * 100).toStringAsFixed(1);
    Get.back(result: valueInCm);
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }
}