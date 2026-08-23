import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  AppPaths._();

  /// ===============================
  /// 基础目录
  /// ===============================

  static String get home {
    final homeDir =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'];

    if (homeDir == null || homeDir.isEmpty) {
      throw UnsupportedError('无法获取用户主目录');
    }
    return homeDir;
  }

  static String join(String part1, [String? part2, String? part3]) {
    return p.joinAll(
      [part1, part2, part3].whereType<String>(),
    );
  }

  /// ===============================
  /// 桌面相关
  /// ===============================

  static String get desktop {
    _ensureDesktopPlatform();
    return join(home, 'Desktop');
  }

  static String get documents {
    if (_isDesktop) {
      return join(home, 'Documents');
    }
    throw UnsupportedError('当前平台不支持 documents 目录');
  }

  static String get downloads {
    if (_isDesktop) {
      return join(home, 'Downloads');
    }
    throw UnsupportedError('当前平台不支持 downloads 目录');
  }

  /// ===============================
  /// Flutter 相关目录（移动端/桌面通用）
  /// ===============================

  static Future<String> get appSupport async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  static Future<String> get appDocuments async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<String> get temp async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  /// ===============================
  /// 工具
  /// ===============================

  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  static void _ensureDesktopPlatform() {
    if (!_isDesktop) {
      throw UnsupportedError(
          '当前平台 ${Platform.operatingSystem} 不支持 Desktop 目录');
    }
  }
}
