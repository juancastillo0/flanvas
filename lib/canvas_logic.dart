import 'dart:typed_data';
import 'dart:ui';

import 'package:flanvas/canvas_ops.dart';
import 'package:flanvas/utils.dart';

Future<Uint8List> spriteFromCanvas(
  void Function(Canvas canvas) draw, {
  int width = 32,
  int height = 32,
}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  draw(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

String opsToSvg(List<CanvasOp> ops, Size size) {
  List<String> svgList = [];
  int groups = 0;
  for (final op in ops) {
    svgList.add('  ' * groups + op.toSvg());
    if (op.isGroup) groups++;
  }
  for (final _ in Iterable<int>.generate(groups)) {
    svgList.add('  ' * --groups + '<g/>');
  }
  return '<svg viewBox="0 0 ${size.width.str} ${size.height.str}">'
      '\n${svgList.join('\n')}\n</svg>';
}

String flutterCodeForOps(List<CanvasOp> ops, Paint paint) {
  return '''
Paint paint = $paint;
${ops.map(flutterCode).join('\n')}
''';
}

String flutterCode(CanvasOp op) {
  switch (op) {
    case final ArcOp a:
      // TOOD: print Rect.fromLTWH
      return 'canvas.drawArc(${a.rect}, ${a.startAngle.str}, ${a.sweepAngle.str}, ${a.useCenter}, paint);';
    case final CircleOp a:
      return 'canvas.drawCircle(${a.c}, ${a.radius.str}, paint);';
    case final LineOp a:
      return 'canvas.drawLine(${a.p1}, ${a.p2}, paint);';
    case final RectOp a:
      return 'canvas.drawRect(${a.rect}, paint);';
    case final PointsOp a:
      return 'canvas.drawPoints(${a.pointMode}, ${a.points}, paint);';
    case final ColorOp a:
      return '''
paint = Paint.from(paint)
  ..color = ${a.color}
  ..blendMode = ${a.blendMode};''';
    case final RotateOp a:
      return 'canvas.rotate(${a.radians.str});';
    case final AxisTransformOp a:
      return (switch (a.kind) {
        AxisTransformKind.scale => 'canvas.scale(${a.dx.str}, ${a.dy.str});',
        AxisTransformKind.skew => 'canvas.skew(${a.dx.str}, ${a.dy.str});',
        AxisTransformKind.translate =>
          'canvas.translate(${a.dx.str}, ${a.dy.str});',
      });
  }
}

Paint applyOp(CanvasOp op, Canvas canvas, Paint paint) {
  switch (op) {
    case final ArcOp a:
      canvas.drawArc(a.rect, a.startAngle, a.sweepAngle, a.useCenter, paint);
    case final CircleOp a:
      canvas.drawCircle(a.c, a.radius, paint);
    case final LineOp a:
      canvas.drawLine(a.p1, a.p2, paint);
    case final RectOp a:
      canvas.drawRect(a.rect, paint);
    case final PointsOp a:
      canvas.drawPoints(a.pointMode, a.points, paint);
    case final ColorOp a:
      return Paint.from(paint)
        ..color = a.color
        ..blendMode = a.blendMode;
    case final RotateOp a:
      canvas.rotate(a.radians);
    case final AxisTransformOp a:
      (switch (a.kind) {
        AxisTransformKind.scale => canvas.scale(a.dx, a.dy),
        AxisTransformKind.skew => canvas.skew(a.dx, a.dy),
        AxisTransformKind.translate => canvas.translate(a.dx, a.dy),
      });
  }
  return paint;
}
