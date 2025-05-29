import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flanvas/canvas_ops.dart';
import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';

void main() {
  runApp(const MyApp());
}

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? image;
  List<CanvasOp> ops = [];
  Size size = Size(500, 500);
  final paint = Paint()..color = Colors.black;
  late String svg = opsToSvg(ops, size);
  Color selectedColor = Colors.black;
  CanvasOp? selectedShape;
  List<Offset> selectedShapeTaps = [];

  /// [{"op":"circle","c":{"dx":120.0,"dy":50.0},"radius":6.0},{"op":"color","color":"72849231","blendMode":"srcOver"},{"op":"points","points":[{"dx":60.0,"dy":30.0},{"dx":100.0,"dy":40.0},{"dx":120.0,"dy":100.0},{"dx":20.0,"dy":100.0}],"pointMode":"polygon"}]

  Future<void> onFormDataSaved(Object value) async {
    final ops = ((value as Map)['ops'] as List)
        .cast<Map<String, Object?>>()
        .map(CanvasOp.fromJson)
        .toList(growable: false);
    final im = await spriteFromCanvas(
      (canvas) {
        Paint p = paint;
        for (final op in ops) {
          p = applyOp(op, canvas, p);
        }
      },
      height: size.height.round(),
      width: size.width.round(),
    );
    if (mounted) {
      setState(() {
        image = im;
        this.ops = ops;
        svg = opsToSvg(ops, size);
      });
    }
  }

  void onInteractCanvas(Offset t, {required bool isTap}) {
    if (selectedShape == null) return;
    selectedShapeTaps.add(t);

    switch (selectedShape) {
      case CircleOp c:
        if (selectedShapeTaps.length == 1) {
          selectedShape = CircleOp(
            c: selectedShapeTaps.first,
            radius: c.radius,
          );
        } else {
          selectedShape = CircleOp(
            c: selectedShapeTaps.first,
            radius: (selectedShapeTaps.first - selectedShapeTaps.last).distance,
          );
          if (isTap) {
            ops.add(selectedShape!);
            selectedShape = null;
            selectedShapeTaps = [];
          }
        }
        setState(() {});
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Wrap(
                    children: [
                      ...[
                        Colors.black,
                        Colors.white,
                        Colors.red,
                        Colors.pink,
                        Colors.purple,
                        Colors.deepPurple,
                        Colors.indigo,
                        Colors.blue,
                        Colors.lightBlue,
                        Colors.cyan,
                        Colors.teal,
                        Colors.green,
                        Colors.lightGreen,
                        Colors.lime,
                        Colors.yellow,
                        Colors.amber,
                        Colors.orange,
                        Colors.deepOrange,
                        Colors.brown,
                        Colors.grey,
                        Colors.blueGrey,
                      ].map(
                        (c) => InkWell(
                          onTap: () {
                            setState(() {
                              selectedColor = c;
                            });
                          },
                          child: Container(color: c, width: 20, height: 20),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedShape = CircleOp(
                              c: Offset(0, 0),
                              radius: 1,
                            );
                            selectedShapeTaps = [];
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          child: Icon(Icons.circle),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: JsonForm(
                        jsonSchema: canvasOpsJsonSchema,
                        onFormDataSaved: onFormDataSaved,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: size.width,
              child: Column(
                children: [
                  GestureDetector(
                    onPanUpdate:
                        (d) => onInteractCanvas(d.localPosition, isTap: false),
                    onTapUp:
                        (d) => onInteractCanvas(d.localPosition, isTap: true),
                    child: CustomPaint(
                      painter: OpsPainter(ops: ops, paintConfig: paint),
                      willChange: true,
                      size: size,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SVG',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SelectableText(svg),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'JSON',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TextButton(
                                onPressed: updateJsonDialog,
                                child: Text('Update'),
                              ),
                            ],
                          ),
                          SelectableText(jsonEncode(ops)),
                          const SizedBox(height: 10),
                          Text(
                            'FLUTTER',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SelectableText(flutterCodeForOps(ops, paint)),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // if (image != null)
            //   Image.memory(image!, width: size.width, height: size.height)
            // else
            //   SizedBox(
            //     width: size.width,
            //     height: size.height,
            //     child: Text('Update Canvas Operations'),
            //   ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  void updateJsonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String value = jsonEncode(ops);
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
                      await onFormDataSaved({'ops': jsonDecode(value)});
                      if (mounted) {
                        Navigator.of(this.context).pop();
                      }
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
  return '<svg viewBox="0 0 ${size.width} ${size.height}">'
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
      return 'canvas.drawArc(${a.rect}, ${a.startAngle}, ${a.sweepAngle}, ${a.useCenter}, paint);';
    case final CircleOp a:
      return 'canvas.drawCircle(${a.c}, ${a.radius}, paint);';
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
      return 'canvas.rotate(${a.radians});';
    case final AxisTransformOp a:
      return (switch (a.kind) {
        AxisTransformKind.scale => 'canvas.scale(${a.dx}, ${a.dy});',
        AxisTransformKind.skew => 'canvas.skew(${a.dx}, ${a.dy});',
        AxisTransformKind.translate => 'canvas.translate(${a.dx}, ${a.dy});',
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

class OpsPainter extends CustomPainter {
  final List<CanvasOp> ops;
  final Paint paintConfig;

  OpsPainter({super.repaint, required this.paintConfig, required this.ops});

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = paintConfig;
    for (final op in ops) {
      p = applyOp(op, canvas, p);
    }
    paintGrid(canvas, size);
  }

  @override
  bool shouldRepaint(covariant OpsPainter oldDelegate) {
    return oldDelegate.ops != ops;
  }
}

void paintGrid(Canvas canvas, Size size) {
  final int grid = 32;
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
