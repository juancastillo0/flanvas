import 'dart:math' as math;

import 'package:flanvas/canvas_logic.dart';
import 'package:flanvas/canvas_ops.dart';
import 'package:flanvas/state_event.dart';
import 'package:flanvas/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:flanvas/state_event.dart';

class OpGroup {
  final List<CanvasOp> ops;
  final List<TransformCanvasOp> transforms = [];
  String name = 'group 1';

  OpGroup(this.ops);
}

class FlanvasState extends ChangeNotifier {
  FlanvasState(this.context);
  final BuildContext context;

  Uint8List? image;
  List<CanvasOp> ops = [];
  Size size = Size(500, 500);
  final paint =
      Paint()
        ..color = Colors.black
        ..strokeWidth = 5
        ..style = PaintingStyle.fill;
  late String svg = opsToSvg(ops, size);

  final availableColors = [
    Colors.black,
    Colors.white,
    Colors.red.shade500,
    Colors.pink.shade500,
    Colors.purple.shade500,
    Colors.deepPurple.shade500,
    Colors.indigo.shade500,
    Colors.blue.shade500,
    Colors.lightBlue.shade500,
    Colors.cyan.shade500,
    Colors.teal.shade500,
    Colors.green.shade500,
    Colors.lightGreen.shade500,
    Colors.lime.shade500,
    Colors.yellow.shade500,
    Colors.amber.shade500,
    Colors.orange.shade500,
    Colors.deepOrange.shade500,
    Colors.brown.shade500,
    Colors.grey.shade500,
    Colors.blueGrey.shade500,
  ];

  late Paint selectedPaint = paint;
  CanvasOp? selectedShapeBase;
  CanvasOp? selectedShape;
  List<Offset> selectedShapeTaps = [];

  late final groups = [OpGroup(ops)];
  final selectedOps = <CanvasOp>[];
  List<CanvasOp> copiedOps = [];
  final Map<CanvasOp, List<TransformCanvasOp>> transforms = {};
  final List<FlanvasEvent> eventsStack = [];
  int eventsStackIndex = -1;

  int gridSpace = 32;
  double zoom = 1;
  // paint, color, transform, group, delete, reorder, select

  /// [{"op":"circle","c":{"dx":120.0,"dy":50.0},"radius":6.0},{"op":"color","color":"72849231","blendMode":"srcOver"},{"op":"points","points":[{"dx":60.0,"dy":30.0},{"dx":100.0,"dy":40.0},{"dx":120.0,"dy":100.0},{"dx":20.0,"dy":100.0}],"pointMode":"polygon"}]

  void undo() {
    if (eventsStackIndex > -1) {
      revert(eventsStack[eventsStackIndex]);
    }
  }

  void redo() {
    if (eventsStackIndex < eventsStack.length - 1) {
      apply(eventsStack[eventsStackIndex + 1]);
    }
  }

  void apply(FlanvasEvent e) {
    switch (e) {
      case RemoveOpEv():
        ops.remove(e.op);
        selectedOps.remove(e.op);
      case AddOpEv():
        ops.insertAll(e.index ?? ops.length, [e.op, ...?e.other]);
      case ReorderOpEv():
        ops.removeAt(e.previousIndex);
        ops.insert(e.index, e.op);
      case UpdateAllOpsEv():
        ops = e.ops;
      case TransformOpEv():
        for (final op in e.selectedOps) {
          transforms.update(op, (a) => a, ifAbsent: () => []).add(e.op);
        }
    }
    if (eventsStack.length == eventsStackIndex + 1 ||
        eventsStack[eventsStackIndex + 1] != e) {
      // different history
      while (eventsStack.length > eventsStackIndex + 1) {
        eventsStack.removeLast();
      }
      eventsStack.add(e);
    }
    eventsStackIndex++;

    _applyOps(ops);
  }

  void revert(FlanvasEvent e) {
    switch (e) {
      case RemoveOpEv():
        ops.add(e.op);
        ops.addAll(e.other ?? const []);
      case AddOpEv():
        final s = {e.op, ...?e.other};
        ops.removeWhere(s.contains);
        selectedOps.removeWhere(s.contains);
      case ReorderOpEv():
        ops.removeAt(e.index);
        ops.insert(e.previousIndex, e.op);
      case UpdateAllOpsEv():
        ops = e.previousOps;
      case TransformOpEv():
        for (final op in e.selectedOps) {
          transforms[op]?.remove(e.op);
        }
    }

    _applyOps(ops);
    eventsStackIndex--;
  }

  Future<void> onFormDataSaved(Object value) {
    final newOps =
        ((value as Map)['ops'] as List)
            .cast<Map<String, Object?>>()
            .map(CanvasOp.fromJson)
            .toList();
    return _applyOps(newOps);
  }

  Future<void> _applyOps(List<CanvasOp> newOps) async {
    final im = await spriteFromCanvas(
      (canvas) {
        Paint p = paint;
        for (final op in newOps) {
          p = applyOp(op, canvas, p);
        }
      },
      height: size.height.round(),
      width: size.width.round(),
    );
    image = im;
    ops = newOps;
    svg = opsToSvg(ops, size);
    notifyListeners();
  }

  void onInteractCanvas(Offset t_, {required bool isTap}) {
    if (selectedShape == null || selectedShapeTaps.isEmpty && !isTap) return;
    final t = Offset(t_.dx.roundPrecision(1), t_.dy.roundPrecision(1));

    bool add = false;
    switch (selectedShape!) {
      case CircleOp c:
        if (selectedShapeTaps.isEmpty) {
          selectedShape = CircleOp(c: t, radius: c.radius);
        } else {
          selectedShape = CircleOp(
            c: selectedShapeTaps.first,
            radius: (selectedShapeTaps.first - t).distance.roundPrecision(1),
          );
          add = true;
        }
      case RectOp c:
        if (selectedShapeTaps.isEmpty) {
          selectedShape = RectOp(
            rect: Rect.fromLTWH(t.dx, t.dy, c.rect.width, c.rect.height),
          );
        } else {
          final c = (selectedShapeTaps.first + t) / 2;
          final d = selectedShapeTaps.first - t;
          selectedShape = RectOp(
            rect: Rect.fromCenter(
              center: c,
              width: d.dx.abs(),
              height: d.dy.abs(),
            ),
          );
          add = true;
        }
      case LineOp():
        if (selectedShapeTaps.isEmpty) {
          selectedShape = LineOp(p1: t, p2: t + Offset(1, 1));
        } else {
          selectedShape = LineOp(p1: selectedShapeTaps.first, p2: t);
          add = true;
        }
      case ArcOp c:
        if (selectedShapeTaps.isEmpty) {
          selectedShape = ArcOp(
            rect: Rect.fromCenter(center: t, width: 1, height: 1),
            startAngle: 0,
            sweepAngle: 1,
            useCenter: c.useCenter,
          );
        } else if (selectedShapeTaps.length == 1) {
          final d = selectedShapeTaps.first - t;
          selectedShape = ArcOp(
            rect: Rect.fromCenter(
              center: selectedShapeTaps.first,
              width: d.dx.abs(),
              height: d.dy.abs(),
            ),
            startAngle: 0,
            sweepAngle: 1,
            useCenter: c.useCenter,
          );
        } else if (selectedShapeTaps.length == 2) {
          final d = selectedShapeTaps.first - t;
          selectedShape = ArcOp(
            rect: c.rect,
            startAngle: math.atan2(d.dy, d.dx).roundPrecision(1),
            sweepAngle: 1,
            useCenter: c.useCenter,
          );
        } else {
          final d = selectedShapeTaps.first - t;
          selectedShape = ArcOp(
            rect: c.rect,
            startAngle: c.startAngle,
            sweepAngle: math.atan2(d.dy, d.dx).roundPrecision(1),
            useCenter: c.useCenter,
          );
          add = true;
        }
      case PointsOp c:
        selectedShape = PointsOp(
          pointMode: c.pointMode,
          points: [...selectedShapeTaps, t],
        );
      case ColorOp():
        // TODO: Handle this case.
        throw UnimplementedError();
      case RotateOp():
        if (selectedShapeTaps.isEmpty) {
          selectedShape = RotateOp(radians: 0);
        } else {
          final d = selectedShapeTaps.first - t;
          selectedShape = RotateOp(
            radians: math.atan2(d.dy, d.dx).roundPrecision(1),
          );
          add = true;
        }
      case AxisTransformOp c:
        if (selectedShapeTaps.isEmpty) {
          selectedShape = AxisTransformOp(kind: c.kind, dx: c.dx, dy: c.dy);
        } else {
          final d = t - selectedShapeTaps.first;
          selectedShape = AxisTransformOp(kind: c.kind, dx: d.dx, dy: d.dy);
          add = true;
        }
    }
    if (isTap) {
      if (add) {
        final op = selectedShape!;
        if (op is TransformCanvasOp) {
          if (selectedOps.isEmpty) {
            ops.insert(0, op);
          } else {
            apply(TransformOpEv(op: op, selectedOps: [...selectedOps]));
          }
        } else {
          if (selectedPaint.color != Colors.black) {
            // TODO: improve
            transforms[op] = [
              ColorOp(
                color: selectedPaint.color,
                blendMode: selectedPaint.blendMode,
              ),
            ];
          }

          apply(AddOpEv(op: op));
        }
        selectedShape = selectedShapeBase;
        selectedShapeTaps = [];
      } else {
        selectedShapeTaps.add(t);
      }
    }

    notifyListeners();
  }

  void selectShape(CanvasOp op) {
    selectedShape = op;
    selectedShapeBase = op;
    selectedShapeTaps = [];
    notifyListeners();
  }

  void selectOp(CanvasOp op) {
    if (!selectedOps.remove(op)) {
      selectedOps.add(op);
    }
    notifyListeners();
  }

  void selectColor(Color c) {
    selectedPaint.color = c;
    notifyListeners();
  }

  void onKeyEvent(KeyEvent value) {
    final noCtrl = {
      LogicalKeyboardKey.escape,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.delete,
    }.contains(value.logicalKey);
    if (!noCtrl &&
        !RawKeyboard.instance.keysPressed.any(
          LogicalKeyboardKey.expandSynonyms({
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.meta,
          }).contains,
        )) {
      return;
    }

    switch (value.logicalKey) {
      case LogicalKeyboardKey.escape:
        if (selectedShapeBase != null) selectShape(selectedShapeBase!);
      case LogicalKeyboardKey.enter:
        // TODO: add points
        if (selectedShapeBase != null) selectShape(selectedShapeBase!);
      case LogicalKeyboardKey.delete:
        if (selectedOps.isNotEmpty) {
          apply(RemoveOpEv.fromList(selectedOps));
        } else if (selectedShapeBase != null) {
          selectShape(selectedShapeBase!);
        }
      case LogicalKeyboardKey.keyC:
        if (selectedOps.isEmpty) return;
        copiedOps = [...selectedOps];
      case LogicalKeyboardKey.keyX:
        if (selectedOps.isEmpty) return;
        copiedOps = [...selectedOps];
        apply(RemoveOpEv.fromList(selectedOps));
      case LogicalKeyboardKey.keyV:
        if (copiedOps.isEmpty) return;
        apply(AddOpEv.fromList(copiedOps));
      case LogicalKeyboardKey.keyZ:
        if (RawKeyboard.instance.keysPressed.any(
          LogicalKeyboardKey.expandSynonyms({
            LogicalKeyboardKey.shift,
          }).contains,
        )) {
          redo();
        } else {
          undo();
        }
    }
  }

  void changePaint({
    PaintingStyle? style,
    double? strokeWidth,
    StrokeCap? strokeCap,
  }) {
    selectedPaint =
        Paint.from(selectedPaint)
          ..style = style ?? selectedPaint.style
          ..strokeWidth = strokeWidth ?? selectedPaint.strokeWidth
          ..strokeCap = strokeCap ?? selectedPaint.strokeCap;
    notifyListeners();
  }

  void updateZoom(double param0) {
    if (param0 <= 0) return;
    zoom = param0;
    notifyListeners();
  }

  void updateGrid(int v) {
    if (v < 0) return;
    gridSpace = v;
    notifyListeners();
  }
}
