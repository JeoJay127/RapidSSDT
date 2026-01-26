//  about_page.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/pages/views/update_check.dart';
import 'package:rapidssdt/widgets/inkwell_widget.dart';
import 'package:rapidssdt/widgets/link_button.dart';
import 'package:rapidssdt/utils/app_info.dart';
import 'package:rapidssdt/utils/constant.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String version = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    version = await AppInfo.version;
    buildNumber = await AppInfo.buildNumber;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            spacing: 12,
            children: [
              Image.asset('assets/images/icon.png', width: 100, height: 100),
              Text(
                Constant.appName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                '版本：$version  (Build $buildNumber)',
                style: const TextStyle(fontSize: 11),
              ),

              Text(Constant.copyright, style: const TextStyle(fontSize: 11)),
              InkWellWidget.common(
                width: 120,
                backgroundColor: Colors.indigo,
                onTap: () {
                  UpdateDialog.checkLatestRelease(context, silent: false);
                },
                child: const Text(
                  '检测更新',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              CustomLinkButton(
                url: 'https://github.com/JeoJay127/RapidSSDT',
                buttonText: '访问作者 GitHub 开源地址',
                icon: Icons.link_sharp,
              ),
              const Divider(),
              CustomLinkButton(
                url: 'https://github.com/JeoJay127/RapidEFI-Tool/releases',
                buttonText:
                    '推荐作者应用:RapidEFI是一款黑苹果OpenCore一键配置工具,严格遵守OpenCore官方指南,代替了手动收集文件和手工配置的繁琐过程,极大节省了配置时间。支持Windows、macOS、Linux跨平台使用。',
                imagePath: 'assets/images/Icon-App-60x60.png',
                iconSize: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
