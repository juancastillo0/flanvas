import 'package:flanvas/canvas_state.dart';
import 'package:flanvas/canvas_widget.dart';
import 'package:flanvas/form_widget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flanvas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        ),
        visualDensity: VisualDensity.compact,
        appBarTheme: AppBarTheme(toolbarHeight: 36),
      ),
      home: const MyHomePage(title: 'Flanvas'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final FlanvasState state;
  final focusNode = FocusNode();

  @override
  void initState() {
    state = FlanvasState(context);
    focusNode.requestFocus();
    state.addListener(_setState);
    super.initState();
  }

  void _setState() {
    setState(() {});
  }

  @override
  void dispose() {
    state.removeListener(_setState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: state.onKeyEvent,
        child: Row(
          children: [
            Expanded(child: CanvasFormWidget(state)),
            SizedBox(width: state.size.width, child: CanvasOutputWidget(state)),
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
    );
  }
}
