import 'log_file_writer.dart';

/// 日志级别
enum LogLevel { debug, info, warning, error, success }

/// 日志配置
class LogConfig {
  // 是否写入本地文件
  bool enableFile;

  /// 文件写入配置
  FileWriterConfig? fileWriterConfig;

  // 是否开启日志Level过滤
  bool enableLevelFilter;
  // 过滤日志Level
  LogLevel minLevel;
  // 内存保留最大行
  int maxLines;
  // 是否开启Debug日志输出
  bool enableDebug;

  // UI显示相关
  bool includeLogTimestampForUI;
  bool includeLogChannelForUI;
  bool includeLogLevelForUI;


  LogConfig({
    this.enableFile = true,
    this.fileWriterConfig,
    this.enableLevelFilter = false,
    this.minLevel = LogLevel.debug,
    this.maxLines = 2000,
    this.enableDebug = true,
    this.includeLogTimestampForUI = false,
    this.includeLogChannelForUI = false,
    this.includeLogLevelForUI = false,
  });

  bool isLevelAllowed(LogLevel level) {
    if (!enableLevelFilter) return true;
    return level.index >= minLevel.index;
  }
}
