import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;

import 'package:image_ops/image_ops.dart';
import 'package:wasm_run/wasm_run.dart';

void main(List<String> args) async {
  if (args.isEmpty || args.length > 2) {
    throw Exception('apply_ops <dir> <ops>');
  }
  final dir = Directory(args.first);
  final items = dir.listSync();
  final inputDir = PreopenedDir(wasmGuestPath: 'files', hostPath: dir.path);
  final outDir = await Directory(
    args.length == 2 ? args.last : '${dir.path}/output',
  ).create(recursive: true);
  final outputDir = PreopenedDir(
    wasmGuestPath: 'output',
    hostPath: outDir.path,
  );

  // final ops = args.last;
  final opsLib = await createImageOps(
    wasiConfig: WasiConfig(
      preopenedDirs: [inputDir, if (inputDir != outputDir) outputDir],
      webBrowserFileSystem: {},
    ),
  );

  final files = <(File, ImageRef)>[];
  for (final f in items.whereType<File>()) {
    final inputPath = '${inputDir.wasmGuestPath}/${f.uri.pathSegments.last}';
    final fResult = opsLib.readFile(path: inputPath);
    if (fResult.isError) {
      print('$inputPath: ${fResult.error!}');
      continue;
    }
    files.add((f, fResult.unwrap()));
  }

  final cli = ApplyImageOps(opsLib, inputDir: inputDir, outputDir: outputDir);
  await cli.concatImages(files);
}

class ApplyImageOps {
  final ImageOpsWorld opsLib;
  final PreopenedDir outputDir;
  final PreopenedDir inputDir;

  ApplyImageOps(this.opsLib, {required this.inputDir, required this.outputDir});

  Future<void> concatImages(List<(File, ImageRef)> files_) async {
    final files = [...files_];
    // late (File, ImageRef) base;
    // files.removeWhere((f) {
    //   final remove = f.$1.path.endsWith('dwd.png'); // '384x192.png'
    //   if (remove) base = f;
    //   return remove;
    // });
    // ImageRef out = base.$2;
    // final bytes = base.$1.readAsBytesSync();
    // for (final (i, b) in bytes.indexed) {
    //   if (b != 0) print('$i,$b');
    // }
    // final value = opsLib.operations.crop(
    //   imageRef: out,
    //   imageCrop: ImageCrop(x: 0, y: 0, height: 4, width: 4),
    // );
    // final b = opsLib.copyImageBuffer(imageRef: value).bytes;

    // opsLib
    //     .saveFile(image: value, path: '${outputDir.wasmGuestPath}/dwd.png')
    //     .unwrap();
    // print(base64Encode(bytes));
    int height = 0;
    int width = 0;
    for (final (_, info) in files) {
      width = math.max(width, info.width);
      height += info.height;
    }

    ImageRef out =
        opsLib.readBuffer(buffer: base64Decode(transparent4x4Png)).unwrap();
    out = opsLib.operations.resizeExact(
      imageRef: out,
      filter: FilterType.nearest,
      size: ImageSize(width: width, height: height),
    );

    int y = 0;
    for (final other in files) {
      out = opsLib.operations.replace(
        imageRef: out,
        other: other.$2,
        x: 0,
        y: y,
      );
      y += other.$2.height;
    }
    final name =
        inputDir.hostPath
            .split(RegExp(r'[/\\]'))
            .where((a) => a.isNotEmpty)
            .last;
    final outputFileName = '$name-${width}x$height.png';
    print('$outputFileName');
    opsLib
        .saveFile(
          image: out,
          path: '${outputDir.wasmGuestPath}/$outputFileName',
        )
        .unwrap();
  }

  void resizeImage((File, ImageRef) fileInfo, double resizeMul) {
    final (file, f) = fileInfo;
    final filename = file.uri.pathSegments.last;
    final extension = filename.split('.').last;
    final name = (filename.split('.')..removeLast()).join('.');

    final resized = opsLib.operations.resize(
      imageRef: f,
      size: ImageSize(
        width: (f.width * sqrt(resizeMul)).ceil(),
        height: (f.height * sqrt(resizeMul)).ceil(),
      ),
      filter: FilterType.gaussian,
    );

    final outputFileName =
        outputDir.wasmGuestPath == inputDir.wasmGuestPath
            ? '$name-resized.$extension'
            : filename;
    opsLib
        .saveFile(
          image: resized,
          path: '${outputDir.wasmGuestPath}/$outputFileName',
        )
        .unwrap();
  }
}

const transparent4x4Png =
    'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAT0lEQVR4AQFEALv/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARAABg7b00QAAAABJRU5ErkJggg==';



