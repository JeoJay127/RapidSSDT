import 'battery_external_normalizer.dart';

class BatteryNamespaceObject {
  const BatteryNamespaceObject({
    required this.path,
    required this.type,
    this.confidence = 2,
  });

  final String path;
  final String type;
  final int confidence;
}

class BatteryNamespaceResolution {
  const BatteryNamespaceResolution({
    required this.body,
    required this.externals,
  });

  final String body;
  final Set<String> externals;
}

class BatteryNamespaceResolver {
  const BatteryNamespaceResolver._();

  static List<BatteryNamespaceObject> mergeDeviceObjects({
    required List<BatteryNamespaceObject> existing,
    required Iterable<Map<String, dynamic>> devices,
  }) {
    final byPath = <String, BatteryNamespaceObject>{};
    void add(String path, String type) {
      final normalized = BatteryExternalNormalizer.normalizePath(path);
      final key = BatteryExternalNormalizer.pathKey(normalized);
      if (key.isEmpty) return;
      final object = BatteryNamespaceObject(
        path: normalized,
        type: BatteryExternalNormalizer.canonicalObjectType(type),
      );
      final old = byPath[key];
      if (old == null ||
          object.confidence > old.confidence ||
          (old.type == 'UnknownObj' && object.type != 'UnknownObj')) {
        byPath[key] = object;
      }
    }

    for (final object in existing) {
      byPath[BatteryExternalNormalizer.pathKey(object.path)] = object;
    }
    for (final device in devices) {
      final devicePath = (device['path'] ?? device['scope'] ?? '').toString();
      if (devicePath.isEmpty) continue;
      add(devicePath, 'DeviceObj');
      for (final raw in device['methods'] as List<dynamic>? ?? const []) {
        if (raw is! Map) continue;
        final name = (raw['name'] ?? '').toString();
        final scope = (raw['scope'] ?? devicePath).toString();
        if (name.isNotEmpty) add('$scope.$name', 'MethodObj');
      }
      for (final raw in device['names'] as List<dynamic>? ?? const []) {
        if (raw is! Map) continue;
        final name = (raw['name'] ?? '').toString();
        final scope = (raw['scope'] ?? devicePath).toString();
        if (name.isNotEmpty) {
          add('$scope.$name', (raw['type'] ?? 'UnknownObj').toString());
        }
      }
      for (final raw in device['mutexs'] as List<dynamic>? ?? const []) {
        if (raw is! Map) continue;
        final name = (raw['name'] ?? '').toString();
        final scope = (raw['scope'] ?? devicePath).toString();
        if (name.isNotEmpty) add('$scope.$name', 'MutexObj');
      }
      for (final rawBlock
          in device['scopeFields'] as List<dynamic>? ?? const []) {
        if (rawBlock is! Map) continue;
        for (final raw in rawBlock['fields'] as List<dynamic>? ?? const []) {
          if (raw is! Map) continue;
          final name = (raw['name'] ?? '').toString();
          final scope = (raw['scope'] ?? devicePath).toString();
          if (name.isNotEmpty) add('$scope.$name', 'FieldUnitObj');
        }
      }
    }
    final result = byPath.values.toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return result;
  }

  static List<BatteryNamespaceObject> collectObjects(
    Iterable<dynamic> tables, {
    required String Function(String declaration) detectNameType,
  }) {
    final result = <BatteryNamespaceObject>[];
    final seen = <String, BatteryNamespaceObject>{};

    void add(String path, String type, {int confidence = 2}) {
      final normalized = BatteryExternalNormalizer.normalizePath(path);
      final key = BatteryExternalNormalizer.pathKey(normalized);
      if (key.isEmpty) return;
      final object = BatteryNamespaceObject(
        path: normalized,
        type: BatteryExternalNormalizer.canonicalObjectType(type),
        confidence: confidence,
      );
      final old = seen[key];
      if (old == null ||
          object.confidence > old.confidence ||
          (old.type == 'UnknownObj' && object.type != 'UnknownObj')) {
        seen[key] = object;
      }
    }

    for (final rawTable in tables) {
      if (rawTable is! Map) continue;
      final table = Map<String, dynamic>.from(rawTable);
      final lines = (table['lines'] as List<dynamic>? ?? const [])
          .map((line) => line.toString())
          .toList();
      final paths = table['paths'] as List<dynamic>? ?? const [];
      for (final rawPath in paths) {
        if (rawPath is! List || rawPath.length < 3) continue;
        final path = rawPath[0].toString();
        final line = rawPath[1] is int
            ? rawPath[1] as int
            : int.tryParse(rawPath[1].toString()) ?? -1;
        final declaration = rawPath[2].toString();
        var type = BatteryExternalNormalizer.objectTypeForDeclaration(
          declaration,
        );
        if (declaration.toUpperCase() == 'NAME') {
          type = line >= 0 && line < lines.length
              ? detectNameType(_completeDeclaration(lines, line))
              : 'UnknownObj';
        }
        add(path, type);
      }

      final ranges = _namespaceRanges(lines, paths);
      final braceEnds = _braceEndLines(lines);
      final fieldHeader = RegExp(
        r'^\s*(?:Field|IndexField|BankField)\s*\(',
        caseSensitive: false,
      );
      final fieldEntry = RegExp(
        r'^\s*([A-Za-z_][A-Za-z0-9_]{0,3})\s*,\s*(?:0x[0-9A-Fa-f]+|\d+)\s*,?',
      );
      final otherDeclaration = RegExp(
        r'^\s*(Mutex|OperationRegion|DataTableRegion|Event|PowerResource|ThermalZone)\s*\(\s*([^,\)]+)',
        caseSensitive: false,
      );
      for (var line = 0; line < lines.length; line++) {
        final other = otherDeclaration.firstMatch(lines[line]);
        if (other != null) {
          final scope = _enclosingPath(line, ranges);
          final name = other.group(2)!.trim();
          add(_joinPath(scope, name), other.group(1)!);
        }
        if (!fieldHeader.hasMatch(lines[line])) continue;
        final end = _blockEndLine(line, braceEnds);
        if (end <= line) continue;
        final scope = _enclosingPath(line, ranges);
        for (var entryLine = line + 1; entryLine < end; entryLine++) {
          final match = fieldEntry.firstMatch(lines[entryLine]);
          if (match != null) {
            add(_joinPath(scope, match.group(1)!), 'FieldUnitObj');
          }
        }
        line = end;
      }

      final source = lines.join('\n');
      final ignored = _ignoredCharacters(source);
      final external = RegExp(
        r'\bExternal\s*\(\s*([^,\)]+)\s*,\s*([^,\)]+)',
        caseSensitive: false,
      );
      for (final match in external.allMatches(source)) {
        if (!ignored[match.start]) {
          add(match.group(1)!, match.group(2)!, confidence: 1);
        }
      }
    }
    result.addAll(seen.values);
    result.sort((a, b) => a.path.compareTo(b.path));
    return result;
  }

  static BatteryNamespaceResolution resolveBody({
    required String body,
    required String methodPath,
    required List<BatteryNamespaceObject> objects,
    Set<String> generatedObjects = const {},
  }) {
    final byPath = <String, BatteryNamespaceObject>{};
    for (final object in objects) {
      final key = BatteryExternalNormalizer.pathKey(object.path);
      final old = byPath[key];
      if (old == null ||
          object.confidence > old.confidence ||
          (old.type == 'UnknownObj' && object.type != 'UnknownObj')) {
        byPath[key] = object;
      }
    }

    final concreteByLeaf = <String, Map<String, BatteryNamespaceObject>>{};
    for (final object in objects) {
      final key = BatteryExternalNormalizer.pathKey(object.path);
      if (object.confidence <= 1 || !key.contains('.')) continue;
      final leaf = key.split('.').last;
      final candidates = concreteByLeaf.putIfAbsent(leaf, () => {});
      final old = candidates[key];
      if (old == null ||
          object.confidence > old.confidence ||
          (old.type == 'UnknownObj' && object.type != 'UnknownObj')) {
        candidates[key] = object;
      }
    }
    for (final object in objects) {
      final rootKey = BatteryExternalNormalizer.pathKey(object.path);
      if (rootKey.isEmpty || rootKey.contains('.')) {
        continue;
      }
      final candidates = (concreteByLeaf[rootKey] ?? const {}).values
          .where(
            (candidate) =>
                object.type == 'UnknownObj' ||
                candidate.type == 'UnknownObj' ||
                candidate.type == object.type,
          )
          .toList();
      if (candidates.length != 1) continue;
      final existing = byPath[rootKey];
      if (existing != null &&
          existing.confidence > 1 &&
          existing.type != 'UnknownObj') {
        continue;
      }
      byPath[rootKey] = candidates.single;
    }

    final ignored = _ignoredCharacters(body);
    final localNames = <String>{};
    final declaredName = RegExp(
      r'\bName\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)',
      caseSensitive: false,
    );
    final createdField = RegExp(
      r'\bCreate(?:Bit|Byte|Word|DWord|QWord)?Field\s*\([^\r\n]*,\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)',
      caseSensitive: false,
    );
    for (final regex in [declaredName, createdField]) {
      for (final match in regex.allMatches(body)) {
        if (!ignored[match.start]) {
          localNames.add(match.group(1)!.toUpperCase());
        }
      }
    }

    final replacements = <({int start, int end, String path})>[];
    final externals = <String>{};
    final reference = RegExp(
      r'(?<![A-Za-z0-9_])((?:\\|\^+)?[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)',
      caseSensitive: false,
    );
    for (final match in reference.allMatches(body)) {
      if (ignored[match.start]) continue;
      final token = match.group(1)!;
      if (!token.contains('.') &&
          !token.startsWith(r'\') &&
          !token.startsWith('^') &&
          localNames.contains(token.toUpperCase())) {
        continue;
      }
      BatteryNamespaceObject? object;
      for (final candidate in lookupCandidates(token, methodPath)) {
        object = byPath[candidate];
        if (object != null) break;
      }
      if (object == null) continue;
      final objectKey = BatteryExternalNormalizer.pathKey(object.path);
      if (BatteryExternalNormalizer.pathKey(token) != objectKey ||
          !token.startsWith(r'\')) {
        replacements.add((
          start: match.start,
          end: match.end,
          path: object.path,
        ));
      }
      final methodKey = BatteryExternalNormalizer.pathKey(methodPath);
      if (generatedObjects.contains(objectKey) ||
          objectKey == methodKey ||
          objectKey.startsWith('$methodKey.')) {
        continue;
      }
      var type = object.type;
      if (type == 'UnknownObj') {
        var after = match.end;
        while (after < body.length && _isWhitespace(body[after])) {
          after++;
        }
        if (after < body.length && body[after] == '(') type = 'MethodObj';
      }
      externals.add('External (${object.path}, $type)');
    }

    var resolved = body;
    replacements.sort((a, b) => b.start.compareTo(a.start));
    var lastStart = body.length + 1;
    for (final replacement in replacements) {
      if (replacement.end > lastStart) continue;
      resolved = resolved.replaceRange(
        replacement.start,
        replacement.end,
        replacement.path,
      );
      lastStart = replacement.start;
    }
    return BatteryNamespaceResolution(body: resolved, externals: externals);
  }

  static List<String> lookupCandidates(String reference, String scope) {
    var name = reference.trim();
    if (name.isEmpty) return const [];
    if (name.startsWith(r'\')) {
      return [BatteryExternalNormalizer.pathKey(name)];
    }
    var current = BatteryExternalNormalizer.pathKey(scope);
    var parents = 0;
    while (name.startsWith('^')) {
      name = name.substring(1);
      parents++;
    }
    for (var index = 0; index < parents; index++) {
      current = _parentOf(current);
    }
    final result = <String>[];
    void append(String base) {
      final candidate = BatteryExternalNormalizer.pathKey(
        base.isEmpty ? name : '$base.$name',
      );
      if (candidate.isNotEmpty && !result.contains(candidate)) {
        result.add(candidate);
      }
    }

    append(current);
    if (parents > 0) return result;
    while (current.isNotEmpty) {
      current = _parentOf(current);
      append(current);
    }
    return result;
  }

  static String _completeDeclaration(List<String> lines, int start) {
    final buffer = StringBuffer();
    var depth = 0;
    var started = false;
    for (var line = start; line < lines.length; line++) {
      buffer.writeln(lines[line]);
      for (final character in lines[line].split('')) {
        if (character == '(') {
          depth++;
          started = true;
        } else if (character == ')') {
          depth--;
        }
      }
      if (started && depth <= 0) break;
    }
    return buffer.toString().trim();
  }

  static List<int> _braceEndLines(List<String> lines) {
    final result = List<int>.filled(lines.length, -1);
    final stack = <int>[];
    for (var line = 0; line < lines.length; line++) {
      for (final character in lines[line].split('')) {
        if (character == '{') {
          stack.add(line);
        } else if (character == '}' && stack.isNotEmpty) {
          result[stack.removeLast()] = line;
        }
      }
    }
    return result;
  }

  static int _blockEndLine(int headerLine, List<int> braceEnds) {
    final end = (headerLine + 8).clamp(0, braceEnds.length);
    for (var line = headerLine; line < end; line++) {
      if (braceEnds[line] >= line) return braceEnds[line];
    }
    return -1;
  }

  static List<({int start, int end, String path})> _namespaceRanges(
    List<String> lines,
    List<dynamic> paths,
  ) {
    final braces = _braceEndLines(lines);
    final ranges = <({int start, int end, String path})>[];
    for (final raw in paths) {
      if (raw is! List || raw.length < 3) continue;
      final type = raw[2].toString().toUpperCase();
      if (!const {
        'DEVICE',
        'PROCESSOR',
        'POWERRESOURCE',
        'THERMALZONE',
      }.contains(type)) {
        continue;
      }
      final start = raw[1] is int
          ? raw[1] as int
          : int.tryParse(raw[1].toString()) ?? -1;
      final end = _blockEndLine(start, braces);
      if (start >= 0 && end >= start) {
        ranges.add((
          start: start,
          end: end,
          path: BatteryExternalNormalizer.normalizePath(raw[0].toString()),
        ));
      }
    }
    final scopeHeader = RegExp(
      r'^\s*Scope\s*\(\s*([^\)]+)\s*\)',
      caseSensitive: false,
    );
    for (var line = 0; line < lines.length; line++) {
      final match = scopeHeader.firstMatch(lines[line]);
      if (match == null) continue;
      final end = _blockEndLine(line, braces);
      if (end < line) continue;
      final expression = match.group(1)!.trim();
      if (expression == r'\') {
        ranges.add((start: line, end: end, path: r'\'));
        continue;
      }
      final parent = _enclosingPath(line, ranges);
      final candidates = lookupCandidates(expression, parent);
      if (candidates.isEmpty) continue;
      ranges.add((
        start: line,
        end: end,
        path: BatteryExternalNormalizer.normalizePath(candidates.first),
      ));
    }
    ranges.sort((a, b) => a.start.compareTo(b.start));
    return ranges;
  }

  static String _enclosingPath(
    int line,
    List<({int start, int end, String path})> ranges,
  ) {
    ({int start, int end, String path})? owner;
    for (final range in ranges) {
      if (range.start >= line || range.end < line) continue;
      if (owner == null || range.start > owner.start) owner = range;
    }
    return owner?.path ?? r'\';
  }

  static String _joinPath(String scope, String name) =>
      scope == r'\' ? r'\' + name : '$scope.$name';

  static String _parentOf(String path) {
    final separator = path.lastIndexOf('.');
    return separator < 0 ? '' : path.substring(0, separator);
  }

  static bool _isWhitespace(String value) =>
      value == ' ' || value == '\t' || value == '\r' || value == '\n';

  static List<bool> _ignoredCharacters(String source) {
    final ignored = List<bool>.filled(source.length, false);
    var state = 0; // 0 code, 1 string, 2 line comment, 3 block comment
    for (var index = 0; index < source.length; index++) {
      final character = source[index];
      final next = index + 1 < source.length ? source[index + 1] : '';
      if (state == 0) {
        if (character == '"') {
          ignored[index] = true;
          state = 1;
        } else if (character == '/' && next == '/') {
          ignored[index] = true;
          ignored[++index] = true;
          state = 2;
        } else if (character == '/' && next == '*') {
          ignored[index] = true;
          ignored[++index] = true;
          state = 3;
        }
        continue;
      }
      ignored[index] = true;
      if (state == 1) {
        if (character == r'\' && index + 1 < source.length) {
          ignored[++index] = true;
        } else if (character == '"') {
          state = 0;
        }
      } else if (state == 2) {
        if (character == '\n') state = 0;
      } else if (character == '*' && next == '/') {
        ignored[++index] = true;
        state = 0;
      }
    }
    return ignored;
  }
}
