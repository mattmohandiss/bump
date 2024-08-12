import 'package:flutter/material.dart';
import 'package:bump_ai/data/prompt.dart';
import 'package:lottie/lottie.dart';

final _faces = [
  'https://fonts.gstatic.com/s/e/notoemoji/latest/1f60e/lottie.json',
  'https://fonts.gstatic.com/s/e/notoemoji/latest/1f600/lottie.json',
  'https://fonts.gstatic.com/s/e/notoemoji/latest/1f610/lottie.json',
  'https://fonts.gstatic.com/s/e/notoemoji/latest/1f62c/lottie.json',
  'https://fonts.gstatic.com/s/e/notoemoji/latest/1f62d/lottie.json',
];

class PainScaleInput extends StatefulWidget {
  final String hint;
  final Function(Prompt prompt)? onChanged;
  final PromptEditingController controller;

  const PainScaleInput({
    super.key,
    this.onChanged,
    required this.controller,
    required this.hint,
  });

  @override
  State<PainScaleInput> createState() => _PainScaleInputState();
}

class _PainScaleInputState extends State<PainScaleInput> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    // widget.controller.addListener(() {});
    _controllers = List.generate(
      _faces.length,
      (_) => AnimationController(vsync: this),
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _faces.length; i++)
                GestureDetector(
                  onTap: () => setState(() {
                    for (var c in _controllers) {
                      c.reset();
                    }
                    _controllers[i].repeat();
                    widget.controller.text = 'Pain level is $i out of ${_faces.length}';
                  }),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withAlpha(i == (int.tryParse(widget.controller.text.split(' ').elementAtOrNull(3) ?? '')) ? 0 : 180),
                      BlendMode.srcATop,
                    ),
                    child: Lottie.network(
                      _faces[i],
                      width: 48,
                      controller: _controllers[i],
                      animate: i == (int.tryParse(widget.controller.text.split(' ').elementAtOrNull(3) ?? '')),
                      onLoaded: (composition) {
                        _controllers[i].duration = composition.duration;
                      },
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}
