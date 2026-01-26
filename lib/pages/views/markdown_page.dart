//  markdown_page.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rapidssdt/pages/views/markdown_viewer.dart';

class MarkdownPage extends StatelessWidget {
  final String mdPath;
  final String? title;
  final EdgeInsets padding;
  final bool showAppBar;

  const MarkdownPage({
    super.key,
    required this.mdPath,
    this.title,
    this.padding = const EdgeInsets.all(16),
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(centerTitle: true, title: Text(title ?? ''))
          : null,
      body: FutureBuilder<String>(
        future: rootBundle.loadString(mdPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('加载失败：${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          } else {
            return MarkdownViewer(data: snapshot.data!);
          }
        },
      ),
    );
  }
}
