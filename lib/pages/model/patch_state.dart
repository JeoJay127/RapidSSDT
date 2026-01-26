//  patch_state.dart
//  Created by JeoJay127
//
import 'package:rapidssdt/utils/ssdttool/manager.dart';

class PatchState {
  final String selectedCategory;
  final Map<String, dynamic> selectedAction;
  final String? dumpPath;
  final String? dsdtPath;
  final String? tablePath;
  final String? configPath;
  final String outputDir;
  final String selectedHpet;
  final List<String> legacyIrqs;
  final PatchContext patchContext;

  PatchState({
    this.selectedCategory = '',
    this.selectedAction = const {},
    this.dumpPath,
    this.dsdtPath,
    this.tablePath,
    this.configPath,
    this.outputDir = '',
    this.selectedHpet = '',
    this.legacyIrqs = const [],
    PatchContext? patchContext,
  }) : patchContext = patchContext ?? PatchContext();

  PatchState copyWith({
    String? selectedCategory,
    Map<String, dynamic>? selectedAction,
    String? dumpPath,
    String? dsdtPath,
    String? tablePath,
    String? configPath,
    String? outputDir,
    String? selectedHpet,
    List<String>? legacyIrqs,
    PatchContext? patchContext,
  }) => PatchState(
    selectedCategory: selectedCategory ?? this.selectedCategory,
    selectedAction: selectedAction ?? this.selectedAction,
    dumpPath: dumpPath ?? this.dumpPath,
    dsdtPath: dsdtPath ?? this.dsdtPath,
    tablePath: tablePath ?? this.tablePath,
    configPath: configPath ?? this.configPath,
    outputDir: outputDir ?? this.outputDir,
    selectedHpet: selectedHpet ?? this.selectedHpet,
    legacyIrqs: legacyIrqs ?? this.legacyIrqs,
    patchContext: patchContext ?? this.patchContext,
  );
}
