import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'package:bump_ai/firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

Future<List<Part>?> firebase(Reference reference) async {
  final mime = (await reference.getMetadata()).contentType;
  final path = 'gs://${reference.bucket}/${reference.fullPath}';
  if (mime != null) {
    return [FileData(mime, path)];
  } else {
    return null;
  }
}

Future<List<Part>?> wikipedia(String name) async {
  try {
    final searchResults = await http.get(
      Uri.https(
        'api.wikimedia.org',
        '/core/v1/wikipedia/en/search/page',
        {
          'q': name,
          'limit': '1',
          'User-Agent': 'bump_ai',
          'Authorization': WikipediaOptions.token,
        },
      ),
    );

    final article = jsonDecode(searchResults.body)['pages'].first;

    final articleContent = await http.get(
      Uri.https('en.wikipedia.org', '/w/api.php', {
        'action': 'parse',
        'format': 'json',
        'page': article['title'],
        'prop': 'text',
        'redirects': '',
      }),
    );

    final content = jsonDecode(articleContent.body)['parse']['text']['*'];
    final htmlText = parse(content).body!.text;
    return [TextPart(htmlText)];
  } catch (error) {
    if (kDebugMode) {
      print('Parse Error: $error');
    }
    return null;
  }
}

Future<List<Part>?> magic(int guideline) async {
  final response = await http.get(Uri.parse('https://api.magicapp.org/api/v1/guidelines/$guideline/recommendations'));
  return [TextPart(response.body)];
}

Future<List<Part>?> nih(String query) async {
  final searchResults = await http.get(
    Uri.https(
      'eutils.ncbi.nlm.nih.gov',
      '/entrez/eutils/esearch.fcgi',
      {
        'db': 'pmc',
        'term': query,
      },
    ),
  );
  final ids = XmlDocument.parse(searchResults.body).xpath('/eSearchResult/IdList/Id').map((e) => e.innerText).join(',');

  final summaryResults = await http.get(
    Uri.https(
      'eutils.ncbi.nlm.nih.gov',
      '/entrez/eutils/esummary.fcgi',
      {
        'db': 'pmc',
        'id': ids,
        'version': '2.0',
      },
    ),
  );
  final titles = XmlDocument.parse(summaryResults.body).xpath('/eSummaryResult/DocumentSummarySet/DocumentSummary/Title').map((e) => e.innerText).join('\n\n');
  return [TextPart(titles)];
  // '((clinical[Title/Abstract] AND trial[Title/Abstract]) OR clinical trials as topic[MeSH Terms] OR clinical trial[Publication Type] OR random*[Title/Abstract] OR random allocation[MeSH Terms] OR therapeutic use[MeSH Subheading])'
  // 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pmc&term=childbirth%20AND%20author%20manuscript%5Bfilter%5D'
}
