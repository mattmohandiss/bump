import 'dart:convert';

import 'package:bump_ai/data/response.dart';
import 'package:bump_ai/gemini/utils.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/foundation.dart';

class Consultation {
  late final ChatSession _chat;

  Consultation.begin({List<Reference>? sources}) {
    _chat = FirebaseVertexAI.instance
        .generativeModel(
          model: 'gemini-1.5-pro',
          systemInstruction: Content('system', [
            TextPart('You are a doctor that can diagnose common medical conditions.'),
            TextPart('You can ask questions to help you find a diagnosis.'),
            TextPart('You should use less than 30 characters to ask each question.'),
            TextPart('If you have a diagnosis always respond using the following JSON schema: ${jsonEncode(Diagnosis.schema.toJson())}'),
            TextPart('If you do not have a diagnosis always respond using the following JSON schema: ${jsonEncode(Question.schema.toJson())}'),
            ...QuestionType.values.map((val) => TextPart(
                  'If your question is asking about a ${val.description} the responseType on the question must be ${val.name}',
                )),
          ]),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        )
        .startChat();
  }

  Future<Response> ask(List<dynamic> parts) async {
    final timer = Stopwatch()..start();

    final result = await _chat.sendMessage(Content.multi([
      for (final part in parts)
        if (part is XFile) DataPart(part.mimeType!, await part.readAsBytes()) else if (part is String) TextPart(part)
    ]));

    if (kDebugMode) {
      print(getDebugInfo(result, timer));
    }

    try {
      return Question.fromJSON(result.text!);
    } catch (error) {
      try {
        return Diagnosis.fromJSON(result.text!);
      } catch (error) {
        if (kDebugMode) {
          print('Parse Error: ${error.toString()}');
          print('${result.text}');
        }

        throw 'Please ry again';
      }
    }
  }
}
