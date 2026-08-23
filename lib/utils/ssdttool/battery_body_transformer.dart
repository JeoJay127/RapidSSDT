class BatteryMethodSemantics {
  const BatteryMethodSemantics({
    this.bif = false,
    this.bix = false,
    this.bst = false,
  });

  final bool bif;
  final bool bix;
  final bool bst;

  BatteryMethodSemantics merge(BatteryMethodSemantics other) =>
      BatteryMethodSemantics(
        bif: bif || other.bif,
        bix: bix || other.bix,
        bst: bst || other.bst,
      );

  bool get isEmpty => !bif && !bix && !bst;
}

class BatteryBodyTransformResult {
  const BatteryBodyTransformResult({
    required this.body,
    required this.valid,
    this.error = '',
    this.usesReadHelpers = false,
    this.usesWriteHelpers = false,
    this.logs = const [],
  });

  final String body;
  final bool valid;
  final String error;
  final bool usesReadHelpers;
  final bool usesWriteHelpers;
  final List<String> logs;
}

class BatteryMultiTransformer {
  const BatteryMultiTransformer._();

  static String rewriteBatteryReferences({
    required String body,
    required String parentPath,
    required List<String> batteryNames,
    String aggregatorName = 'BATC',
  }) {
    var output = body;
    final parent = parentPath.startsWith(r'\') ? parentPath : r'\' + parentPath;
    for (final battery in batteryNames) {
      final absoluteBattery = '$parent.$battery';
      final escaped = RegExp.escape(battery);
      output = output.replaceAllMapped(
        RegExp(
          r'Notify\s*\(\s*(?:[\\^]+[A-Za-z0-9_\.]*)*' + escaped + r'\s*,',
          caseSensitive: false,
        ),
        (_) => 'Notify ($aggregatorName,',
      );
      output = output.replaceAllMapped(
        RegExp(
          r'(?<![A-Za-z0-9_\.])(?:[\\^]+[A-Za-z0-9_\.]*)*' +
              escaped +
              r'(?![A-Za-z0-9_])',
          caseSensitive: false,
        ),
        (_) => absoluteBattery,
      );
    }
    return _deduplicateAdjacentNotifications(output, aggregatorName);
  }

  static String _deduplicateAdjacentNotifications(
    String body,
    String aggregatorName,
  ) {
    final notification = RegExp(
      r'^\s*Notify\s*\(\s*' +
          RegExp.escape(aggregatorName) +
          r'\s*,\s*(.+)\)\s*(?://.*)?$',
      caseSensitive: false,
    );
    final lines = body.split('\n');
    final result = <String>[];
    String? previousNotification;
    for (final line in lines) {
      final match = notification.firstMatch(line);
      if (match != null) {
        final signature = match
            .group(1)!
            .replaceAll(RegExp(r'\s+'), '')
            .toUpperCase();
        if (signature == previousNotification) continue;
        previousNotification = signature;
        result.add(line);
        continue;
      }
      final trimmed = line.trim();
      if (trimmed.isNotEmpty &&
          !trimmed.startsWith('//') &&
          !trimmed.startsWith('/*') &&
          !trimmed.startsWith('*')) {
        previousNotification = null;
      }
      result.add(line);
    }
    return result.join('\n');
  }
}

class BatteryBodyTransformer {
  const BatteryBodyTransformer._();

  static BatteryBodyTransformResult transform({
    required String body,
    required String methodName,
    required BatteryMethodSemantics semantics,
    required List<Map<String, dynamic>> fields,
  }) {
    var output = body;
    var reads = false;
    var writes = false;
    final logs = <String>[];
    final used = fields.where((field) {
      final name = (field['name'] ?? '').toString();
      final bits = field['bitLength'] as int? ?? 0;
      return bits > 8 && _fieldReference(name).hasMatch(body);
    }).toList();

    if (semantics.bif &&
        semantics.bix &&
        used.isNotEmpty &&
        RegExp(
          r'\[\s*(?:0x0*[9A-F]|0x1[0-3]|9|1[0-9])\s*\]\s*=',
          caseSensitive: false,
        ).hasMatch(output)) {
      return BatteryBodyTransformResult(
        body: output,
        valid: false,
        error: '方法同时服务 _BIF 与 _BIX，索引 9..19 的宽字段类型存在歧义。',
      );
    }

    for (final field in used) {
      final name = (field['name'] ?? '').toString();
      final reference = r'(?:[\\^A-Za-z0-9_]+\.)*' + RegExp.escape(name);
      final direct = RegExp(
        r'^(\s*)(' + reference + r')\s*=\s*(?!=)([^\r\n;]+)\s*;?\s*$',
        caseSensitive: false,
        multiLine: true,
      );
      output = output.replaceAllMapped(direct, (match) {
        writes = true;
        final source = match.group(3)!.trim();
        logs.add(
          '=> ${_regionSpace(field)}寄存器写入：${match.group(2)!.trim()} = $source',
        );
        return '${match.group(1)}${_writeExpression(field, source)}';
      });
    }

    final storeResult = _replaceStoreTargets(output, used, logs);
    if (storeResult.error.isNotEmpty) {
      return BatteryBodyTransformResult(
        body: output,
        valid: false,
        error: storeResult.error,
        logs: logs,
      );
    }
    output = storeResult.body;
    writes = writes || storeResult.replaced;

    final slots = _stringSlots(methodName, semantics);
    final buffers = _namedBuffers(output);
    for (final slot in slots) {
      final slotPattern = '(?:0x0*${slot.toRadixString(16)}|$slot)';
      for (final field in used) {
        final name = (field['name'] ?? '').toString();
        final reference = r'(?:[\\^A-Za-z0-9_]+\.)*' + RegExp.escape(name);
        final assignment = RegExp(
          r'((?:[\\^A-Za-z0-9_]+\.)*[A-Za-z_][A-Za-z0-9_]*\s*\[\s*' +
              slotPattern +
              r'\s*\]\s*=\s*)(' +
              reference +
              r')',
          caseSensitive: false,
        );
        if (!assignment.hasMatch(output)) continue;
        if (!_byteAligned(field)) {
          return BatteryBodyTransformResult(
            body: output,
            valid: false,
            error: '电池字符串槽位 $slot 引用了非字节对齐字段 $name。',
            logs: logs,
          );
        }
        output = output.replaceAllMapped(assignment, (match) {
          reads = true;
          logs.add(
            '=> 电池字符串读取：$methodName[$slot] <- $name (${_bitLength(field) ~/ 8} 字节 ASCIIZ)',
          );
          return '${match.group(1)}${_stringReadExpression(field)}';
        });
      }
      for (final buffer in buffers) {
        final assignment = RegExp(
          r'((?:[\\^A-Za-z0-9_]+\.)*[A-Za-z_][A-Za-z0-9_]*\s*\[\s*' +
              slotPattern +
              r'\s*\]\s*=\s*)' +
              RegExp.escape(buffer) +
              r'\b',
          caseSensitive: false,
        );
        output = output.replaceAllMapped(assignment, (match) {
          reads = true;
          logs.add('=> 电池字符串读取：$methodName[$slot] <- Buffer $buffer');
          return '${match.group(1)}ToString ($buffer, SizeOf ($buffer))';
        });
      }
    }

    for (final buffer in buffers) {
      for (final field in used) {
        final name = (field['name'] ?? '').toString();
        final reference = r'(?:[\\^A-Za-z0-9_]+\.)*' + RegExp.escape(name);
        final assignment = RegExp(
          r'(\b' + RegExp.escape(buffer) + r'\s*=\s*)(' + reference + r')',
          caseSensitive: false,
        );
        if (!assignment.hasMatch(output)) continue;
        if (!_byteAligned(field)) {
          return BatteryBodyTransformResult(
            body: output,
            valid: false,
            error: 'Buffer $buffer 引用了非字节对齐字段 $name。',
            logs: logs,
          );
        }
        output = output.replaceAllMapped(assignment, (match) {
          reads = true;
          logs.add(
            '=> ${_regionSpace(field)}缓冲区读取：$buffer <- $name (${_bitLength(field) ~/ 8} 字节)',
          );
          return '${match.group(1)}${_bufferReadExpression(field)}';
        });
      }
    }

    final unsupported = _unsupportedTarget(output, used);
    if (unsupported.isNotEmpty) {
      return BatteryBodyTransformResult(
        body: output,
        valid: false,
        error: unsupported,
        logs: logs,
      );
    }

    used.sort(
      (a, b) => (b['name'] ?? '').toString().length.compareTo(
        (a['name'] ?? '').toString().length,
      ),
    );
    for (final field in used) {
      final name = (field['name'] ?? '').toString();
      final reference = _fieldReference(name);
      if (!reference.hasMatch(_withoutComments(output))) continue;
      if (_bitLength(field) > 64) {
        if (!_byteAligned(field)) {
          return BatteryBodyTransformResult(
            body: output,
            valid: false,
            error:
                '字段 $name 为非字节对齐的 ${_bitLength(field)} 位 Buffer，无法安全执行 RECB。',
            logs: logs,
          );
        }
        reads = true;
        output = output.replaceAll(reference, _bufferReadExpression(field));
        logs.add(
          '=> ${_regionSpace(field)}宽Buffer读取：$name (${_bitLength(field) ~/ 8} 字节，不执行 B2IN)',
        );
      } else {
        reads = true;
        output = output.replaceAll(reference, _integerReadExpression(field));
      }
    }

    return BatteryBodyTransformResult(
      body: output,
      valid: true,
      usesReadHelpers: reads,
      usesWriteHelpers: writes,
      logs: logs,
    );
  }

  static RegExp _fieldReference(String name) => RegExp(
    r'(?<![A-Za-z0-9_])(?:[\\^A-Za-z0-9_]+\.)*' +
        RegExp.escape(name) +
        r'(?![A-Za-z0-9_])',
    caseSensitive: false,
  );

  static int _bitLength(Map<String, dynamic> field) =>
      field['bitLength'] as int? ?? 0;

  static bool _byteAligned(Map<String, dynamic> field) {
    final offset =
        field['bitOffset'] as int? ?? ((field['offset'] as int? ?? 0) * 8);
    return offset % 8 == 0 && _bitLength(field) % 8 == 0;
  }

  static String _regionSpace(Map<String, dynamic> field) {
    final value = (field['regionSpace'] ?? '').toString();
    return value.isEmpty ? 'EmbeddedControl' : value;
  }

  static bool _systemMemory(Map<String, dynamic> field) =>
      _regionSpace(field).toLowerCase() == 'systemmemory';

  static String _helper(Map<String, dynamic> field, {required bool write}) =>
      _systemMemory(field)
      ? (write ? 'WMCB' : 'RMCB')
      : (write ? 'WECB' : 'RECB');

  static int _absoluteByteOffset(Map<String, dynamic> field) =>
      (field['originOffset'] as int? ?? 0) + (field['offset'] as int? ?? 0);

  static String _addressExpression(Map<String, dynamic> field) {
    final origin = (field['originExpression'] ?? '').toString().trim();
    final relative = field['offset'] as int? ?? 0;
    if (origin.isEmpty) return _hex(_absoluteByteOffset(field));
    if (relative == 0) return origin;
    return 'Add ($origin, ${_hex(relative)})';
  }

  static String _hex(int value, {int width = 2}) =>
      '0x${value.toRadixString(16).toUpperCase().padLeft(width, '0')}';

  static String _scope(Map<String, dynamic> field) {
    var value = (field['scope'] ?? '').toString().trim();
    if (!value.startsWith(r'\')) value = r'\' + value;
    return value;
  }

  static String _bufferReadExpression(Map<String, dynamic> field) =>
      '${_scope(field)}.${_helper(field, write: false)} '
      '(${_addressExpression(field)}, ${_hex(_bitLength(field))})';

  static String _stringReadExpression(Map<String, dynamic> field) =>
      'ToString (${_bufferReadExpression(field)}, ${_hex(_bitLength(field) ~/ 8)})';

  static String _integerReadExpression(Map<String, dynamic> field) {
    final bitOffset =
        field['bitOffset'] as int? ?? ((field['offset'] as int? ?? 0) * 8);
    final shift = bitOffset % 8;
    final bytes = (shift + _bitLength(field) + 7) ~/ 8;
    final source =
        'B2IN (${_scope(field)}.${_helper(field, write: false)} '
        '(${_addressExpression(field)}, ${_hex(bytes * 8)}), ${_hex(bytes)})';
    if (shift == 0 && _bitLength(field) % 8 == 0) return source;
    final mask = _bitLength(field) >= 64
        ? '0xFFFFFFFFFFFFFFFF'
        : '0x${((BigInt.one << _bitLength(field)) - BigInt.one).toRadixString(16).toUpperCase()}';
    return 'And (ShiftRight ($source, $shift), $mask)';
  }

  static String _writeExpression(Map<String, dynamic> field, String source) =>
      '${_scope(field)}.${_helper(field, write: true)} '
      '(${_addressExpression(field)}, ${_hex(_bitLength(field))}, $source)';

  static Set<int> _stringSlots(
    String methodName,
    BatteryMethodSemantics semantics,
  ) {
    if (semantics.bif && semantics.bix) return const {};
    if (semantics.bif) return const {9, 10, 11, 12};
    if (semantics.bix) return const {16, 17, 18, 19};
    final name = methodName.toUpperCase();
    if (name.endsWith('BIF')) return const {9, 10, 11, 12};
    if (name.endsWith('BIX')) return const {16, 17, 18, 19};
    return const {};
  }

  static Set<String> _namedBuffers(String body) => RegExp(
    r'\bName\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*Buffer\s*\(',
    caseSensitive: false,
  ).allMatches(body).map((match) => match.group(1)!).toSet();

  static String _withoutComments(String value) => value
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\r\n]*'), '');

  static ({String body, bool replaced, String error}) _replaceStoreTargets(
    String body,
    List<Map<String, dynamic>> fields,
    List<String> logs,
  ) {
    var output = body;
    var from = 0;
    var replaced = false;
    final store = RegExp(r'\bStore\s*\(', caseSensitive: false);
    while (from < output.length) {
      final match = store.firstMatch(output.substring(from));
      if (match == null) break;
      final start = from + match.start;
      final open = output.indexOf('(', start);
      final close = _matchingParen(output, open);
      if (close < 0) {
        return (body: output, replaced: replaced, error: 'Store 表达式括号不完整。');
      }
      final arguments = output.substring(open + 1, close);
      final comma = _topLevelComma(arguments);
      if (comma < 0) {
        return (body: output, replaced: replaced, error: 'Store 表达式参数不完整。');
      }
      final source = arguments.substring(0, comma).trim();
      final targetText = arguments.substring(comma + 1).trim();
      Map<String, dynamic>? target;
      for (final field in fields) {
        final hit = _fieldReference(
          (field['name'] ?? '').toString(),
        ).firstMatch(targetText);
        if (hit != null && hit.start == 0 && hit.end == targetText.length) {
          target = field;
          break;
        }
      }
      if (target == null) {
        from = close + 1;
        continue;
      }
      logs.add('=> ${_regionSpace(target)}寄存器写入：$targetText = $source');
      final replacement = _writeExpression(target, source);
      output = output.replaceRange(start, close + 1, replacement);
      replaced = true;
      from = start + replacement.length;
    }
    return (body: output, replaced: replaced, error: '');
  }

  static int _matchingParen(String text, int open) {
    var depth = 0;
    var quoted = false;
    for (var index = open; index < text.length; index++) {
      final ch = text[index];
      if (ch == '"' && (index == 0 || text[index - 1] != r'\')) {
        quoted = !quoted;
      }
      if (quoted) continue;
      if (ch == '(') depth++;
      if (ch == ')' && --depth == 0) return index;
    }
    return -1;
  }

  static int _topLevelComma(String text) {
    var depth = 0;
    var quoted = false;
    for (var index = 0; index < text.length; index++) {
      final ch = text[index];
      if (ch == '"' && (index == 0 || text[index - 1] != r'\')) {
        quoted = !quoted;
      }
      if (quoted) continue;
      if ('({['.contains(ch)) depth++;
      if (')}]'.contains(ch)) depth--;
      if (ch == ',' && depth == 0) return index;
    }
    return -1;
  }

  static String _unsupportedTarget(
    String body,
    List<Map<String, dynamic>> fields,
  ) {
    const indexes = <String, List<int>>{
      'DECREMENT': [0],
      'INCREMENT': [0],
      'DIVIDE': [2, 3],
      'ADD': [2],
      'AND': [2],
      'CONCATENATE': [2],
      'COPYOBJECT': [1],
      'INDEX': [2],
      'MOD': [2],
      'MULTIPLY': [2],
      'NAND': [2],
      'NOR': [2],
      'NOT': [1],
      'OR': [2],
      'SHIFTLEFT': [2],
      'SHIFTRIGHT': [2],
      'SUBTRACT': [2],
      'XOR': [2],
    };
    for (final entry in indexes.entries) {
      final call = RegExp('\\b${entry.key}\\s*\\(', caseSensitive: false);
      var from = 0;
      while (from < body.length) {
        final match = call.firstMatch(body.substring(from));
        if (match == null) break;
        final start = from + match.start;
        final open = body.indexOf('(', start);
        final close = _matchingParen(body, open);
        if (close < 0) return '${entry.key} 表达式括号不完整。';
        final args = _topLevelArguments(body.substring(open + 1, close));
        for (final index in entry.value) {
          if (index >= args.length) continue;
          for (final field in fields) {
            final name = (field['name'] ?? '').toString();
            final hit = _fieldReference(name).firstMatch(args[index].trim());
            if (hit != null &&
                hit.start == 0 &&
                hit.end == args[index].trim().length) {
              return '字段 $name 被 ${entry.key} 用作写入目标，当前无法可靠自动转换。';
            }
          }
        }
        from = close + 1;
      }
    }
    for (final field in fields) {
      final name = (field['name'] ?? '').toString();
      final reference = r'(?:[\\^A-Za-z0-9_]+\.)*' + RegExp.escape(name);
      if (RegExp(
        r'\b(?:RefOf|CondRefOf)\s*\(\s*' + reference + r'\s*\)',
        caseSensitive: false,
      ).hasMatch(body)) {
        return '字段 $name 以对象引用方式使用，不能替换为 EC 读取表达式。';
      }
    }
    return '';
  }

  static List<String> _topLevelArguments(String text) {
    final result = <String>[];
    var rest = text;
    while (true) {
      final comma = _topLevelComma(rest);
      if (comma < 0) {
        result.add(rest.trim());
        break;
      }
      result.add(rest.substring(0, comma).trim());
      rest = rest.substring(comma + 1);
    }
    return result;
  }
}
