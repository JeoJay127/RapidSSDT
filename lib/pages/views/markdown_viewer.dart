//  markdown_viewer.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownViewer extends StatefulWidget {
  final String data;

  const MarkdownViewer({super.key, required this.data});

  @override
  State createState() => _MarkdownViewerState();
}

class _MarkdownViewerState extends State<MarkdownViewer> {
  @override
  Widget build(BuildContext context) {
    String modifiedMarkdownData = widget.data.replaceAllMapped(
      RegExp(r'!\[.*?\]\((.*?)\)'),
      (match) {
        String imagePath = match.group(1)!;
        if (imagePath.startsWith('images/')) {
          return '![${imagePath.substring(7)}](assets/images/$imagePath)';
        } else {
          return match.group(0)!;
        }
      },
    );

    return Markdown(
      data: modifiedMarkdownData,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        a: TextStyle(color: Theme.of(context).colorScheme.primary),

        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 1.0)),
        ),
      ),
      onTapLink: (text, href, title) {
        launchURL(href!);
      },
    );
  }

  void launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}
