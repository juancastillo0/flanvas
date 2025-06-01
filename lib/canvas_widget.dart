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
          children: [
            Text('Size:', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(width: 6),
            SizedBox(
              width: 75,
              child: TextFormField(initialValue: state.size.width.toString()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('x'),
            ),
            SizedBox(
              width: 75,
              child: TextFormField(initialValue: state.size.height.toString()),
            ),
            const SizedBox(width: 6),

            ///
            Icon(Icons.grid_4x4, size: 22),
            Text('Grid:', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(width: 6),
            SizedBox(
              width: 50,
              child: TextFormField(initialValue: state.gridSpace.toString()),
            ),
            const SizedBox(width: 6),

            ///
            Icon(Icons.zoom_in, size: 24),
            Text('Zoom:', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(width: 6),
            SizedBox(
              width: 50,
              child: TextFormField(initialValue: state.gridSpace.toString()),
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
    if (gridSpace != null) {
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
