import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'dart:math' as math;

class HighQuality3DShape extends StatefulWidget {
  final String shapeName;
  final Color shapeColor;
  final double rotationX;
  final double rotationY;
  final double size;

  const HighQuality3DShape({
    super.key,
    required this.shapeName,
    required this.shapeColor,
    required this.rotationX,
    required this.rotationY,
    this.size = 200,
  });

  @override
  State<HighQuality3DShape> createState() => _HighQuality3DShapeState();
}

class _HighQuality3DShapeState extends State<HighQuality3DShape> {
  late Object cube;
  late Object sphere;
  late Object pyramid;
  late Object cone;
  late Object cylinder;
  late Scene _scene;

  @override
  void initState() {
    super.initState();
    _scene = Scene();
    _create3DShapes();
  }

  @override
  void didUpdateWidget(HighQuality3DShape oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild scene if shape name changed
    if (oldWidget.shapeName != widget.shapeName) {
      _scene.world.children.clear();
      _scene.world.add(_getCurrentShape());
    }
  }

  void _create3DShapes() {
    // Create Cube
    cube = Object(name: 'cube');
    final cubeSize = 1.0;
    
    // Cube vertices (8 corners)
    final cubeVertices = [
      Vector3(-cubeSize, -cubeSize, -cubeSize), // 0
      Vector3(cubeSize, -cubeSize, -cubeSize),  // 1
      Vector3(cubeSize, cubeSize, -cubeSize),   // 2
      Vector3(-cubeSize, cubeSize, -cubeSize),  // 3
      Vector3(-cubeSize, -cubeSize, cubeSize),  // 4
      Vector3(cubeSize, -cubeSize, cubeSize),   // 5
      Vector3(cubeSize, cubeSize, cubeSize),    // 6
      Vector3(-cubeSize, cubeSize, cubeSize),   // 7
    ];

    final cubeMesh = Mesh();
    cubeMesh.vertices = cubeVertices;
    
    // Add faces as Polygon objects (Polygon takes 3 separate int args)
    cubeMesh.indices.add(Polygon(0, 1, 2));
    cubeMesh.indices.add(Polygon(0, 2, 3));
    cubeMesh.indices.add(Polygon(4, 7, 6));
    cubeMesh.indices.add(Polygon(4, 6, 5));
    cubeMesh.indices.add(Polygon(3, 2, 6));
    cubeMesh.indices.add(Polygon(3, 6, 7));
    cubeMesh.indices.add(Polygon(0, 5, 1));
    cubeMesh.indices.add(Polygon(0, 4, 5));
    cubeMesh.indices.add(Polygon(1, 5, 6));
    cubeMesh.indices.add(Polygon(1, 6, 2));
    cubeMesh.indices.add(Polygon(0, 3, 7));
    cubeMesh.indices.add(Polygon(0, 7, 4));
    
    cube.mesh = cubeMesh;
    cube.lighting = true;

    // Create Sphere
    sphere = Object(name: 'sphere');
    sphere.mesh = _createSphereMesh(1.0, 24, 24);
    sphere.lighting = true;

    // Create Pyramid
    pyramid = Object(name: 'pyramid');
    pyramid.mesh = _createPyramidMesh(1.5);
    pyramid.lighting = true;

    // Create Cone
    cone = Object(name: 'cone');
    cone.mesh = _createConeMesh(1.0, 2.0, 24);
    cone.lighting = true;

    // Create Cylinder
    cylinder = Object(name: 'cylinder');
    cylinder.mesh = _createCylinderMesh(1.0, 2.0, 24);
    cylinder.lighting = true;
  }

  Mesh _createSphereMesh(double radius, int latSegments, int lonSegments) {
    final mesh = Mesh();
    final vertices = <Vector3>[];
    
    for (int lat = 0; lat <= latSegments; lat++) {
      final theta = lat * math.pi / latSegments;
      final sinTheta = math.sin(theta);
      final cosTheta = math.cos(theta);

      for (int lon = 0; lon <= lonSegments; lon++) {
        final phi = lon * 2 * math.pi / lonSegments;
        final sinPhi = math.sin(phi);
        final cosPhi = math.cos(phi);

        final x = cosPhi * sinTheta;
        final y = cosTheta;
        final z = sinPhi * sinTheta;

        vertices.add(Vector3(radius * x, radius * y, radius * z));
      }
    }

    mesh.vertices = vertices;

    // Create indices as Polygon objects (3 separate args, not list)
    for (int lat = 0; lat < latSegments; lat++) {
      for (int lon = 0; lon < lonSegments; lon++) {
        final first = lat * (lonSegments + 1) + lon;
        final second = first + lonSegments + 1;

        mesh.indices.add(Polygon(first, second, first + 1));
        mesh.indices.add(Polygon(second, second + 1, first + 1));
      }
    }

    return mesh;
  }

  Mesh _createPyramidMesh(double size) {
    final mesh = Mesh();
    
    final vertices = [
      Vector3(0, size, 0),           // Top
      Vector3(-size, -size, size),   // Front left
      Vector3(size, -size, size),    // Front right
      Vector3(size, -size, -size),   // Back right
      Vector3(-size, -size, -size),  // Back left
    ];

    mesh.vertices = vertices;
    
    // Pyramid faces as Polygon objects (3 separate args)
    mesh.indices.add(Polygon(0, 1, 2)); // Front
    mesh.indices.add(Polygon(0, 2, 3)); // Right
    mesh.indices.add(Polygon(0, 3, 4)); // Back
    mesh.indices.add(Polygon(0, 4, 1)); // Left
    mesh.indices.add(Polygon(1, 4, 3)); // Bottom 1
    mesh.indices.add(Polygon(1, 3, 2)); // Bottom 2

    return mesh;
  }

  Mesh _createConeMesh(double radius, double height, int segments) {
    final mesh = Mesh();
    final vertices = <Vector3>[];
    
    // Top vertex
    vertices.add(Vector3(0, height / 2, 0));
    
    // Base vertices
    for (int i = 0; i <= segments; i++) {
      final angle = 2 * math.pi * i / segments;
      final x = radius * math.cos(angle);
      final z = radius * math.sin(angle);
      vertices.add(Vector3(x, -height / 2, z));
    }
    
    // Center of base
    vertices.add(Vector3(0, -height / 2, 0));
    
    mesh.vertices = vertices;

    // Cone sides as Polygon objects (3 separate args)
    for (int i = 0; i < segments; i++) {
      mesh.indices.add(Polygon(0, i + 1, i + 2));
    }

    // Base
    final baseCenter = vertices.length - 1;
    for (int i = 0; i < segments; i++) {
      mesh.indices.add(Polygon(baseCenter, i + 2, i + 1));
    }

    return mesh;
  }

  Mesh _createCylinderMesh(double radius, double height, int segments) {
    final mesh = Mesh();
    final vertices = <Vector3>[];
    
    // Top circle
    for (int i = 0; i <= segments; i++) {
      final angle = 2 * math.pi * i / segments;
      final x = radius * math.cos(angle);
      final z = radius * math.sin(angle);
      vertices.add(Vector3(x, height / 2, z));
    }
    
    // Bottom circle
    for (int i = 0; i <= segments; i++) {
      final angle = 2 * math.pi * i / segments;
      final x = radius * math.cos(angle);
      final z = radius * math.sin(angle);
      vertices.add(Vector3(x, -height / 2, z));
    }
    
    // Center top
    vertices.add(Vector3(0, height / 2, 0));
    // Center bottom
    vertices.add(Vector3(0, -height / 2, 0));
    
    mesh.vertices = vertices;

    // Cylinder sides as Polygon objects (3 separate args)
    for (int i = 0; i < segments; i++) {
      final topFirst = i;
      final topSecond = i + 1;
      final bottomFirst = i + segments + 1;
      final bottomSecond = i + segments + 2;
      
      mesh.indices.add(Polygon(topFirst, bottomFirst, topSecond));
      mesh.indices.add(Polygon(topSecond, bottomFirst, bottomSecond));
    }

    // Top cap
    final topCenter = vertices.length - 2;
    for (int i = 0; i < segments; i++) {
      mesh.indices.add(Polygon(topCenter, i, i + 1));
    }

    // Bottom cap
    final bottomCenter = vertices.length - 1;
    for (int i = 0; i < segments; i++) {
      final first = i + segments + 1;
      final second = i + segments + 2;
      mesh.indices.add(Polygon(bottomCenter, second, first));
    }

    return mesh;
  }

  Object _getCurrentShape() {
    switch (widget.shapeName) {
      case 'Cube':
        return cube;
      case 'Sphere':
        return sphere;
      case 'Pyramid':
        return pyramid;
      case 'Cone':
        return cone;
      case 'Cylinder':
        return cylinder;
      default:
        return cube;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentShape = _getCurrentShape();
    
    // Update rotation
    currentShape.rotation.setValues(widget.rotationX, widget.rotationY, 0);

    return Cube(
      onSceneCreated: (Scene scene) {
        _scene = scene;
        scene.world.add(currentShape);
        
        // Set up lighting
        scene.light.position.setValues(3, 3, 3);
        
        // Set up camera
        scene.camera.position.z = 5;
        scene.camera.target.setValues(0, 0, 0);
      },
    );
  }
}
