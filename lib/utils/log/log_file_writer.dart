// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

/// ==========================
/// 滚动类型
/// ==========================
enum LogRotateType { none, size, daily }

/// ==========================
/// 文件写入配置
/// ==========================
class FileWriterConfig {
  /// 刷新间隔（毫秒）
  final int flushIntervalMs;

  /// 刷新批量大小
  final int flushBatchSize;

  /// 单文件最大大小（KB）
  final int maxFileSizeKB;

  final LogRotateType rotateType;

  /// 文件名前缀
  final String filePrefix;

  /// 日志文件扩展名
  final String fileExtension;

  /// 文件打开模式, 默认追加
  final FileMode mode;

  const FileWriterConfig({
    this.flushIntervalMs = 200,
    this.flushBatchSize = 20,
    this.maxFileSizeKB = 1024,
    this.rotateType = LogRotateType.size,
    this.filePrefix = 'log',
    this.fileExtension = '.txt',
    this.mode = FileMode.append,
  });
}

/// ==========================
/// Isolate 消息
/// ==========================
sealed class FileOp {}

class FileInit extends FileOp {
  final String dir;
  final String channel;
  final FileWriterConfig config;

  FileInit(this.dir, this.channel, this.config);
}

class FileWrite extends FileOp {
  final String line;
  FileWrite(this.line);
}

class FileClear extends FileOp {}

class FileDispose extends FileOp {}

/// ==========================
/// 日志文件写入器
/// ==========================
class LogFileWriter {
  final String channel;
  final FileWriterConfig? config;

  SendPort? _sendPort;
  final Completer<void> _ready = Completer();
  final List<String> _pending = [];

  late final String logDirPath;

  LogFileWriter({required this.channel, this.config});

  String get directory => logDirPath;

  /// 初始化
  Future<void> init() async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _fileWriterEntry,
      receivePort.sendPort,
      debugName: 'log_file_writer_$channel',
    );

    receivePort.listen((msg) async {
      if (msg is SendPort) {
        _sendPort = msg;

        final dir = await getApplicationSupportDirectory();
        logDirPath = '${dir.path}${Platform.pathSeparator}logs';

        _sendPort!.send(
          FileInit(logDirPath, channel, config ?? const FileWriterConfig()),
        );

        for (final line in _pending) {
          _sendPort!.send(FileWrite(line));
        }
        _pending.clear();

        _ready.complete();
      }
    });

    await _ready.future;
  }

  /// 写入
  void write(String line) {
    final port = _sendPort;
    if (port == null) {
      _pending.add(line);
      return;
    }
    port.send(FileWrite(line));
  }

  void clear() {
    _sendPort?.send(FileClear());
  }

  void dispose() {
    _sendPort?.send(FileDispose());
  }

  /// 获取当前 channel 所有日志文件
  Future<List<File>> listLogFiles() async {
    final dir = Directory(logDirPath);
    if (!dir.existsSync()) return [];
    final config = this.config ?? const FileWriterConfig();
    return dir
        .listSync()
        .whereType<File>()
        .where(
          (f) =>
              f.path.contains(channel) && f.path.endsWith(config.fileExtension),
        )
        .toList();
  }

  Future<String> exportCurrentLog({
    required String targetDir,
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    final files = await listLogFiles();
    if (files.isEmpty) {
      onError?.call('没有日志文件');
      throw Exception('没有日志文件');
    }

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    final latest = files.first;

    final targetPath =
        '$targetDir${Platform.pathSeparator}${latest.uri.pathSegments.last}';

    await latest.copy(targetPath);
    onSuccess?.call('文件导出成功: $targetPath');
    return targetPath;
  }

  Future<String> exportSingleFile({
    required String fileName,
    required String targetDir,
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    final file = File('$logDirPath${Platform.pathSeparator}$fileName');

    if (!await file.exists()) {
      onError?.call('文件不存在: $fileName');
      throw Exception('文件不存在: $fileName');
    }

    final targetPath = '$targetDir${Platform.pathSeparator}$fileName';

    await file.copy(targetPath);
    onSuccess?.call('文件导出成功: $targetPath');
    return targetPath;
  }

  Future<String> exportByDate({
    required DateTime date,
    required String targetDir,
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final config = this.config ?? const FileWriterConfig();
    final fileName =
        '${config.filePrefix}_${channel}_$dateStr${config.fileExtension}';

    return exportSingleFile(
      fileName: fileName,
      targetDir: targetDir,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// 按索引导出
  Future<String> exportByIndex({
    required int index,
    required String targetDir,
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    final config = this.config ?? const FileWriterConfig();
    final fileName =
        '${config.filePrefix}_${channel}_$index${config.fileExtension}';

    return exportSingleFile(
      fileName: fileName,
      targetDir: targetDir,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// ZIP 导出
  Future<String> exportZip({
    required String targetDir,
    String? zipName,
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    final files = await listLogFiles();

    if (files.isEmpty) {
      onError?.call('没有日志文件可导出');
      throw Exception('没有日志文件可导出');
    }

    final archive = Archive();

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final name = file.uri.pathSegments.last;
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    final zipData = ZipEncoder().encode(archive);

    final name = zipName ?? 'log_$channel.zip';
    final zipPath = '$targetDir${Platform.pathSeparator}$name';

    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipData);

    return zipPath;
  }

  /// ==========================
  /// Isolate 入口
  /// ==========================
  static void _fileWriterEntry(SendPort mainPort) async {
    final port = ReceivePort();
    mainPort.send(port.sendPort);

    Directory? logDir;
    IOSink? sink;
    File? file;

    String? channel;
    FileWriterConfig? config;

    DateTime? currentDate;
    int fileIndex = 0;

    final buffer = <String>[];
    Timer? timer;

    Future<void> _closeSink() async {
      if (sink == null) return;
      try {
        await sink!.flush();
        await sink!.close();
      } catch (_) {}
      sink = null;
    }

    String _buildFileName() {
      final now = DateTime.now();

      if (config!.rotateType == LogRotateType.daily) {
        final date =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        return '${config.filePrefix}_${channel}_$date${config.fileExtension}';
      }

      return '${config.filePrefix}_${channel}_$fileIndex${config.fileExtension}';
    }

    Future<void> _openNewFile() async {
      await _closeSink();

      final name = _buildFileName();
      final path = '${logDir!.path}${Platform.pathSeparator}$name';

      file = File(path);
      sink = file!.openWrite(mode: FileMode.append);

      currentDate = DateTime.now();
    }

    Future<void> _rotateIfNeeded() async {
      final currentFile = file;
      final currentConfig = config;
      if (currentFile == null || currentConfig == null) return;

      if (currentConfig.rotateType == LogRotateType.size) {
        final sizeKB = await currentFile.length() ~/ 1024;
        if (sizeKB >= currentConfig.maxFileSizeKB) {
          fileIndex++;
          await _openNewFile();
        }
      }

      if (currentConfig.rotateType == LogRotateType.daily) {
        final now = DateTime.now();
        if (currentDate == null ||
            now.day != currentDate!.day ||
            now.month != currentDate!.month ||
            now.year != currentDate!.year) {
          await _openNewFile();
        }
      }
    }

    Future<void> _flush() async {
      if (buffer.isEmpty || sink == null) return;
      sink!.writeln(buffer.join('\n'));
      buffer.clear();
    }

    void _cancelTimer() {
      timer?.cancel();
      timer = null;
    }

    await for (final msg in port) {
      switch (msg) {
        case FileInit():
          logDir = Directory(msg.dir);
          if (!logDir.existsSync()) {
            logDir.createSync(recursive: true);
          }
          channel = msg.channel;
          config = msg.config;
          await _openNewFile();
          break;

        case FileWrite():
          buffer.add(msg.line);

          if (buffer.length >= config!.flushBatchSize) {
            await _flush();
            await _rotateIfNeeded();
            _cancelTimer();
          } else {
            timer ??= Timer(
              Duration(milliseconds: config.flushIntervalMs),
              () async {
                await _flush();
                await _rotateIfNeeded();
                _cancelTimer();
              },
            );
          }
          break;

        case FileClear():
          await _flush();
          await _closeSink();
          if (logDir != null) {
            for (final f in logDir.listSync()) {
              if (config != null &&
                  f is File &&
                  f.path.contains(channel!) &&
                  f.path.endsWith(config.fileExtension)) {
                f.deleteSync();
              }
            }
          }
          fileIndex = 0;
          await _openNewFile();
          break;

        case FileDispose():
          _cancelTimer();
          await _flush();
          await _closeSink();
          Isolate.exit();
      }
    }
  }
}
