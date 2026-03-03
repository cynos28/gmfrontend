import 'package:flutter/material.dart';

class ShapeModel {
  final String id;
  final String name;
  final String type;
  final int? sides;
  final int? corners;
  final int? faces;
  final int? edges;
  final int? vertices;
  final String color;
  final String description;
  final String imageUrl;
  final ShapeProperties properties;
  final List<RealWorldExample> realWorldExamples;

  ShapeModel({
    required this.id,
    required this.name,
    required this.type,
    this.sides,
    this.corners,
    this.faces,
    this.edges,
    this.vertices,
    required this.color,
    required this.description,
    required this.imageUrl,
    required this.properties,
    required this.realWorldExamples,
  });

  factory ShapeModel.fromJson(Map<String, dynamic> json) {
    return ShapeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      sides: json['sides'],
      corners: json['corners'],
      faces: json['faces'],
      edges: json['edges'],
      vertices: json['vertices'],
      color: json['color'] ?? '#000000',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      properties: ShapeProperties.fromJson(json['properties'] ?? {}),
      realWorldExamples: (json['real_world_examples'] as List<dynamic>?)
              ?.map((e) => RealWorldExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.black;
    }
  }

  String get propertiesText {
    if (type == '2d') {
      return '${sides ?? 0} sides, ${corners ?? 0} corners';
    } else {
      return '${faces ?? 0} faces, ${edges ?? 0} edges, ${vertices ?? 0} vertices';
    }
  }
}

class ShapeProperties {
  final bool hasCurves;
  final bool isRegular;
  final String? symmetryLines;
  final String? volumeFormula;

  ShapeProperties({
    required this.hasCurves,
    required this.isRegular,
    this.symmetryLines,
    this.volumeFormula,
  });

  factory ShapeProperties.fromJson(Map<String, dynamic> json) {
    return ShapeProperties(
      hasCurves: json['has_curves'] ?? false,
      isRegular: json['is_regular'] ?? false,
      symmetryLines: json['symmetry_lines'],
      volumeFormula: json['volume_formula'],
    );
  }
}

class RealWorldExample {
  final String name;
  final String emoji;
  final String category;

  RealWorldExample({
    required this.name,
    required this.emoji,
    required this.category,
  });

  factory RealWorldExample.fromJson(Map<String, dynamic> json) {
    return RealWorldExample(
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '',
      category: json['category'] ?? '',
    );
  }
}
