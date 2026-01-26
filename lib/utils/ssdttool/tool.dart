//  tool.dart
//  Created by JeoJay127
//
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:rapidssdt/utils/http/http_client_manager.dart';
import 'package:rapidssdt/utils/log/log.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rapidssdt/utils/ssdttool/permissions.dart';
import 'package:rapidssdt/utils/validate/file_integrity.dart';

/// ================== 平台相关工具下载地址表 ==================
const Map<String, Map<String, String>> _urls = {
  "checksums": {
    "url":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/checksums.json",
  },
  "windows": {
    "iasl":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/windows/iasl.exe",
    "iasl-legacy":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/windows/iasl-legacy.exe",
    "acpidump":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/windows/acpidump.exe",
  },
  "macos": {
    "iasl":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/macos/iasl",
    "iasl-legacy":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/macos/iasl-legacy",
    "patchmatic":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/macos/patchmatic",
  },
  "linux": {
    "iasl":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/linux/iasl",
    "iasl-legacy":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/linux/iasl-legacy",
    "acpidump":
        "https://raw.githubusercontent.com/JeoJay127/acpitools/main/linux/acpidump",
  },
};

/// ================== 工具配置类 ==================
class _PlatformToolConfig {
  final String platform;
  const _PlatformToolConfig({required this.platform});

  /// 平台后缀规则
  String get suffix => platform == 'windows' ? '.exe' : '';

  /// 当前平台真实的工具名（mac 用 patchmatic）
  String get acpidumpToolName =>
      platform == 'macos' ? "patchmatic" : "acpidump";

  Map<String, String> get _toolMap => _urls[platform] ?? {};

  String urlOf(String toolName) => _toolMap[toolName] ?? '';

  String assetOf(String toolName) =>
      'assets/acpitool/$platform/$toolName$suffix';

  String get stableToolName => "iasl";
  String get legacyToolName => "iasl-legacy";

  String get stableAsset => assetOf(stableToolName);
  String get legacyAsset => assetOf(legacyToolName);
  String get acpidumpAsset => assetOf(acpidumpToolName);

  String get checksumsAsset => 'assets/acpitool/checksums.json';
}

enum FileVerifyStatus {
  valid, // 校验通过
  invalid, // 校验明确失败（hash 不匹配）
  unknown, // 无法校验（无 checksum / 网络失败）
}

class ACPITool {
  final HttpClientManager _httpClientManager = HttpClientManager();
  final FileIntegrity _fileIntegrity = const FileIntegrity();
  Map<String, String>? _checksums;
  Map<String, String>? _remoteChecksums;
  _PlatformToolConfig get _platformConfig =>
      _PlatformToolConfig(platform: Platform.operatingSystem);

  final Map<String, Future<dynamic>> _activeRequests = {};
  final List<DownloadCancelToken> _cancelTokens = [];

  String _iaslLocal = '';
  String _iaslLocalLegacy = '';
  String _iaslRemote = '';
  String _iaslRemoteLegacy = '';

  bool useLocaliAsl;
  bool useLegacyAsl;

  String get iasl => useLocaliAsl
      ? (useLegacyAsl ? _iaslLocalLegacy : _iaslLocal)
      : (useLegacyAsl ? _iaslRemoteLegacy : _iaslRemote);
  String get iaslLegacy => useLocaliAsl ? _iaslLocalLegacy : _iaslRemoteLegacy;

  ACPITool({required this.useLocaliAsl, this.useLegacyAsl = false}) {
    Future.microtask(() async => await initialize());
  }

  Future<void> initialize() async {
    try {
      await _checkIaslValid(local: useLocaliAsl, legacy: useLegacyAsl);
      if ((_iaslLocal.isEmpty && _iaslLocalLegacy.isEmpty) &&
          (_iaslRemote.isEmpty && _iaslRemoteLegacy.isEmpty)) {
        Log.error("初始化 iasl 工具失败");
      }
    } catch (e) {
      Log.error("初始化 iasl 工具失败: $e");
      rethrow;
    }
  }

  Future<void> checkIaslValid({bool? local, bool? legacy}) async =>
      await _checkIaslValid(
        local: local ?? useLocaliAsl,
        legacy: legacy ?? useLegacyAsl,
      );

  Future<void> copyACPIToolFiles({bool replaceExisting = false}) async =>
      await _copyLocalToolFiles(replaceExisting: replaceExisting);

  /// ================== 校验 ==================
  Future<Map<String, String>> _loadLocalChecksums() async {
    if (_checksums != null) return _checksums!;
    final raw = await rootBundle.loadString(_platformConfig.checksumsAsset);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _checksums = map.map((k, v) => MapEntry(k, v.toString().toLowerCase()));
    return _checksums!;
  }

  Future<Map<String, String>> _loadRemoteChecksums() async {
    if (_remoteChecksums != null) return _remoteChecksums!;
    final url = _urls['checksums']?['url'] ?? '';
    final jsonStr = await _httpClientManager.getString(
      url,
      onError: (e) {
        Log.error('获取远程信息失败: $e');
      },
    );

    if (jsonStr == null || jsonStr.isEmpty) {
      Log.warning('将使用本地已缓存的远程工具,可能无效,谨慎使用!');
      return {};
    }

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    _remoteChecksums = map.map(
      (k, v) => MapEntry(k, v.toString().toLowerCase()),
    );

    return _remoteChecksums!;
  }

  String _checksumKeyForFile(String filePath) =>
      '${_platformConfig.platform}/${path.basename(filePath)}';

  Future<FileVerifyStatus> _verifyToolFile(
    String filePath, {
    bool remote = false,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return FileVerifyStatus.invalid;
    }

    Map<String, String> checksums;
    try {
      checksums = remote
          ? await _loadRemoteChecksums()
          : await _loadLocalChecksums();
    } catch (e) {
      Log.warning('校验出错: $e');
      return FileVerifyStatus.unknown;
    }

    final key = _checksumKeyForFile(filePath);
    final expected = checksums[key];

    if (expected == null && checksums.isNotEmpty) {
      Log.warning('校验信息未包含 $key');
      return FileVerifyStatus.unknown;
    }

    final result = await _fileIntegrity.verifyFileWithResult(
      file,
      expectedDigest: expected ?? '',
      algorithm: IntegrityAlgorithm.sha256,
    );

    return result.valid ? FileVerifyStatus.valid : FileVerifyStatus.invalid;
  }

  Future<void> _checkIaslValid({
    required bool local,
    required bool legacy,
  }) async {
    final bool isLocalMode = local;
    final bool isLegacy = legacy;

    useLocaliAsl = local;
    useLegacyAsl = legacy;

    if (isLocalMode) cancelAllDownloads();

    final taskKey = _getTaskKeyByName(
      isLegacy
          ? _platformConfig.legacyToolName
          : _platformConfig.stableToolName,
    );

    if (!isLocalMode && _activeRequests.containsKey(taskKey)) {
      Log.warning('任务 $taskKey 已在执行，等待完成...');
      return await _activeRequests[taskKey]!;
    }

    if (isLocalMode) {
      await _copyLocalToolFiles(replaceExisting: false);
    }

    // 模式显式传递
    final toolPath = await _checkIaslAvailability(local: isLocalMode);

    if (isLocalMode) {
      isLegacy ? _iaslLocalLegacy = toolPath : _iaslLocal = toolPath;
    } else {
      isLegacy ? _iaslRemoteLegacy = toolPath : _iaslRemote = toolPath;
    }

    _logToolStatus(toolPath, isLocalMode);
  }

  Future<String> _checkIaslAvailability({required bool local}) async {
    final toolDir = await getExecutableDir(local: local);
    final targets = await _getTargetToolInfo(toolDir);

    String validPath = '';
    for (final entry in targets.entries) {
      final toolName = entry.key;
      final toolPath = entry.value;

      final valid = local
          ? await _validateLocalTool(toolPath, toolName)
          : await _validateRemoteTool(toolPath, toolName, toolDir);

      if (valid.isNotEmpty &&
          (toolName == _platformConfig.stableToolName ||
              toolName == _platformConfig.legacyToolName)) {
        validPath = valid;
      }
    }
    return validPath;
  }

  Future<Map<String, String>> _getTargetToolInfo(String exePath) async {
    final tools = <String, String>{};
    final String iaslName = useLegacyAsl
        ? _platformConfig.legacyToolName
        : _platformConfig.stableToolName;

    tools[iaslName] = path.join(exePath, '$iaslName${_platformConfig.suffix}');
    final String dumpName = _platformConfig.acpidumpToolName;

    tools[dumpName] = path.join(exePath, '$dumpName${_platformConfig.suffix}');

    return tools;
  }

  String _getTaskKeyByName(String toolName) =>
      '${Platform.operatingSystem}-$toolName';

  bool _isACPITool(String filePath) {
    final name = path.basename(filePath).toLowerCase();
    if (name.endsWith('.zip')) return false;

    final validNames = <String>{
      '${_platformConfig.stableToolName}${_platformConfig.suffix}',
      '${_platformConfig.legacyToolName}${_platformConfig.suffix}',
      '${_platformConfig.acpidumpToolName}${_platformConfig.suffix}',
    };

    return validNames.contains(name);
  }

  Future<String> _validateLocalTool(String filePath, String toolName) async {
    Log('校验内置工具 $toolName...');
    final status = await _verifyToolFile(filePath, remote: false);
    if (status == FileVerifyStatus.valid) {
      Log('内置工具 $toolName 校验通过!');
      return filePath;
    }
    Log('内置工具 $toolName 无效，重新复制');
    await _copyLocalToolFiles(replaceExisting: true);
    return filePath;
  }

  Future<String> _validateRemoteTool(
    String filePath,
    String toolName,
    String toolDir,
  ) async {
    Log('校验远程工具 $toolName...');

    return _runTaskIfNotActive(_getTaskKeyByName(toolName), () async {
      if (useLocaliAsl) {
        Log.warning('已切换到内置模式,放弃远程任务 $toolName');
        return '';
      }
      final status = await _verifyToolFile(filePath, remote: true);
      switch (status) {
        case FileVerifyStatus.valid:
          Log('远程工具 $toolName 校验通过');
          return filePath;

        case FileVerifyStatus.unknown:
          Log.warning('远程工具 $toolName 校验状态未知，谨慎使用!');
          return filePath;

        case FileVerifyStatus.invalid:
          Log.error('远程工具 $toolName 校验失败，文件不存在或无效，重新下载');
          await _deleteFileIfExists(filePath);

          final url = _getDownloadUrlByName(toolName);
          final ok = await _downloadAndExtract(url, toolDir);
          return ok ? filePath : '';
      }
    });
  }

  String _getDownloadUrlByName(String toolName) =>
      _platformConfig.urlOf(toolName);

  /// ================== 下载解压 ==================
  Future<bool> _downloadAndExtract(String url, String targetDir) async {
    final fileName = path.basename(url);
    final filePath = path.join(targetDir, fileName);
    final cancelToken = DownloadCancelToken();
    _cancelTokens.add(cancelToken);

    try {
      final downloaded = await _downloadWithIdleTimeout(
        url,
        filePath,
        cancelToken,
      );
      if (downloaded == null || downloaded.isEmpty) return false;
      if (!Platform.isWindows && _isACPITool(filePath)) {
        await _chmodExecutable(filePath);
      }
      await _extractZip(filePath: filePath, extractDir: targetDir);
      return true;
    } catch (e) {
      Log.error('下载/解压失败: $e');
      return false;
    } finally {
      _cancelTokens.remove(cancelToken);
    }
  }

  Future<void> _extractZip({
    required String filePath,
    required String extractDir,
    bool deleteZipAfter = true,
  }) async {
    if (!filePath.toLowerCase().endsWith('.zip')) return;
    Log('开始解压: ${path.basename(filePath)}');
    final zipFile = File(filePath);
    if (!await zipFile.exists()) throw Exception('ZIP 文件不存在: $filePath');

    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    for (final archiveFile in archive) {
      final extractPath = path.join(extractDir, archiveFile.name);
      if (archiveFile.isFile) {
        final file = File(extractPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(archiveFile.content as List<int>);
        if (!Platform.isWindows && _isACPITool(extractPath)) {
          await _chmodExecutable(extractPath);
        }
      } else {
        await Directory(extractPath).create(recursive: true);
      }
    }

    if (deleteZipAfter) await zipFile.delete();
  }

  Future<String?> _downloadWithIdleTimeout(
    String url,
    String savePath,
    DownloadCancelToken cancelToken,
  ) async {
    bool cancelled = false;
    final result = await _httpClientManager.streamToFile(
      url,
      savePath,
      onProgress: (percent, speed, remaining) {
        if (useLocaliAsl) {
          cancelled = true;
          cancelToken.cancel();
          return;
        }
        Log(
          '${path.basename(url)} 下载进度: '
          '${percent.toStringAsFixed(2)}% | 速度: $speed | 剩余: $remaining',
        );
      },

      onError: (e) {
        // 出错,取消任务
        final toolName = path.basename(url);
        _activeRequests.remove(_getTaskKeyByName(toolName));
        _logNetworkError(e);
      },

      cancelToken: cancelToken,
      allowResume: true,
    );
    if (cancelled) {
      return null;
    }
    return result;
  }

  /// ================== 文件操作 ==================
  Future<void> _copyLocalToolFiles({bool replaceExisting = false}) async {
    final localDir = await getExecutableDir(local: true);

    final assetList = <String>[
      _platformConfig.assetOf(
        useLegacyAsl
            ? _platformConfig.legacyToolName
            : _platformConfig.stableToolName,
      ),
      _platformConfig.assetOf(_platformConfig.acpidumpToolName),
    ];

    await Future.wait(
      assetList.map((asset) async {
        final target = path.join(localDir, path.basename(asset));
        final success = await _copyAssetToDir(
          assetPath: asset,
          targetDir: localDir,
          replaceExisting: replaceExisting,
        );
        if (success && (!Platform.isWindows || _isACPITool(target))) {
          await _chmodExecutable(target);
        }
        if (!success) Log.error('复制内置工具失败: $asset 到 $localDir');
      }),
    );
  }

  Future<bool> _copyAssetToDir({
    required String assetPath,
    required String targetDir,
    bool replaceExisting = false,
  }) async {
    final fileName = path.basename(assetPath);
    final targetFilePath = path.join(targetDir, fileName);
    final targetFile = File(targetFilePath);

    if (await targetFile.exists()) {
      if (!replaceExisting) return true;
      await targetFile.delete(recursive: true);
    }

    try {
      final assetData = await rootBundle.load(assetPath);
      await File(targetFilePath).writeAsBytes(assetData.buffer.asUint8List());
      return true;
    } catch (e) {
      Log.error('复制 Asset 失败 ($assetPath → $targetFilePath): $e');
      return false;
    }
  }

  Future<void> _chmodExecutable(String filePath) async {
    await ExecutablePermissionManager.instance.ensureExecutable(filePath);
  }

  /// ================== 工具路径 ==================
  Future<String> getExecutableDir({required bool local}) async {
    final String baseDir = switch (Platform.operatingSystem) {
      'windows' => File(Platform.resolvedExecutable).parent.path,
      'macos' || 'linux' => (await getApplicationSupportDirectory()).path,
      _ => throw UnsupportedError('不支持的平台: ${Platform.operatingSystem}'),
    };
    final subDir = local ? "local" : "remote";
    final toolDir = path.join(baseDir, subDir);
    await Directory(toolDir).create(recursive: true);
    return toolDir;
  }

  /// ================== 任务管理 ==================
  void cancelAllDownloads() {
    for (final token in _cancelTokens) {
      token.cancel();
    }
    _cancelTokens.clear();
    _activeRequests.clear();
  }

  Future<T> _runTaskIfNotActive<T>(
    String taskKey,
    Future<T> Function() task,
  ) async {
    final existing = _activeRequests[taskKey];
    if (existing != null) {
      Log.warning('任务 $taskKey 已在执行，等待完成...');
      return await existing as T;
    }

    final future = Future<T>(() async {
      try {
        return await task();
      } catch (e) {
        Log.error('$taskKey 执行失败: $e');
        rethrow;
      } finally {
        _activeRequests.remove(taskKey);
      }
    });

    _activeRequests[taskKey] = future;

    return await future;
  }

  void _logNetworkError(dynamic e) {
    if (e is SocketException) {
      Log.error("网络连接异常: $e");
    } else if (e is TimeoutException) {
      Log.error('网络链接超时!请稍后尝试!: $e');
    } else {
      Log.error('发生异常: $e');
    }
  }

  Future<void> _deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  void _logToolStatus(String toolPath, bool isLocal) {
    final toolType = isLocal ? "内置" : "远程";
    final toolName = path.basename(toolPath);
    if (toolPath.isNotEmpty) {
      Log('$toolType工具 $toolName 准备就绪!\n');
    } else {
      Log.error(
        '$toolType工具$toolName未就绪！${isLocal ? "请检查工具完整性" : "建议切换到内置模式"}! \n',
      );
    }
  }
}
