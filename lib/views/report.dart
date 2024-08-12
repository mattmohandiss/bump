import 'package:bump_ai/data/response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class Report extends StatelessWidget {
  final Diagnosis diagnosis;
  const Report(this.diagnosis, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.1,
            vertical: MediaQuery.of(context).size.height * 0.1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                diagnosis.name,
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.1,
                  bottom: MediaQuery.of(context).size.height * 0.1,
                ),
                child: Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              MarkdownBody(
                data: diagnosis.summary,
                selectable: true,
                onTapLink: (text, href, title) {
                  // print(text);
                },
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.1,
                  bottom: MediaQuery.of(context).size.height * 0.1,
                ),
                child: Text(
                  'Treatment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              MarkdownBody(
                data: diagnosis.treatment,
                selectable: true,
                onTapLink: (text, href, title) {
                  // print(text);
                },
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.1,
                ),
                child: const Text(
                  '⚠️ This content is for informational purposes only. If you think you have an emergency dial 911 immediately.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.yellow,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
