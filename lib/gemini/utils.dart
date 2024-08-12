import 'dart:convert';

import 'package:bump_ai/data/response.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/foundation.dart';

String getDebugInfo(GenerateContentResponse response, Stopwatch timer) {
  final Map<String, String?> debugInfo = {
    'Tokens': response.usageMetadata?.totalTokenCount.toString(),
    'Feedback': response.promptFeedback?.safetyRatings.map((rating) => '${rating.category} (${rating.probability})').join(', '),
    'Blocked': response.promptFeedback?.blockReasonMessage,
    'Time': timer.elapsed.toString(),
  };
  return 'GEMINI RESPONSE:\n${debugInfo.entries.map(
        (e) => '${e.key}: ${e.value}',
      ).join('\n')}';
}

Future<List<String>> getLinks(Diagnosis diagnosis) async {
  final model = FirebaseVertexAI.instance.generativeModel(
    model: 'gemini-1.5-flash',
    systemInstruction: Content('system', [
      TextPart('You are a medical researcher tasked with finding medical terms in text.'),
      TextPart('The terms should be less than three words each'),
      TextPart('Always respond using the following JSON schema: ARRAY<STRING>'),
    ]),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
    ),
  );
  final timer = Stopwatch()..start();
  final result = await model.generateContent([
    Content.multi([TextPart('Generate a list of medical terms from the following text:'), TextPart(diagnosis.summary), TextPart(diagnosis.treatment)]),
  ]);

  if (kDebugMode) {
    print(getDebugInfo(result, timer));
  }

  try {
    return jsonDecode(result.text!).cast<String>();
  } catch (error) {
    if (kDebugMode) {
      print('Parse Error: ${error.toString()}');
      print('${result.text}');
    }

    return [];
  }
}

Future<Diagnosis> generateReport({required Diagnosis diagnosis, required List<List<Part>?> sources}) async {
  final model = FirebaseVertexAI.instance.generativeModel(
    model: 'gemini-1.5-pro',
    systemInstruction: Content('system', [
      TextPart('You are a medical researcher compiling diagnosis and treatment information on ${diagnosis.name}'),
      TextPart('Always respond using the following JSON schema: ${jsonEncode(Diagnosis.schema.toJson())}'),
    ]),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
    ),
  );
  final timer = Stopwatch()..start();
  final result = await model.generateContent([
    Content.multi([
      TextPart("The summary should be in layman's terms."),
      TextPart('The treatment should include a list of actionable steps that the patient can take to cure their diagnosis.'),
      TextPart('The summary and treatment should be formatted as markdown.'),
      TextPart('Include markdown formatted links for any medical terms that appear in the text.'),
      TextPart('Include a lot of details. The diagnosis should be at least 500 words.'),
      if (sources.isEmpty) TextPart('Use the following information to generate a diagnosis of ${diagnosis.name}.'),
      for (final source in sources)
        if (source != null) ...source,
      TextPart('Original diagnosis summary: ${diagnosis.summary}'),
      TextPart('Original diagnosis treatment: ${diagnosis.treatment}'),
      TextPart('Always respond using the following JSON schema: ${jsonEncode(Diagnosis.schema.toJson())}'),
    ]),
  ]);

  if (kDebugMode) {
    print(getDebugInfo(result, timer));
  }

  try {
    final diagnosis = Diagnosis.fromJSON(result.text!);

    try {
      final links = await getLinks(diagnosis);
      final exp = RegExp(
        links.map((e) => '\\b$e\\b').join('|'),
        caseSensitive: false,
      );

      final linkedSummary = diagnosis.summary.replaceAllMapped(exp, (Match m) {
        // print(m[0]);
        return '[${m[0]}]()';
      });

      final linkedTreatment = diagnosis.treatment.replaceAllMapped(exp, (Match m) {
        // print(m[0]);
        return '[${m[0]}]()';
      });
      return Diagnosis(
        name: diagnosis.name,
        summary: linkedSummary,
        treatment: linkedTreatment,
      );
    } catch (error) {
      if (kDebugMode) {
        print('Linking error');
      }
      return diagnosis;
    }
  } catch (error) {
    if (kDebugMode) {
      print('Parse Error: ${error.toString()}');
      print('${result.text}');
    }
    return diagnosis;
  }
}
