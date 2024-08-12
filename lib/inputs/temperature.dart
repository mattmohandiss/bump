import 'package:flutter/material.dart';
import 'package:bump_ai/data/prompt.dart';

class TemperatureInput extends StatefulWidget {
  final String hint;
  final Function(Prompt prompt)? onChanged;
  final PromptEditingController controller;
  final double initial, min, max;

  const TemperatureInput({
    super.key,
    this.onChanged,
    required this.controller,
    required this.hint,
    this.initial = 97.7,
    this.min = 2,
    this.max = 150,
  });

  @override
  State<TemperatureInput> createState() => _TemperatureInputState();
}

class _TemperatureInputState extends State<TemperatureInput> {
  late final pageController = PageController(
    viewportFraction: 0.5,
    initialPage: convertToPageIndex(widget.controller.text),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (widget.controller.text.isEmpty) {
        pageController.animateToPage(
          convertToPageIndex(widget.controller.text),
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
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
          SizedBox(
            height: 100,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                setState(() => widget.controller.text = 'Temperature is ${tempString(index)}');
                if (widget.onChanged != null) {
                  widget.onChanged!(widget.controller.prompt);
                }
              },
              itemCount: ((widget.max - widget.min) * 10).floor(),
              itemBuilder: (context, index) => AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastOutSlowIn,
                style: TextStyle(fontSize: index == convertToPageIndex(widget.controller.text.split(' ').last) ? 50 : 30),
                child: Center(
                  child: Text(
                    tempString(index),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  String tempString(int index) => (index / 10 + widget.min).toString();
  int convertToPageIndex(String text) => (((double.tryParse(text) ?? widget.initial) - widget.min) * 10).floor();
}
