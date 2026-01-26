//  link_button.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomLinkButton extends StatelessWidget {
  final String url;
  final String buttonText;

  /// 优先显示 IconData，如果未提供，则使用 imagePath 图标
  final IconData? icon;
  final String? imagePath;
  final double iconSize;

  /// 若为空，则使用默认的 launchUrl 行为
  final Future<void> Function(BuildContext context, String url)? onTap;

  const CustomLinkButton({
    super.key,
    required this.url,
    required this.buttonText,
    this.icon,
    this.imagePath,
    this.iconSize = 24.0,
    this.onTap,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (onTap != null) {
      await onTap!(context, url);
      return;
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(icon, size: iconSize)
                else if (imagePath != null)
                  Image.asset(
                    imagePath!,
                    width: iconSize,
                    height: iconSize,
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    buttonText,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}