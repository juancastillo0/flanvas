import 'dart:ui';

import 'package:flanvas/utils.dart';
import 'package:flanvas/canvas_ops.dart';
import 'package:flanvas/canvas_state.dart';
import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';

Border selectedBorder(BuildContext context, {required bool isSelected}) {
  return isSelected
      ? Border.all(
        color: Theme.of(context).colorScheme.inversePrimary,
        width: 3,
      )
      : Border.all(color: Colors.transparent, width: 3);
}

class CanvasFormWidget extends StatelessWidget {
  const CanvasFormWidget(this.state, {super.key});
  final FlanvasState state;

  @override
  Widget build(BuildContext context) {
    final selectedOps = state.selectedOps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          children: [
            ...state.availableColors.map((c) {
              final s = state.selectedPaint.color;
              final isSelected = [
                (s.a, c.a),
                (s.b, c.b),
                (s.g, c.g),
                (s.r, c.r),
              ].every((e) => e.$1.equalDouble(e.$2));
              return InkWell(
                onTap:
                    isSelected
                        ? null
                        : () {
                          state.selectColor(c);
                        },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c,
                    border: selectedBorder(context, isSelected: isSelected),
                  ),
                ),
              );
            }),
          ],
        ),
        Row(
          children: [
            ...[
              (CircleOp(c: Offset(0, 0), radius: 1), Icons.circle_outlined),
              (
                RectOp(
                  rect: Rect.fromCenter(
                    center: Offset(0, 0),
                    width: 1,
                    height: 1,
                  ),
                ),
                Icons.rectangle_outlined,
              ),
              (
                ArcOp(
                  rect: Rect.fromCenter(
                    center: Offset(0, 0),
                    width: 1,
                    height: 1,
                  ),
                  startAngle: 1,
                  sweepAngle: 1,
                  useCenter: false,
                ),
                Icons.mode_night_outlined,
              ),
              (
                LineOp(p1: Offset(0, 0), p2: Offset(1, 1)),
                Icons.linear_scale_rounded,
              ),
              (
                PointsOp(
                  pointMode: PointMode.polygon,
                  points: [Offset(0, 0), Offset(1, 1)],
                ),
                Icons.pentagon,
              ),
              (
                PointsOp(
                  pointMode: PointMode.lines,
                  points: [Offset(0, 0), Offset(1, 1)],
                ),
                Icons.timeline,
              ),
              (
                PointsOp(
                  pointMode: PointMode.points,
                  points: [Offset(0, 0), Offset(1, 1)],
                ),
                Icons.scatter_plot,
              ),
            ].map(
              (s) => InkWell(
                onTap: () {
                  state.selectShape(s.$1);
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: selectedBorder(
                      context,
                      isSelected: state.selectedShapeBase == s.$1,
                    ),
                  ),
                  child: Icon(s.$2),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            ...[
              (RotateOp(radians: 1), Icons.rotate_right),
              (
                AxisTransformOp(kind: AxisTransformKind.scale, dx: 2, dy: 2),
                Icons.zoom_out_map,
              ),
              (
                AxisTransformOp(kind: AxisTransformKind.skew, dx: 2, dy: 2),
                Icons.sync_alt,
              ),
              (
                AxisTransformOp(
                  kind: AxisTransformKind.translate,
                  dx: 2,
                  dy: 2,
                ),
                Icons.open_with,
              ),
              (
                AxisTransformOp(
                  kind: AxisTransformKind.translate,
                  dx: 2,
                  dy: 2,
                ),
                Icons.select_all,
              ),
              (
                AxisTransformOp(
                  kind: AxisTransformKind.translate,
                  dx: 2,
                  dy: 2,
                ),
                Icons.deselect,
              ),
              (
                AxisTransformOp(
                  kind: AxisTransformKind.translate,
                  dx: 2,
                  dy: 2,
                ),
                Icons.format_shapes,
              ),
              // TODO: crop?
              (
                AxisTransformOp(
                  kind: AxisTransformKind.translate,
                  dx: 2,
                  dy: 2,
                ),
                Icons.crop,
              ),
            ].map(
              (s) => InkWell(
                onTap: () {
                  state.selectShape(s.$1);
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: selectedBorder(
                      context,
                      isSelected: state.selectedShapeBase == s.$1,
                    ),
                  ),
                  child: Icon(s.$2),
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            ...state.groups.map((g) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Text(
                          g.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),

                  ReorderableListView(
                    shrinkWrap: true,
                    onReorder: (oldIndex, newIndex) {
                      state.apply(
                        ReorderOpEv(
                          op: g.ops[oldIndex],
                          index: newIndex,
                          previousIndex: oldIndex,
                        ),
                      );
                    },
                    children: [
                      ...g.ops.map(
                        (op) => InkWell(
                          key: ValueKey(op),
                          onTap: () {
                            state.selectOp(op);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color:
                                  selectedOps.contains(op)
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha(30)
                                      : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(op.toSvg())),
                                IconButton(
                                  onPressed:
                                      () => RemoveOpEv(op: op).apply(state),
                                  icon: Icon(Icons.delete, size: 18),
                                  iconSize: 18,
                                  constraints: BoxConstraints.tightFor(),
                                ),
                                Icon(Icons.drag_handle, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: JsonForm(
              jsonSchema: canvasOpsJsonSchema,
              onFormDataSaved: state.onFormDataSaved,
            ),
          ),
        ),
      ],
    );
  }
}

String get canvasOpsJsonSchema => r'''
{
  "type": "object",
  "properties": {
    "ops": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/canvasOp"
      }
    }
  },
  "definitions": {
    "offset": {
      "type": "object",
      "required": ["dx", "dy"],
      "properties": {
        "dx": {
          "type": "integer"
        },
        "dy": {
          "type": "integer"
        }
      }
    },
    "rectangle": {
      "type": "object",
      "required": ["x", "y", "w", "h"],
      "properties": {
        "x": {
          "type": "integer"
        },
        "y": {
          "type": "integer"
        },
        "w": {
          "type": "integer"
        },
        "h": {
          "type": "integer"
        }
      }
    },
    "canvasOp": {
      "type": "object",
      "required": ["op"],
      "oneOf": [
        {
          "properties": {
            "op": {
              "const": "arc"
            },
            "rect": {
              "$ref": "#/definitions/rectangle"
            },
            "startAngle": {
              "type": "number"
            },
            "sweepAngle": {
              "type": "number"
            },
            "useCenter": {
              "type": "boolean"
            }
          }
        },
        {
          "properties": {
            "op": {
              "const": "circle"
            },
            "c": {
              "$ref": "#/definitions/offset"
            },
            "radius": {
              "type": "number"
            }
          }
        },
        {
          "properties": {
            "op": {
              "const": "line"
            },
            "p1": {
              "$ref": "#/definitions/offset"
            },
            "p2": {
              "$ref": "#/definitions/offset"
            }
          }
        },
        {
          "properties": {
            "op": {
              "const": "rect"
            },
            "rect": {
              "$ref": "#/definitions/rectangle"
            }
          }
        },
        {
          "properties": {
            "op": {
              "const": "points"
            },
            "points": {
              "type": "array",
              "items": { "$ref": "#/definitions/offset" }
            },
            "pointMode": {
              "type": "string",
              "enum": ["points", "lines", "polygon"]
            }
          }
        },
        {
          "properties": {
            "op": {
              "const": "color"
            },
            "color": {
              "type": "string",
              "format": "color"
            },
            "blendMode": {
              "type": "string",
              "enum": [
                "clear",
                "src",
                "dst",
                "srcOver",
                "dstOver",
                "srcIn",
                "dstIn",
                "srcOut",
                "dstOut",
                "srcATop",
                "dstATop",
                "xor",
                "plus",
                "modulate",
                "screen",
                "overlay",
                "darken",
                "lighten",
                "colorDodge",
                "colorBurn",
                "hardLight",
                "softLight",
                "difference",
                "exclusion",
                "multiply",
                "hue",
                "saturation",
                "color",
                "luminosity"
              ]
            }
          }
        },
        {
          "properties": {
            "op": {
              "const": "rotate"
            },
            "radians": {
              "type": "number"
            }
          }
        },
        {
          "properties": {
            "op": {
              "const": "transform"
            },
            "kind": {
              "type": "string",
              "enum": ["scale", "skew", "translate"]
            },
            "dx": {
              "type": "number"
            },
            "dy": {
              "type": "number"
            }
          }
        }
      ]
    }
  }
}
''';
