import 'dart:async';
import 'package:flutter/material.dart';
import 'log.dart';
import 'log_config.dart';

class LogWidget extends StatefulWidget {
  final List<String>? channels;
  final LogConfig? config;
  final bool allChannel;
  final Map<String, Color>? channelColors;

  const LogWidget({
    super.key,
    this.channels,
    this.config,
    this.allChannel = false,
    this.channelColors,
  });

  @override
  State<LogWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  final List<StreamSubscription<String>> _subscriptions = [];
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.allChannel) {
      _subscriptions.add(Log.logStreamAll.listen(_onNewLogLine));
    } else {
      final targetChannels = widget.channels ?? [Log.defaultChannel];
      for (final c in targetChannels) {
        _subscriptions.add(
          Log.width(channel: c).logStream.listen(_onNewLogLine),
        );
      }
    }
  }

  void _onNewLogLine(String line) {
    if (!mounted) return;

    final maxLines =
        widget.config?.maxLines ??
        Log.channels[Log.defaultChannel]?.config.maxLines ??
        2000;

    setState(() {
      if (line.contains('[CLEARED]')) {
        _logs.clear();
      } else {
        _logs.add(line);
      }
      final excess = _logs.length - maxLines;
      if (excess > 0) _logs.removeRange(0, excess);
    });

    _scheduleScrollToBottom();
  }

  void _scheduleScrollToBottom() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom([double? previousMaxExtent]) {
    if (!mounted || !_scrollController.hasClients) {
      _scrollScheduled = false;
      return;
    }

    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    if ((position.pixels - maxExtent).abs() > 0.5) {
      _scrollController.jumpTo(maxExtent);
    }

    final extentIsStable =
        previousMaxExtent != null &&
        (previousMaxExtent - maxExtent).abs() <= 0.5;
    if (extentIsStable && position.extentAfter <= 0.5) {
      _scrollScheduled = false;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(maxExtent),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      constraints: const BoxConstraints(
        minHeight: 200,
        minWidth: double.infinity,
      ),
      child: SelectionArea(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: _logs.length,
          itemBuilder: (context, index) => RichText(
            text: LogTextFormatter.format(
              _logs[index],
              context: context,
              config: widget.config,
              channelColors: widget.channelColors,
            ),
            selectionRegistrar: SelectionContainer.maybeOf(context),
            selectionColor: DefaultSelectionStyle.of(context).selectionColor,
          ),
        ),
      ),
    );
  }
}

class LogTextFormatter {
  /// 完整日志匹配
  /// 2026-02-11 09:20:30.123 [default] [INFO] message
  static final RegExp _logPattern = RegExp(
    r'^'
    r'(?<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?)\s+'
    r'\[(?<channel>[^\]]+)\]\s+'
    r'\[(?<level>[A-Z]+)\]'
    r'(?:\s(?<message>[\s\S]*))?'
    r'$',
  );

  static TextSpan format(
    String logText, {
    required BuildContext context,
    LogConfig? config,
    Map<String, Color>? channelColors,
    double textSize = 11,
  }) {
    final match = _logPattern.firstMatch(logText);

    // 如果匹配失败，直接原样输出
    if (match == null) {
      return TextSpan(
        text: logText,
        style: TextStyle(fontSize: textSize),
      );
    }

    final timestamp = match.namedGroup('timestamp') ?? '';
    final channel = match.namedGroup('channel') ?? Log.defaultChannel;
    final levelStr = match.namedGroup('level') ?? 'DEBUG';
    final message = match.namedGroup('message') ?? '';

    final logConfig =
        config ??
        Log.channels[channel]?.config ??
        Log.channels[Log.defaultChannel]!.config;

    final channelColor = channelColors?[channel] ?? _getChannelColor(channel);

    final levelColor = _getLevelColor(levelStr, context);

    final children = <InlineSpan>[];

    // ===== Timestamp =====
    if (logConfig.includeLogTimestampForUI) {
      children.add(
        TextSpan(
          text: '$timestamp ',
          style: TextStyle(fontSize: textSize, color: levelColor),
        ),
      );
    }
    // ===== Channel =====
    if (logConfig.includeLogChannelForUI) {
      children.add(
        TextSpan(
          text: '[$channel] ',
          style: TextStyle(fontSize: textSize, color: channelColor),
        ),
      );
    }

    // ===== Level =====
    if (logConfig.includeLogLevelForUI) {
      children.add(
        TextSpan(
          text: '[$levelStr] ',
          style: TextStyle(fontSize: textSize, color: levelColor),
        ),
      );
    }

    // ===== Message =====
    children.add(
      TextSpan(
        text: message,
        style: TextStyle(fontSize: textSize, color: levelColor),
      ),
    );

    return TextSpan(children: children);
  }

  static Color _getChannelColor(String channel) {
    final hash = channel.hashCode % 360;
    return HSLColor.fromAHSL(1, hash.toDouble(), 0.7, 0.6).toColor();
  }

  static Color _getLevelColor(String level, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case 'INFO':
        return Colors.blue;
      case 'DEBUG':
        return isDark ? Colors.white : Colors.black;
      case 'WARNING':
        return Colors.orange;
      case 'ERROR':
        return Colors.red;
      case 'SUCCESS':
        return Colors.green;
      default:
        return Colors.deepPurple;
    }
  }
}
