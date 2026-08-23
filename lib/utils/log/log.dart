//  log.dart
//  Created by JeoJay127
//
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:rapidssdt/utils/paths/app_path.dart';
import 'log_file_writer.dart';
import 'log_config.dart';

enum LogExportMode {
  latest, // 当前最新文件
  allFiles, // 所有日志文件
  zipAll, // 所有文件压缩
  byFileName, // 指定文件
}

typedef LogChannelCreatedCallback = void Function(Log log);

/// 日志管理器
class Log {
  static final Map<String, Log> _channels = {};
  static const String defaultChannel = 'default';
  final String channel;
  final LogLevel defaultLevel;
  final LogConfig config;

  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  bool _disposed = false;

  /// 日志流,仅当前 channel 日志
  final StreamController<String> _logStreamController =
      StreamController.broadcast(sync: true);
  Stream<String> get logStream => _logStreamController.stream;

  /// 全局流,所有 channel 合并
  static final StreamController<String> _globalLogStreamController =
      StreamController.broadcast(sync: true);
  static Stream<String> get logStreamAll => _globalLogStreamController.stream;

  /// 日志文件写入器
  LogFileWriter? _fileWriter;
  Future<void>? _fileWriterReady;

  /// 获取/创建日志通道
  static LogChannelCreatedCallback? onChannelCreated;
  static Map<String, Log> get channels => _channels;

  Log._(this.channel, this.defaultLevel, this.config) {
    if (!kIsWeb && config.enableFile) {
      _fileWriter = LogFileWriter(
        channel: channel,
        config: config.fileWriterConfig,
      );
      _fileWriterReady = _fileWriter!.init();
    }
  }

  /// 初始化默认通道
  factory Log(
    String? message, {
    String? channel,
    LogLevel level = LogLevel.debug,
    LogConfig? config,
  }) => Log.width(
    channel: channel,
    level: level,
    config: config,
    message: message,
  );

  factory Log.width({
    String? channel,
    LogLevel level = LogLevel.debug,
    LogConfig? config,
    String? message,
  }) {
    final ch = channel ?? defaultChannel;
    final log = _channels.putIfAbsent(ch, () {
      final l = Log._(ch, level, config ?? LogConfig());
      onChannelCreated?.call(l);
      return l;
    });

    if (message != null) {
      log._add(message, level: level);
    }
    return log;
  }

  Future<void> _add(String message, {LogLevel? level}) async {
    if (_disposed) return;

    final effectiveLevel = level ?? defaultLevel;
    if (!config.isLevelAllowed(effectiveLevel)) return;

    final ts = DateTime.now().toLocal();
    final levelStr = effectiveLevel.name.toUpperCase();

    final logLine = '$ts [$channel] [$levelStr] $message';

    _logs.add(logLine);
    while (_logs.length > config.maxLines) {
      _logs.removeAt(0);
    }

    _logStreamController.add(logLine);
    _globalLogStreamController.add(logLine);

    if (config.enableDebug) {
      debugPrint(logLine);
    }

    if (config.enableFile && _fileWriter != null) {
      await _fileWriterReady;
      _fileWriter!.write(logLine);
    }
  }

  String _prettyJson(dynamic data) {
    try {
      final encoder = JsonEncoder.withIndent('  ');

      if (data is Map || data is List) {
        return encoder.convert(data);
      }

      if (data is String) {
        final s = data.trim();
        // 仅当合法 JSON 字符串才 decode
        if ((s.startsWith('{') && s.endsWith('}')) ||
            (s.startsWith('[') && s.endsWith(']'))) {
          return encoder.convert(jsonDecode(s));
        }
        // 否则直接原样返回
        return s;
      }

      return encoder.convert(data);
    } catch (_) {
      Log.warning('JSON 格式化失败: $data 请检查数据是否为合法 JSON 字符串');
      return data.toString();
    }
  }

  Future<void> _json(
    dynamic data, {
    String? title,
    LogLevel level = LogLevel.debug,
  }) async {
    await _add(title ?? '----------ResponseData----------', level: level);
    await _add(_prettyJson(data), level: level);
  }

  Future<void> _clear() async {
    _logs.clear();
    _logStreamController.add('[$channel] [CLEARED]');
    _globalLogStreamController.add('[$channel] [CLEARED]');
    _fileWriter?.clear();
  }

  static Future<void> info(String msg, {String? channel, LogConfig? config}) =>
      Log.width(
        channel: channel,
        config: config,
      )._add(msg, level: LogLevel.info);
  static Future<void> debug(String msg, {String? channel, LogConfig? config}) =>
      Log.width(
        channel: channel,
        config: config,
      )._add(msg, level: LogLevel.debug);
  static Future<void> warning(
    String msg, {
    String? channel,
    LogConfig? config,
  }) => Log.width(
    channel: channel,
    config: config,
  )._add(msg, level: LogLevel.warning);
  static Future<void> error(String msg, {String? channel, LogConfig? config}) =>
      Log.width(
        channel: channel,
        config: config,
      )._add(msg, level: LogLevel.error);
  static Future<void> success(
    String msg, {
    String? channel,
    LogConfig? config,
  }) => Log.width(
    channel: channel,
    config: config,
  )._add(msg, level: LogLevel.success);

  /// 将执行权短暂交还事件循环，让日志面板及时绘制。
  static Future<void> yieldToUi() =>
      Future<void>.delayed(const Duration(milliseconds: 1));

  /// 打印 JSON 数据
  static Future<void> json(
    dynamic data, {
    String? channel,
    String? title,
    LogLevel level = LogLevel.debug,
  }) => Log.width(channel: channel)._json(data, title: title, level: level);

  /// 导出日志到桌面
  static Future<String?> exportToDirectory({
    String? channel,
    String? targetDirectory,
    LogExportMode mode = LogExportMode.latest,
    String? fileName,
    String? zipName,
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    final log = _channels[channel ?? defaultChannel];
    if (log == null) {
      onError?.call('日志通道不存在: ${channel ?? defaultChannel}');
      return null;
    }

    final writer = log._fileWriter;
    if (writer == null) {
      onError?.call('当前日志未启用文件写入');
      return null;
    }

    await log._fileWriterReady;

    targetDirectory ??= AppPaths.desktop;

    switch (mode) {
      /// 导出当前文件
      case LogExportMode.latest:
        return writer.exportCurrentLog(
          targetDir: targetDirectory,
          onSuccess: onSuccess,
          onError: onError,
        );

      /// 导出全部文件
      case LogExportMode.allFiles:
        final files = await writer.listLogFiles();
        if (files.isEmpty) {
          onError?.call('没有日志文件');
          return null;
        }

        String? lastPath;

        for (final f in files) {
          final dest =
              '$targetDirectory${Platform.pathSeparator}${f.uri.pathSegments.last}';
          await f.copy(dest);
          lastPath = dest;
        }

        return lastPath!;

      /// 导出 zip
      case LogExportMode.zipAll:
        return writer.exportZip(
          targetDir: targetDirectory,
          zipName: zipName,
          onSuccess: onSuccess,
          onError: onError,
        );

      /// 导出指定文件
      case LogExportMode.byFileName:
        if (fileName == null) {
          onError?.call('必须提供 fileName');
          return null;
        }
        return writer.exportSingleFile(
          fileName: fileName,
          targetDir: targetDirectory,
          onSuccess: onSuccess,
          onError: onError,
        );
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _fileWriterReady;
    _fileWriter?.dispose();
    _channels.remove(channel);
    await _logStreamController.close();
  }

  /// 清除指定日志通道的日志
  static Future<void> clear({String? channel}) async =>
      _channels[channel ?? defaultChannel]?._clear();

  /// 清除所有日志通道的日志
  static Future<void> clearAll() async {
    for (final log in _channels.values) {
      await log._clear();
    }
  }

  /// 关闭所有日志通道
  static Future<void> shutdownAll() async {
    for (final log in _channels.values) {
      await log.dispose();
    }
    // 关闭全局日志流
    await _globalLogStreamController.close();
  }
}
