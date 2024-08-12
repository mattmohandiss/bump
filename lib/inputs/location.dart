import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:bump_ai/data/prompt.dart';
import 'package:flutter/services.dart';

class LocationInput extends StatefulWidget {
  final String hint;
  final PromptEditingController controller;

  const LocationInput({
    super.key,
    required this.controller,
    required this.hint,
  });

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  // late final controller = ScribbleNotifier();
  List<List<Offset>> paths = [];

  late Future<ui.Image> image = getBackgroundImage(
    (MediaQuery.of(context).size.width * 0.3).floor(),
    (MediaQuery.of(context).size.height * 0.3).floor(),
  );

  Future<ui.Image> getBackgroundImage(int width, int height) async {
    final data = await rootBundle.load('assets/body_outline.jpg');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void initState() {
    super.initState();
    // widget.controller.addListener(() {
    //   textController.text = widget.controller.text;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.hint),
          FutureBuilder(
              future: image,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FittedBox(
                    fit: BoxFit.contain,
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() => paths.add([details.localPosition]));
                      },
                      onPanUpdate: (details) {
                        setState(() => paths.last.add(details.localPosition));
                      },
                      onPanEnd: (details) async {
                        final img = await getImage(background: snapshot.data!, paths: paths);
                        widget.controller.files = [XFile.fromData(img, mimeType: 'image/png')];
                      },
                      child: ClipRRect(
                        clipBehavior: Clip.hardEdge,
                        child: CustomPaint(
                          size: Size(
                            snapshot.data!.width.toDouble(),
                            snapshot.data!.height.toDouble(),
                          ),
                          painter: DrawPainter(
                            paths: paths,
                            background: snapshot.data!,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              }),
        ],
      ),
    );
  }

  Future<Uint8List> getImage({required ui.Image background, required List<List<Offset>> paths}) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, background.width.toDouble(), background.height.toDouble()),
    );
    final paint = Paint();
    canvas.drawImage(background, Offset.zero, paint);

    paint.color = Colors.red;
    paint.style = PaintingStyle.stroke;
    paint.strokeJoin = StrokeJoin.round;
    paint.strokeCap = StrokeCap.round;
    paint.strokeWidth = 5;

    for (final points in paths) {
      final path = Path();

      path.moveTo(points.first.dx, points.first.dy);
      points.sublist(1).forEach(
            (point) => path.lineTo(point.dx, point.dy),
          );

      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();

    ui.Image img = await picture.toImage(background.width, background.height);
    final ByteData? pngBytes = await img.toByteData(
      format: ImageByteFormat.png,
    );
    return pngBytes!.buffer.asUint8List();
  }
}

class DrawPainter extends CustomPainter {
  final ui.Image background;
  final List<List<Offset>> paths;

  DrawPainter({
    super.repaint,
    required this.paths,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(background, Offset.zero, paint);

    paint.color = Colors.red;
    paint.style = PaintingStyle.stroke;
    paint.strokeJoin = StrokeJoin.round;
    paint.strokeCap = StrokeCap.round;
    paint.strokeWidth = 10;

    for (final points in paths) {
      final path = Path();

      path.moveTo(points.first.dx, points.first.dy);
      points.sublist(1).forEach(
            (point) => path.lineTo(point.dx, point.dy),
          );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawPainter oldDelegate) {
    return true;
  }
}
