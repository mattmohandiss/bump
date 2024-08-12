import 'dart:convert';

import 'package:bump_ai/data/schema.dart';

sealed class Response {}

enum QuestionType {
  locationOnBody,
  temperatureReading,
  dateOrTime,
  painScale,
  textOrImage;

  String get description => switch (this) {
        QuestionType.locationOnBody => 'location',
        QuestionType.temperatureReading => 'temperature',
        QuestionType.dateOrTime => 'date or time',
        QuestionType.painScale => 'rating of pain',
        QuestionType.textOrImage => 'textual response or image',
      };
}

class Diagnosis extends Response {
  final String name;
  final String summary;
  final String treatment;

  Diagnosis({
    required this.name,
    required this.summary,
    required this.treatment,
  });

  static Diagnosis fromJSON(String json) {
    final decoded = jsonDecode(json);

    if (decoded['properties'] != null) {
      return Diagnosis(
        name: decoded['properties']['name'],
        summary: decoded['properties']['summary'],
        treatment: decoded['properties']['treatment'],
      );
    } else {
      return Diagnosis(
        name: decoded['name'],
        summary: decoded['summary'],
        treatment: decoded['treatment'],
      );
    }
  }

  static Schema schema = Schema.object(
    description: 'A diagnosis of a medical condition.',
    properties: {
      'name': Schema.string(
        description: 'The name of the medical condition.',
      ),
      'summary': Schema.string(
        description: 'A summary of the medical condition.',
      ),
      'treatment': Schema.string(
        description: 'A suggested treatment plan for the medical condition.',
      ),
    },
  );
}

class Question extends Response {
  final String text;
  final QuestionType dataType;

  Question({
    required this.text,
    required this.dataType,
  });

  static Question fromJSON(String json) {
    final decoded = jsonDecode(json);
    return Question(
      text: decoded['properties']['text'],
      dataType: QuestionType.values.firstWhere((value) => decoded['properties']['responseType'] == value.name, orElse: () => QuestionType.textOrImage),
    );
  }

  static Schema schema = Schema.object(
    description: 'A question asked by a doctor to a patient in order to gather information for the doctor to make a diagnosis.',
    properties: {
      'text': Schema.string(
        description: 'The text of the question.',
      ),
      'responseType': Schema.enumString(
        description: 'The data type of the response to the question.',
        enumValues: QuestionType.values.map((e) => e.name).toList(),
      ),
    },
  );
}
