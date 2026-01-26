//  update_check.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/pages/views/markdown_viewer.dart';
import 'package:rapidssdt/utils/app_info.dart';
import 'package:rapidssdt/utils/log/log.dart';
import 'package:rapidssdt/utils/update/repo_config.dart';
import 'package:rapidssdt/utils/update/repo_context.dart';
import 'package:rapidssdt/utils/update/repo_sevice.dart';
import 'package:rapidssdt/widgets/inkwell_widget.dart';
import 'package:rapidssdt/widgets/link_button.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog._(this._ctx);
  final RepoContext _ctx;

  static Future<void> checkLatestRelease(
    BuildContext context, {
    bool silent = true,
    RepoConfig? config,
  }) async {
    final currentVersion = await AppInfo.version;
    await RepoService.instance.checkLatestRelease(
      currentVersion: currentVersion,
      silent: silent,
      onUpdateFound: (ctx, info) {
        if (!context.mounted) return;
        Log.info(info);
        _show(context, ctx);
      },
      onInfo: (info) => Log.info(info),
      onError: (error) => Log.error(error),
    );
  }

  static void _show(BuildContext context, RepoContext ctx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => UpdateDialog._(ctx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final release = _ctx.release;
    final asset = release.assetForCurrentPlatform();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '${_ctx.repoConfig.repo}发现新版本',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 6),
              Text('版本号：${release.tag}'),
              Text('发布时间：${release.publishedAt}'),
              const Divider(height: 24),
              Expanded(child: MarkdownViewer(data: release.body)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  CustomLinkButton(
                    url: _ctx.repoConfig.releasesUrl,
                    buttonText: '访问 GitHub',
                  ),
                  if (asset != null)
                    CustomLinkButton(
                      url: asset.downloadUrl,
                      buttonText: '立即下载',
                    ),
                  InkWellWidget(
                    width: 60,
                    height: 28,
                    radius: 6,
                    backgroundColor: Colors.transparent,
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
