import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';

import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';

import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';

import 'package:ar_flutter_plugin_updated/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';

/// Tap 2 points -> measure distance.
/// Navigator.pop returns double meters.
class ARMeasureView extends StatefulWidget {
  const ARMeasureView({Key? key}) : super(key: key);

  @override
  State<ARMeasureView> createState() => _ARMeasureViewState();
}

class _ARMeasureViewState extends State<ARMeasureView> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;

  final List<ARAnchor> _anchors = [];
  final List<ARNode> _anchorNodes = [];
  final List<ARNode> _lineNodes = [];

  double _measuredMeters = 0.0;
  String _status = 'Move phone to detect planes, then tap 2 points';

  final Vector3 _markerScale = Vector3(0.03, 0.03, 0.03);
  final Vector3 _dotScale = Vector3(0.01, 0.01, 0.01);
  final int _lineDots = 20;

  // Strongly recommended to use a single-file .glb for this plugin
  final String _modelAsset = 'assets/models/ar/sphere.glb';

  String? _modelDocFullPath;
  String? _modelDocFileName;

  bool _ready = false;

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    // Remove nodes/anchors first
    try {
      await _resetAll();
    } catch (_) {}

    // Avoid calling methods that don't exist in 0.0.1
    try {
  arSessionManager?.onPlaneOrPointTap = (List<ARHitTestResult> _) {};
    } catch (_) {}

    try {
      arSessionManager?.dispose();
    } catch (_) {}
  }

  Future<void> _prepareModel() async {
    final data = await rootBundle.load(_modelAsset);
    final bytes = data.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final fileName = _modelAsset.split('/').last;
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    _modelDocFullPath = file.path;
    _modelDocFileName = fileName;
  }

  Future<ARNode?> _addMarkerNode({
    required String name,
    required Matrix4 transform,
    required Vector3 scale,
  }) async {
    final o = arObjectManager;
    if (o == null) return null;

    // 1) Try asset
    try {
      final node1 = ARNode(
        type: NodeType.localGLTF2,
        uri: _modelAsset,
        scale: scale,
        name: name,
        transformation: transform,
      );
      final ok = await o.addNode(node1);
      if (ok == true) return node1;
    } catch (_) {}

    // 2) Try documents file name (GLB)
    if (_modelDocFileName != null) {
      try {
        final node2 = ARNode(
          type: NodeType.fileSystemAppFolderGLB,
          uri: _modelDocFileName!,
          scale: scale,
          name: name,
          transformation: transform,
        );
        final ok = await o.addNode(node2);
        if (ok == true) return node2;
      } catch (_) {}
    }

    // 3) Try full path (GLB)
    if (_modelDocFullPath != null) {
      try {
        final node3 = ARNode(
          type: NodeType.fileSystemAppFolderGLB,
          uri: _modelDocFullPath!,
          scale: scale,
          name: name,
          transformation: transform,
        );
        final ok = await o.addNode(node3);
        if (ok == true) return node3;
      } catch (_) {}
    }

    return null;
  }

  Future<void> _onARViewCreated(
    ARSessionManager s,
    ARObjectManager o,
    ARAnchorManager a,
    ARLocationManager l,
  ) async {
    arSessionManager = s;
    arObjectManager = o;
    arAnchorManager = a;
    arLocationManager = l;

    arSessionManager?.onInitialize(
      showFeaturePoints: true, // helps tracking early
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    try {
      await arObjectManager?.onInitialize();
    } catch (_) {}

    try {
      await _prepareModel();
    } catch (_) {
      setState(() => _status = 'Missing model: $_modelAsset');
      return;
    }

    arSessionManager?.onPlaneOrPointTap = _onTap;

    setState(() {
      _ready = true;
      _status = 'Tap 2 points to measure';
    });
  }

  Future<void> _onTap(List<ARHitTestResult> hits) async {
    if (!_ready) return;

    if (hits.isEmpty) {
      setState(() => _status = 'No hit. Move phone and try again.');
      return;
    }

    // Prefer plane hits. If you get point hits, we still anchor using ARPlaneAnchor
    final hit = hits.firstWhere(
      (h) => h.type == ARHitTestResultType.plane,
      orElse: () => hits.first,
    );

    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final ok = await arAnchorManager?.addAnchor(anchor);

    if (ok != true) {
      setState(() => _status = 'Failed to add anchor. Try another spot.');
      return;
    }

    // Keep only 2 anchors (remove oldest)
    if (_anchors.length >= 2) {
      await _removeOldest();
    }

    _anchors.add(anchor);

    final isStart = _anchors.length == 1;
    final transform = _matrixFromTransform(anchor.transformation);

    final node = await _addMarkerNode(
      name: isStart ? 'start_marker' : 'end_marker',
      transform: transform,
      scale: _markerScale,
    );
    if (node != null) _anchorNodes.add(node);

    if (_anchors.length == 2) {
      _updateDistance();
      await _drawDottedLine();
      setState(() => _status = 'Distance: ${_formattedDistance()}');
    } else {
      setState(() {
        _measuredMeters = 0.0;
        _status = 'Tap second point';
      });
    }
  }

  Matrix4 _matrixFromTransform(dynamic t) {
    if (t is Matrix4) return t;
    if (t is List && t.length >= 16) {
      return Matrix4.fromList(
        List<double>.from(t.map((e) => (e as num).toDouble())),
      );
    }
    return Matrix4.identity();
  }

  Vector3 _posFromTransform(dynamic t) {
    try {
      if (t is Matrix4) {
        final s = t.storage;
        return Vector3(s[12], s[13], s[14]);
      }
      if (t is List && t.length >= 16) {
        return Vector3(
          (t[12] as num).toDouble(),
          (t[13] as num).toDouble(),
          (t[14] as num).toDouble(),
        );
      }
    } catch (_) {}
    return Vector3.zero();
  }

  void _updateDistance() {
    if (_anchors.length < 2) return;

    final p1 = _posFromTransform(_anchors[0].transformation);
    final p2 = _posFromTransform(_anchors[1].transformation);

    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    final dz = p1.z - p2.z;

    setState(() {
      _measuredMeters = math.sqrt(dx * dx + dy * dy + dz * dz);
    });
  }

  Future<void> _drawDottedLine() async {
    // remove old dots
    for (final n in _lineNodes) {
      try {
        await arObjectManager?.removeNode(n);
      } catch (_) {}
    }
    _lineNodes.clear();

    if (_anchors.length < 2) return;

    final p1 = _posFromTransform(_anchors[0].transformation);
    final p2 = _posFromTransform(_anchors[1].transformation);

    for (int i = 1; i <= _lineDots; i++) {
      final t = i / (_lineDots + 1);
      final pos = Vector3(
        p1.x + (p2.x - p1.x) * t,
        p1.y + (p2.y - p1.y) * t,
        p1.z + (p2.z - p1.z) * t,
      );

      final transform = Matrix4.identity()..setTranslation(pos);

      final node = await _addMarkerNode(
        name: 'dot_$i',
        transform: transform,
        scale: _dotScale,
      );
      if (node != null) _lineNodes.add(node);
    }
  }

  Future<void> _removeOldest() async {
    if (_anchors.isNotEmpty) {
      final oldA = _anchors.removeAt(0);
      try {
        await arAnchorManager?.removeAnchor(oldA);
      } catch (_) {}
    }

    if (_anchorNodes.isNotEmpty) {
      final oldN = _anchorNodes.removeAt(0);
      try {
        await arObjectManager?.removeNode(oldN);
      } catch (_) {}
    }

    for (final n in _lineNodes) {
      try {
        await arObjectManager?.removeNode(n);
      } catch (_) {}
    }
    _lineNodes.clear();
  }

  Future<void> _resetAll() async {
    for (final n in _lineNodes) {
      try {
        await arObjectManager?.removeNode(n);
      } catch (_) {}
    }
    _lineNodes.clear();

    for (final n in _anchorNodes) {
      try {
        await arObjectManager?.removeNode(n);
      } catch (_) {}
    }
    _anchorNodes.clear();

    for (final a in List<ARAnchor>.from(_anchors)) {
      try {
        await arAnchorManager?.removeAnchor(a);
      } catch (_) {}
    }
    _anchors.clear();

    if (mounted) {
      setState(() {
        _measuredMeters = 0.0;
        _status = 'Tap 2 points to measure';
      });
    }
  }

  String _formattedDistance() {
    if (_measuredMeters >= 1.0) return '${_measuredMeters.toStringAsFixed(2)} m';
    return '${(_measuredMeters * 100).toStringAsFixed(1)} cm';
  }

  void _returnMeasuredValue() {
    if (_anchors.length < 2) return;
    Navigator.of(context).pop(_measuredMeters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Measure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAll,
            tooltip: 'Reset',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _anchors.length >= 2 ? _returnMeasuredValue : null,
            tooltip: 'Use this value',
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _anchors.length >= 2 ? 'Distance: ${_formattedDistance()}' : _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}