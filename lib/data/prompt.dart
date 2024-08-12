import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

class Prompt {
  final String text;
  final List<XFile> files;

  const Prompt({
    required this.text,
    required this.files,
  });

  Prompt copyWith({String? text, List<XFile>? files}) => Prompt(
        text: text ?? this.text,
        files: files ?? this.files,
      );

  bool get isEmpty => text.isEmpty && files.isEmpty;
}

class PromptEditingController extends ValueNotifier<Prompt> {
  Prompt get prompt => value;
  String get text => value.text;
  List<XFile> get files => value.files;

  PromptEditingController() : super(const Prompt(text: '', files: []));

  set text(String newText) {
    value = value.copyWith(text: newText);
  }

  set files(List<XFile> newFiles) {
    value = value.copyWith(files: newFiles);
  }

  bool get isEmpty => value.isEmpty;

  void clear() {
    value = const Prompt(text: '', files: []);
  }
}
