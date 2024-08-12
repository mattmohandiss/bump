// import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html;
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

void main() async {
  final topics = await getTopics();
  if (kDebugMode) {
    print('Fetched ${topics.length} topics');
  }

  File('topics_small.txt').writeAsString(topics.getRange(0, 10).map((e) => serialize(e)).join('\n\n'));
}

Future<List<Map<String, dynamic>>> getTopics() async {
  final file = File('topics.xml');
  final xml = XmlDocument.parse(await file.readAsString());

  final english = xml.xpath('/health-topics/*').where((node) => node.getAttribute('language') == 'English');
  for (var node in english) {
    for (var innerNode in node.xpath('full-summary')) {
      innerNode.innerText = html.parseFragment(innerNode.innerText).text!;
    }
  }
  final topics = english.map(
    (node) => {
      'NAME': [
        node.getAttribute('title')!,
        ...node.xpath('also-called').map((e) => e.innerText),
      ],
      'ABOUT': node.xpath('full-summary').map((e) => e.innerText),
      // 'NAME': node.getAttribute('title'),
      // 'SYNONYMS': node.xpath('also-called').map((e) => e.innerText).toList(),
      // 'RELATED': node.xpath('related-topic').map((e) => e.innerText).toList(),
      // 'DESCRIPTION': node.xpath('full-summary').map((e) => e.innerText),
      // 'GROUPS': node.xpath('group').map((e) => e.innerText).toList(),
      // 'MESH': node.xpath('mesh-heading/descriptor').map((e) => e.innerText).toList(),
      // 'URLS': node.xpath('site').map((e) => e.getAttribute('url') ?? 's').toList(),
    },
  );
  return topics.toList();
}

String serialize(Map<String, dynamic> data) {
  String result = '';
  for (final entry in data.entries) {
    final value = entry.value is List ? (entry.value as List).join(', ') : entry.value.toString();
    if (value.isNotEmpty) {
      result += '${entry.key}: $value\n';
    }
  }
  return result;
}
