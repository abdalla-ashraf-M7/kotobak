import 'dart:convert';
import 'package:flutter/material.dart';

enum AnnotationType { highlight, underline, strikethrough, drawing, note }

class Annotation {
  final int? id;
  final String bookId;
  final int page;
  final AnnotationType type;
  final Color color;
  final double opacity;
  final List<Offset> points;
  final double strokeWidth;
  final DateTime createdAt;

  Annotation({
    this.id,
    required this.bookId,
    required this.page,
    required this.type,
    required this.color,
    required this.opacity,
    required this.points,
    required this.strokeWidth,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'page': page,
      'type': type.toString(),
      'color': color.value,
      'opacity': opacity,
      'points': jsonEncode(points.map((p) => {'x': p.dx, 'y': p.dy}).toList()),
      'strokeWidth': strokeWidth,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Annotation.fromMap(Map<String, dynamic> map) {
    final pointsList = (jsonDecode(map['points']) as List).map((p) => Offset(p['x'], p['y'])).toList();

    return Annotation(
      id: map['id'],
      bookId: map['bookId'],
      page: map['page'],
      type: AnnotationType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      color: Color(map['color']),
      opacity: map['opacity'],
      points: pointsList,
      strokeWidth: map['strokeWidth'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}

class DrawingLayer {
  final int? id;
  final String bookId;
  final int page;
  final String layerName;
  final bool isVisible;
  final Color strokeColor;
  final double strokeWidth;
  final double opacity;
  final List<Offset> points;
  final DateTime createdAt;

  DrawingLayer({
    this.id,
    required this.bookId,
    required this.page,
    required this.layerName,
    this.isVisible = true,
    required this.strokeColor,
    required this.strokeWidth,
    required this.opacity,
    required this.points,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'page': page,
      'layerName': layerName,
      'isVisible': isVisible ? 1 : 0,
      'strokeColor': strokeColor.value,
      'strokeWidth': strokeWidth,
      'opacity': opacity,
      'points': jsonEncode(points.map((p) => {'x': p.dx, 'y': p.dy}).toList()),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory DrawingLayer.fromMap(Map<String, dynamic> map) {
    final pointsList = (jsonDecode(map['points']) as List).map((p) => Offset(p['x'], p['y'])).toList();

    return DrawingLayer(
      id: map['id'],
      bookId: map['bookId'],
      page: map['page'],
      layerName: map['layerName'],
      isVisible: map['isVisible'] == 1,
      strokeColor: Color(map['strokeColor']),
      strokeWidth: map['strokeWidth'],
      opacity: map['opacity'],
      points: pointsList,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  DrawingLayer copyWith({
    int? id,
    String? bookId,
    int? page,
    String? layerName,
    bool? isVisible,
    Color? strokeColor,
    double? strokeWidth,
    double? opacity,
    List<Offset>? points,
    DateTime? createdAt,
  }) {
    return DrawingLayer(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      page: page ?? this.page,
      layerName: layerName ?? this.layerName,
      isVisible: isVisible ?? this.isVisible,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
