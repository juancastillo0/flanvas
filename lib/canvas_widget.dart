import 'dart:convert';

import 'package:flanvas/canvas_logic.dart';
import 'package:flanvas/canvas_ops.dart';
import 'package:flanvas/canvas_state.dart';
import 'package:flutter/material.dart';

class CanvasOutputWidget extends StatelessWidget {
  const CanvasOutputWidget(this.state, {super.key});
  final FlanvasState state;

  @override
  Widget build(BuildContext context) {
    final ops = state.ops;
    final paint = state.paint;

    return Column(
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Size:', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(width: 6),
                SizedBox(
                  width: 65,
                  child: TextFormField(
                    initialValue: state.size.width.round().toString(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text('x'),
                ),
                SizedBox(
                  width: 65,
                  child: TextFormField(
                    initialValue: state.size.height.round().toString(),
                  ),
                ),
              ],
            ),

            ///
            ///
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grid_4x4, size: 22),
                Text('Grid:', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(width: 6),
                SizedBox(
                  width: 50,
                  child: TextFormField(
                    initialValue: state.gridSpace.toString(),
                    onChanged: (value) {
                      final v = int.tryParse(value);
                      if (v != null) state.updateGrid(v);
                    },
                  ),
                ),
              ],
            ),

            ///
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_in, size: 24),
                Text('Zoom:', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(width: 6),
                SizedBox(
                  width: 50,
                  child: TextFormField(
                    initialValue: state.zoom.toString(),
                    onChanged: (value) {
                      final v = double.tryParse(value);
                      if (v != null && v > 0) state.updateZoom(v);
                    },
                  ),
                ),
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        state.updateZoom(state.zoom + 0.1);
                      },
                      child: Icon(Icons.arrow_drop_up, size: 16),
                    ),
                    InkWell(
                      onTap: () {
                        state.updateZoom(state.zoom - 0.1);
                      },
                      child: Icon(Icons.arrow_drop_down, size: 16),
                    ),
                  ],
                ),
              ],
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.draw, size: 24),
                Text('Stroke:', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(width: 6),
                SizedBox(
                  width: 50,
                  child: TextFormField(
                    initialValue: state.selectedPaint.strokeWidth.toString(),
                    onChanged: (value) {
                      final v = double.tryParse(value);
                      if (v != null && v > 0) state.changePaint(strokeWidth: v);
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cable_sharp, size: 24),
                Text('Cap:', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(width: 6),
                ToggleButtons(
                  isSelected: [false, false, false]
                    ..[state.selectedPaint.strokeCap.index] = true,
                  borderRadius: BorderRadius.circular(10),
                  constraints: BoxConstraints.tightFor(),
                  onPressed:
                      (index) =>
                          state.changePaint(strokeCap: StrokeCap.values[index]),
                  children:
                      StrokeCap.values
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 5,
                              ),
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.selectedPaint.style == PaintingStyle.fill
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 24,
                ),
                const SizedBox(width: 2),
                Text('Fill:', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(width: 6),
                SizedBox(
                  width: 50,
                  child: Checkbox(
                    value: state.selectedPaint.style == PaintingStyle.fill,
                    onChanged:
                        (v) => state.changePaint(
                          style:
                              state.selectedPaint.style == PaintingStyle.fill
                                  ? PaintingStyle.stroke
                                  : PaintingStyle.fill,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
        MouseRegion(
          onHover: (d) => state.onInteractCanvas(d.localPosition, isTap: false),
          child: GestureDetector(
            onTapUp:
                (d) => state.onInteractCanvas(d.localPosition, isTap: true),
            child: Stack(
              children: [
                CustomPaint(
                  painter: OpsPainter(
                    ops: ops,
                    paintConfig: paint,
                    gridSpace: state.gridSpace,
                    state: state,
                  ),
                  willChange: true,
                  size: state.size,
                ),
                CustomPaint(
                  painter: OpsPainter(
                    ops:
                        state.selectedShape != null
                            ? [state.selectedShape!]
                            : const [],
                    paintConfig: state.selectedPaint,
                    gridSpace: null,
                    state: state,
                  ),
                  willChange: true,
                  size: state.size,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SVG', style: Theme.of(context).textTheme.titleLarge),
                SelectableText(state.svg),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('JSON', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: updateJsonDialog,
                      child: Text('Update'),
                    ),
                  ],
                ),
                SelectableText(jsonEncode(ops)),
                const SizedBox(height: 10),
                Text('FLUTTER', style: Theme.of(context).textTheme.titleLarge),
                SelectableText(flutterCodeForOps(ops, paint)),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void updateJsonDialog() {
    showDialog(
      context: state.context,
      builder: (context) {
        String value = jsonEncode(state.ops);
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              content: TextFormField(
                initialValue: value,
                maxLines: 100,
                forceErrorText: error,
                onChanged: (v) {
                  value = v;
                  if (error != null) {
                    setDialogState(() {
                      error = null;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await state.onFormDataSaved({'ops': jsonDecode(value)});
                      Navigator.of(state.context).pop();
                    } catch (e) {
                      setDialogState(() {
                        error = e.toString();
                      });
                    }
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class OpsPainter extends CustomPainter {
  final List<CanvasOp> ops;
  final Paint paintConfig;
  final int? gridSpace;
  final FlanvasState state;

  OpsPainter({
    super.repaint,
    required this.paintConfig,
    required this.gridSpace,
    required this.ops,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint p2 = paintConfig;
    Paint p = paintConfig;
    List<TransformCanvasOp>? transforms;
    canvas.save();
    for (final op in ops) {
      List<TransformCanvasOp>? tl = state.transforms[op];
      if (state.selectedShape is TransformCanvasOp &&
          (state.selectedOps.contains(op) || state.selectedOps.isEmpty)) {
        tl = [...?tl, state.selectedShape as TransformCanvasOp];
      }

      if (tl != transforms) {
        if (transforms != null) canvas.restore();
        p = p2;
        if (tl != null) {
          canvas.save();
          p2 = p;
          for (final t in tl) {
            p = applyOp(t, canvas, p);
          }
        }
      }

      p = applyOp(op, canvas, p);
      transforms = tl;
    }
    if (transforms != null) canvas.restore();
    canvas.restore();
    if (gridSpace != null && gridSpace! > 0) {
      paintGrid(canvas, size, gridSpace!);
    }
  }

  @override
  bool shouldRepaint(covariant OpsPainter oldDelegate) {
    return oldDelegate.ops != ops;
  }
}

void paintGrid(Canvas canvas, Size size, int gridSpace) {
  final int grid = gridSpace;
  final gridPaint = Paint()..color = Colors.black12;

  for (int i in Iterable.generate(size.width ~/ grid)) {
    canvas.drawLine(
      Offset((i + 1.0) * grid, 0),
      Offset((i + 1.0) * grid, size.height),
      gridPaint,
    );
  }
  for (int i in Iterable.generate(size.height ~/ grid)) {
    canvas.drawLine(
      Offset(0, (i + 1.0) * grid),
      Offset(size.width, (i + 1.0) * grid),
      gridPaint,
    );
  }
}
