import 'dart:math';

import 'package:bump_ai/data/prompt.dart';
import 'package:bump_ai/data/response.dart';
import 'package:bump_ai/gemini/consultation.dart';
import 'package:bump_ai/gemini/sources.dart';
import 'package:bump_ai/gemini/utils.dart';
import 'package:bump_ai/inputs/location.dart';
import 'package:bump_ai/inputs/pain.dart';
import 'package:bump_ai/inputs/temperature.dart';
import 'package:bump_ai/inputs/text.dart';
import 'package:bump_ai/views/report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final List<String> _phrases = [
  'I need a little more information',
  'Getting closer',
  'Almost there',
  'Just one more thing',
];

class Diagnose extends StatefulWidget {
  const Diagnose({super.key});

  @override
  State<Diagnose> createState() => _DiagnoseState();
}

class _DiagnoseState extends State<Diagnose> {
  final Consultation consultation = Consultation.begin();
  PromptEditingController controller = PromptEditingController();
  Question question = Question(text: 'Describe your symptoms', dataType: QuestionType.textOrImage);
  String titleText = "Hello, let's get started";
  bool loading = false;
  bool canSubmit = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (canSubmit == controller.isEmpty) {
        if (mounted) {
          setState(() => canSubmit = !controller.isEmpty);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.1,
          vertical: MediaQuery.of(context).size.height * 0.1,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.25),
              child: Text(
                titleText,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.1,
              ),
              child: switch (question.dataType) {
                QuestionType.textOrImage => TextImageInput(
                    controller: controller,
                    hint: question.text,
                  ),
                QuestionType.locationOnBody => LocationInput(
                    controller: controller,
                    hint: question.text,
                  ),
                QuestionType.temperatureReading => TemperatureInput(
                    controller: controller,
                    hint: question.text,
                  ),
                QuestionType.dateOrTime => TextImageInput(
                    controller: controller,
                    hint: question.text,
                  ),
                QuestionType.painScale => PainScaleInput(
                    controller: controller,
                    hint: question.text,
                  )
              },
            ),
            Padding(padding: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.25)),
            if (loading)
              const CircularProgressIndicator()
            else
              Visibility(
                visible: canSubmit,
                maintainAnimation: true,
                maintainSize: true,
                maintainState: true,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  onPressed: () async {
                    setState(() => loading = true);
                    try {
                      final response = await consultation.ask([
                        if (controller.files.isNotEmpty) ...controller.files,
                        if (controller.text.isNotEmpty) controller.text,
                        'Based on these symptoms, what is the most likely diagnosis for the patient?',
                      ]);
                      switch (response) {
                        case Question():
                          setState(() {
                            titleText = _phrases[Random().nextInt(_phrases.length)];
                            question = response;
                            if (kDebugMode) {
                              print('New Question: ${question.text} (${question.dataType})');
                            }
                          });
                        case Diagnosis():
                          final diagnosis = await generateReport(
                            diagnosis: response,
                            sources: [(await wikipedia(response.name))],
                          );

                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Report(diagnosis),
                              ),
                            );
                          }
                      }
                    } catch (error) {
                      if (kDebugMode) {
                        print('Error: ${error.toString()}');
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Theme.of(context).colorScheme.errorContainer,
                            content: Text(
                              error.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        );
                      }
                    } finally {
                      setState(() {
                        loading = false;
                        controller.clear();
                      });
                    }
                  },
                  label: Text(
                    'Next',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
