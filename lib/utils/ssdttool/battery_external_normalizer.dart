class BatteryExternalNormalizer {
  const BatteryExternalNormalizer._();

  static const _canonicalTypes = <String, String>{
    'UNKNOWNOBJ': 'UnknownObj',
    'INTOBJ': 'IntObj',
    'STROBJ': 'StrObj',
    'BUFFOBJ': 'BuffObj',
    'PKGOBJ': 'PkgObj',
    'FIELDUNITOBJ': 'FieldUnitObj',
    'DEVICEOBJ': 'DeviceObj',
    'EVENTOBJ': 'EventObj',
    'METHODOBJ': 'MethodObj',
    'MUTEXOBJ': 'MutexObj',
    'OPREGIONOBJ': 'OpRegionObj',
    'POWERRESOBJ': 'PowerResObj',
    'THERMALZONEOBJ': 'ThermalZoneObj',
    'BUFFFIELDOBJ': 'BuffFieldObj',
  };

  static String normalizePath(String path) {
    var value = path.trim();
    if (value.isEmpty) return '';
    if (!value.startsWith(r'\')) value = r'\' + value;
    return value
        .split('.')
        .where((part) => part.isNotEmpty)
        .map((part) => part.replaceFirst(RegExp(r'_+$'), '').toUpperCase())
        .join('.');
  }

  static String pathKey(String path) => normalizePath(path)
      .split('.')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part
            .replaceAll(r'\', '')
            .replaceFirst(RegExp(r'_+$'), '')
            .toUpperCase(),
      )
      .join('.');

  static String canonicalObjectType(String type) {
    return _canonicalTypes[type.trim().toUpperCase()] ?? 'UnknownObj';
  }

  static String objectTypeForDeclaration(String declarationKind) {
    final value = declarationKind.trim();
    final canonical = canonicalObjectType(value);
    if (canonical != 'UnknownObj' || value.toUpperCase() == 'UNKNOWNOBJ') {
      return canonical;
    }
    return const <String, String>{
          'METHOD': 'MethodObj',
          'DEVICE': 'DeviceObj',
          'MUTEX': 'MutexObj',
          'POWERRESOURCE': 'PowerResObj',
          'THERMALZONE': 'ThermalZoneObj',
          'OPERATIONREGION': 'OpRegionObj',
          'DATATABLEREGION': 'OpRegionObj',
          'EVENT': 'EventObj',
        }[value.toUpperCase()] ??
        'UnknownObj';
  }

  static Set<String> canonicalize(
    Iterable<String> externals, {
    Map<String, String> preferredTypes = const {},
    Map<String, String> pathAliases = const {},
  }) {
    final aliases = <String, String>{
      for (final entry in pathAliases.entries)
        pathKey(entry.key): normalizePath(entry.value),
    };
    final preferred = <String, String>{
      for (final entry in preferredTypes.entries)
        pathKey(entry.key): canonicalObjectType(entry.value),
    };
    final declaration = RegExp(
      r'^\s*External\s*\(\s*([^,\)]+)\s*,\s*([^,\)]+)',
      caseSensitive: false,
    );
    final candidates = <String, ({String path, Set<String> types})>{};
    final lines = externals.toList()
      ..sort(
          (left, right) => left.toLowerCase().compareTo(right.toLowerCase()));

    for (final line in lines) {
      final match = declaration.firstMatch(line);
      if (match == null) continue;
      var path = normalizePath(match.group(1) ?? '');
      var key = pathKey(path);
      if (aliases.containsKey(key)) {
        path = aliases[key]!;
        key = pathKey(path);
      }
      if (key.isEmpty) continue;
      final type = canonicalObjectType(match.group(2) ?? '');
      final old = candidates[key];
      candidates[key] = (
        path: old == null ||
                path.toLowerCase().compareTo(old.path.toLowerCase()) < 0
            ? path
            : old.path,
        types: {...?old?.types, type},
      );
    }

    final result = <String>{};
    for (final entry in candidates.entries) {
      var type = preferred[entry.key];
      if (type == null || type == 'UnknownObj') {
        final types = entry.value.types.toList()
          ..sort((left, right) {
            final priority = _typePriority(right) - _typePriority(left);
            return priority != 0
                ? priority
                : left.toLowerCase().compareTo(right.toLowerCase());
          });
        type = types.isEmpty ? 'UnknownObj' : types.first;
      }
      result.add('External (${entry.value.path}, $type)');
    }
    return result;
  }

  static int _typePriority(String type) {
    switch (type.toUpperCase()) {
      case 'METHODOBJ':
        return 100;
      case 'DEVICEOBJ':
        return 90;
      case 'POWERRESOBJ':
      case 'THERMALZONEOBJ':
        return 80;
      case 'MUTEXOBJ':
      case 'EVENTOBJ':
        return 70;
      case 'FIELDUNITOBJ':
      case 'BUFFFIELDOBJ':
        return 60;
      case 'OPREGIONOBJ':
        return 50;
      case 'UNKNOWNOBJ':
        return 0;
      default:
        return 40;
    }
  }
}
