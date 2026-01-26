//  copyable_text.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableText extends StatelessWidget {
  final String text;
  final String? title;
  final TextStyle? style;
  final TextStyle? titleStyle;
  final String? successMessage;
  final Duration snackBarDuration;
  final double spacing;

  const CopyableText({
    super.key,
    required this.text,
    this.title,
    this.style,
    this.titleStyle,
    this.successMessage,
    this.snackBarDuration = const Duration(seconds: 2),
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            style:
                titleStyle ??
                TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        if (title != null) SizedBox(width: spacing),
        Flexible(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: text)).then((_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      successMessage ?? '$text\n文本已复制到剪贴板',
                      style: TextStyle(fontSize: 11),
                    ),
                    duration: snackBarDuration,
                  ),
                );
              });
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style ?? TextStyle(fontSize: 11),
                ),
                Positioned(
                  bottom: -2.0,
                  left: 1,
                  right: 0,
                  child: Container(
                    height: 0.5,
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
