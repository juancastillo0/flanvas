import 'dart:ui';

import 'package:flanvas/utils.dart';

sealed class CanvasOp {
  const CanvasOp();
  Map<String, Object?> toJson();
  String toSvg();
  bool get isGroup => false;

  @override
  bool operator ==(Object other) {
    if (other is! CanvasOp) return false;
    return jsonEqual(toJson(), other.toJson());
  }

  @override
  int get hashCode => Object.hashAll(jsonEntries(toJson())!);

  factory CanvasOp.fromJson(Map<String, Object?> json) {
    return switch (json['op'] as String) {
      'arc' => ArcOp.fromJson(json),
      'circle' => CircleOp.fromJson(json),
      'line' => LineOp.fromJson(json),
      'rect' => RectOp.fromJson(json),
      'points' => PointsOp.fromJson(json),
      'color' => ColorOp.fromJson(json),
      'rotate' => RotateOp.fromJson(json),
      'transform' => AxisTransformOp.fromJson(json),
      _ => throw Exception('CanvasOp.fromJson no "op" found $json'),
    };
  }
}

sealed class TransformCanvasOp extends CanvasOp {
  @override
  bool get isGroup => true;
}

class ArcOp extends CanvasOp {
  final Rect rect;
  final double startAngle;
  final double sweepAngle;
  final bool useCenter;

  ArcOp({
    required this.rect,
    required this.startAngle,
    required this.sweepAngle,
    required this.useCenter,
  });

  factory ArcOp.fromJson(Map<String, Object?> json) => ArcOp(
    rect: JsonUtils.rectFromJson(json['rect'] as Map),
    startAngle: (json['startAngle'] as num).toDouble(),
    sweepAngle: (json['sweepAngle'] as num).toDouble(),
    useCenter: json['useCenter'] as bool,
  );
  @override
  Map<String, Object?> toJson() => {
    'op': 'arc',
    'rect': JsonUtils.rectToJson(rect),
    'startAngle': startAngle,
    'sweepAngle': sweepAngle,
    'useCenter': useCenter,
  };

  /// A rx ry x-axis-rotation large-arc-flag sweep-flag x y
  /// // TODO: sweepAngle
  @override
  String toSvg() =>
      '<path d="A ${rect.width.str} ${rect.height.str} ${startAngle.str}'
      ' ${useCenter ? 1 : 0} 1 ${rect.left.str} ${rect.top.str}"/>';
  @override
  String toString() => 'ArcOp${toJson()}';
}

class CircleOp extends CanvasOp {
  final Offset c;
  final double radius;

  CircleOp({required this.c, required this.radius});
  factory CircleOp.fromJson(Map<String, Object?> json) => CircleOp(
    c: JsonUtils.offsetFromJson(json['c'] as Map),
    radius: (json['radius'] as num).toDouble(),
  );
  @override
  Map<String, Object?> toJson() => {
    'op': 'circle',
    'c': JsonUtils.offsetToJson(c),
    'radius': radius,
  };

  /// <circle cx="25" cy="75" r="20"/>
  @override
  String toSvg() =>
      '<circle dx="${c.dx.str}" dy="${c.dy.str}" r="${radius.str}"/>';
  @override
  String toString() => 'CircleOp${toJson()}';
}

class LineOp extends CanvasOp {
  final Offset p1;
  final Offset p2;

  LineOp({required this.p1, required this.p2});
  factory LineOp.fromJson(Map<String, Object?> json) => LineOp(
    p1: JsonUtils.offsetFromJson(json['p1'] as Map),
    p2: JsonUtils.offsetFromJson(json['p2'] as Map),
  );
  @override
  Map<String, Object?> toJson() => {
    'op': 'line',
    'p1': JsonUtils.offsetToJson(p1),
    'p2': JsonUtils.offsetToJson(p2),
  };

  /// <line x1="10" x2="50" y1="110" y2="150" stroke="black" stroke-width="5"/>
  @override
  String toSvg() =>
      '<line x1="${p1.dx.str}" x2="${p2.dx.str}" y1="${p1.dy.str}" y2="${p2.dy.str}"/>';
  @override
  String toString() => 'LineOp${toJson()}';
}

class RectOp extends CanvasOp {
  final Rect rect;

  RectOp({required this.rect});

  factory RectOp.fromJson(Map<String, Object?> json) =>
      RectOp(rect: JsonUtils.rectFromJson(json['rect'] as Map));
  @override
  Map<String, Object?> toJson() => {
    'op': 'rect',
    'rect': JsonUtils.rectToJson(rect),
  };

  /// <rect x="60" y="10" rx="10" ry="10" width="30" height="30"/>
  @override
  String toSvg() =>
      '<rect x="${rect.left.str}" y="${rect.top.str}"'
      ' width="${rect.width.str}" height="${rect.height.str}"/>';
  @override
  String toString() => 'RectOp${toJson()}';
}

class PointsOp extends CanvasOp {
  final PointMode pointMode;
  final List<Offset> points;

  PointsOp({required this.pointMode, required this.points});

  factory PointsOp.fromJson(Map<String, Object?> json) => PointsOp(
    points:
        (json['points'] as List)
            .cast<Map>()
            .map(JsonUtils.offsetFromJson)
            .toList(),
    pointMode: PointMode.values.byName(json['pointMode'] as String),
  );
  @override
  Map<String, Object?> toJson() => {
    'op': 'points',
    'points': points.map(JsonUtils.offsetToJson).toList(growable: false),
    'pointMode': pointMode.name,
  };

  // TODO: render only points
  /// <polyline points="60, 110 65, 120 70, 115 75, 130 80, 125 85, 140 90, 135 95, 150 100, 145"/>
  @override
  String toSvg() {
    String allPoints = points.map((p) => '${p.dx.str},${p.dy.str}').join(' ');
    return '<${pointMode == PointMode.lines ? 'polyline' : 'polygon'} points="$allPoints"/>';
  }

  @override
  String toString() => 'PointsOp${toJson()}';
}

String colorHex(Color color) => color.toARGB32().toRadixString(16);

class ColorOp extends TransformCanvasOp {
  final Color color;
  final BlendMode blendMode;

  ColorOp({required this.color, required this.blendMode});

  factory ColorOp.fromJson(Map<String, Object?> json) => ColorOp(
    color: Color(
      int.parse(
        (json['color'] as String).replaceAll('#', '').toLowerCase(),
        radix: 16,
      ),
    ),
    blendMode: BlendMode.values.byName(json['blendMode'] as String),
  );
  @override
  Map<String, Object?> toJson() => {
    'op': 'color',
    'color': colorHex(color),
    'blendMode': blendMode.name,
  };
  @override
  String toSvg() => '<g fill="#${colorHex(color)}">';

  @override
  String toString() => 'ColorOp${toJson()}';
}

class RotateOp extends TransformCanvasOp {
  final double radians;

  RotateOp({required this.radians});

  factory RotateOp.fromJson(Map<String, Object?> json) =>
      RotateOp(radians: (json['radians'] as num).toDouble());
  @override
  Map<String, Object?> toJson() => {'op': 'rotate', 'radians': radians};

  /// <g transform="rotate(2)"></g>
  @override
  String toSvg() => '<g transform="rotate(${radians.str})">';

  @override
  String toString() => 'RotateOp${toJson()}';
}

class AxisTransformOp extends TransformCanvasOp {
  // TODO: flip?
  final AxisTransformKind kind;
  final double dx;
  final double dy;

  AxisTransformOp({required this.kind, required this.dx, required this.dy});

  factory AxisTransformOp.fromJson(Map<String, Object?> json) =>
      AxisTransformOp(
        dx: (json['dx'] as num).toDouble(),
        dy: (json['dy'] as num).toDouble(),
        kind: AxisTransformKind.values.byName(json['kind'] as String),
      );
  @override
  Map<String, Object?> toJson() => {
    'op': 'transform',
    'kind': kind.name,
    'dx': dx,
    'dy': dy,
  };
  @override
  String toSvg() => switch (kind) {
    AxisTransformKind.scale => '<g transform="scale(${dx.str},${dy.str})">',
    AxisTransformKind.skew => '<g transform="skew(${dx.str},${dy.str})">',
    AxisTransformKind.translate =>
      '<g transform="translate(${dx.str},${dy.str})">',
  };
  @override
  String toString() => 'AxisTransformOp${toJson()}';
}

enum AxisTransformKind { scale, skew, translate }

class JsonUtils {
  JsonUtils._();

  static Rect rectFromJson(Map rect) => Rect.fromLTWH(
    (rect['x'] as num).toDouble(),
    (rect['y'] as num).toDouble(),
    (rect['w'] as num).toDouble(),
    (rect['h'] as num).toDouble(),
  );
  static Map<String, Object?> rectToJson(Rect rect) => {
    'x': rect.left,
    'y': rect.top,
    'w': rect.width,
    'h': rect.height,
  };

  static Offset offsetFromJson(Map offset) => Offset(
    (offset['dx'] as num).toDouble(),
    (offset['dy'] as num).toDouble(),
  );
  static Map<String, Object?> offsetToJson(Offset offset) => {
    'dx': offset.dx,
    'dy': offset.dy,
  };
}
