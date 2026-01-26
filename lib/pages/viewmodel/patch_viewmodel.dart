//  patch_viewmodel.dart
//  Created by JeoJay127
//
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rapidssdt/pages/model/ssdt_category.dart';
import 'package:rapidssdt/pages/model/patch_state.dart';
import 'package:rapidssdt/pages/viewmodel/patch_config.dart';
import 'package:rapidssdt/utils/ssdttool/config.dart';
import 'package:rapidssdt/utils/ssdttool/manager.dart';
import 'package:path/path.dart' as path;
import 'package:rapidssdt/utils/ssdttool/table.dart';

class PatchViewModel extends ChangeNotifier {
  // 状态管理
  final ValueNotifier<PatchState> _state = ValueNotifier(
    PatchState(selectedCategory: '核心补丁', selectedHpet: 'C'),
  );
  late Map<String, PatchConfig> _patchConfigs;
  ValueNotifier<PatchState> get state => _state;
  Map<String, PatchConfig> get patchConfigs => _patchConfigs;
  String get desktopDirectory => _desktopDirectory;
  
  bool _isDumping = false;
  final ACPIToolManager manager;
  // 补丁分类常量
  final List<Map<String, dynamic>> patchCategories =
      SsdtCategory.patchCategories;
  // 桌面目录
  late String _desktopDirectory;
  // ACPI 偏好配置
  late ValueNotifier<AcpiConfig> acpiConfig;
  AcpiConfig get config => acpiConfig.value;

  PatchViewModel({AcpiConfig? acpiconfig, ACPIToolManager? manager})
    : acpiConfig = ValueNotifier(acpiconfig ?? AcpiConfig()),
      manager = manager ?? ACPIToolManager(acpiConfig: acpiconfig) {
    _initOutputDir();
    _initPatchConfigs();
  }

  void updateConfig(
    AcpiConfig newConfig, {
    Function(String)? onError,
    Function(String)? onLog,
  }) {
    final old = acpiConfig.value;
    // ACPI工具校验（local, legacy）
    if (old.useLocaliAsl != newConfig.useLocaliAsl ||
        old.useLeagcyiAsl != newConfig.useLeagcyiAsl) {
      checkIaslValid(
        local: newConfig.useLocaliAsl,
        legacy: newConfig.useLeagcyiAsl,
        onError: (err) => onError?.call(err),
      );
    }

    // 删除dsl
    if (old.deleteDsl != newConfig.deleteDsl) {
      onLog?.call('是否删除源.dsl文件: ${newConfig.deleteDsl ? "是" : "否"}');
    }

    // 强制编译
    if (old.force != newConfig.force) {
      onLog?.call('是否强制编译: ${newConfig.force ? "是" : "否"}');
    }
    // 覆盖EFI
    if (old.overwriteEFI != newConfig.overwriteEFI) {
      onLog?.call('是否覆盖目标EFI: ${newConfig.overwriteEFI ? "是" : "否"}');
    }

    // 匹配模式
    if (old.acpiMatchMode != newConfig.acpiMatchMode) {
      onLog?.call('匹配模式: ${newConfig.acpiMatchMode.value}');
    }

    acpiConfig.value = newConfig;
    manager.acpiConfig = acpiConfig.value.copyWith(
      useLocaliAsl: newConfig.useLocaliAsl,
      deleteDsl: newConfig.deleteDsl,
      useLeagcyiAsl: newConfig.useLeagcyiAsl,
      force: newConfig.force,
      acpiMatchMode: newConfig.acpiMatchMode,
      outputDirectory:
          newConfig.outputDirectory ?? manager.acpiConfig.outputDirectory,
      acpiDirectory:
          newConfig.acpiDirectory ?? manager.acpiConfig.acpiDirectory,
    );
  }

  /// 初始化补丁配置（从manager的动作列表生成）
  void _initPatchConfigs() {
    _patchConfigs = {
      for (final action in manager.actionKeys) action: PatchConfig(),
    };
  }

  /// 初始化默认输出目录（Desktop/ACPIs）
  void _initOutputDir() {
    _desktopDirectory = manager.getDesktopDirectory();
    _updateOutputDirectory(null);
  }

  void _updateOutputDirectory(String? dir, {bool updateAcpiDir = false}) {
    final targetDir = _resolveValidOutputDir(dir);
    manager.acpiConfig = manager.acpiConfig.copyWith(
      outputDirectory: targetDir,
      acpiDirectory: updateAcpiDir
          ? targetDir
          : manager.acpiConfig.acpiDirectory,
    );
    _updateState(outputDir: targetDir);
  }

  String _resolveValidOutputDir(String? dir) {
    if (dir != null && dir.trim().isNotEmpty) {
      return dir;
    }

    return path.join(_desktopDirectory, 'ACPIs');
  }

  /// 加载HPET中断数据
  Future<void> _loadHpetData() async {
    final devs = _state.value.patchContext.devs;
    if (devs == null || devs.isEmpty) return;

    try {
      final (irqs, legacyIrqs) = manager.ssdt.getIrqChoice(
        devs,
        selectedOption: _state.value.selectedHpet,
      );

      // 仅在数据变化时更新状态（减少无效重绘）
      final currentState = _state.value;
      if (!mapEquals(currentState.patchContext.targetIrqs, irqs) ||
          !listEquals(currentState.legacyIrqs, legacyIrqs)) {
        _updateState(
          patchContext: currentState.patchContext.copyWith(targetIrqs: irqs),
          legacyIrqs: legacyIrqs,
        );
      }
    } catch (e) {
      debugPrint('加载HPET数据失败: $e');
      _updateState(
        patchContext: _state.value.patchContext.copyWith(targetIrqs: {}),
        legacyIrqs: [],
      );
    }
  }

  /// 初始化HPET设备与中断数据
  Future<void> _initHpetData() async {
    try {
      final devs = await manager.ssdt.listIrqs();
      final currentState = _state.value;

      // 更新设备列表状态
      _updateState(
        patchContext: currentState.patchContext.copyWith(devs: devs),
      );

      if (devs.isNotEmpty) {
        _updateState(selectedHpet: 'C'); // 默认选中Hpet C
        await _loadHpetData();
      }

      // 更新SSDT-HPET配置可见性（仅当前选中时）
      final hpetConfig = _patchConfigs[ACPITable.ssdtHPET.name];
      if (hpetConfig != null &&
          currentState.selectedAction.name == ACPITable.ssdtHPET.name) {
        hpetConfig.isVisible.value =
            devs.isNotEmpty &&
            (currentState.tablePath != null || currentState.dsdtPath != null);
      }
    } catch (e) {
      debugPrint('初始化HPET数据失败: $e');
      _updateState(patchContext: _state.value.patchContext.copyWith(devs: {}));
    }
  }

  /// 初始化目标ACPI表路径
  void _initTargetSSDTPath() {
    try {
      const Map<String, String> tableSignatureMap = {
        'SSDT-DMAR': 'DMAR',
        'SSDT-FACP': 'FACP',
        'Check-AOAC': 'FACP', // 特殊映射
      };

      tableSignatureMap.forEach((table, tableSignature) {
        final targetPath = manager.getSSDTPathWithSignature(tableSignature);
        _patchConfigs[table]?.data.value = targetPath;
      });
    } catch (e) {
      debugPrint('初始化ACPI路径失败: $e');
    }
  }

  /// 获取选中补丁的说明文本
  String getActionNote() {
    try {
      final currentState = _state.value;
      // 查找当前分类
      final category = patchCategories.firstWhere(
        (c) => c.name == currentState.selectedCategory,
        orElse: () => <String, Object>{'actions': []},
      );
      final actions = category['actions'] as List;
      if (actions.isEmpty) return '无补丁说明';

      final action = actions.firstWhere(
        (a) => a['name'] == currentState.selectedAction.name,
        orElse: () => {'note': '无补丁说明'},
      );
      return action['note'] as String;
    } catch (e) {
      debugPrint('获取补丁说明失败: $e');
      return '获取补丁说明失败';
    }
  }

  /// 更新补丁配置的可见性
  void updatePatchVisibility(
    Map<String, dynamic> selectedAction,
    bool prebuilt,
  ) {
    _updateState(selectedAction: selectedAction);
    final currentState = _state.value;

    for (final entry in _patchConfigs.entries) {
      bool visible = (entry.key == selectedAction.name) && !prebuilt;
      // SSDT-HPET需额外校验路径
      if (entry.key == ACPITable.ssdtHPET.name) {
        visible =
            visible &&
            (currentState.tablePath != null || currentState.dsdtPath != null);
      }
      entry.value.isVisible.value = visible;
    }
  }

  void updatePatchConfigPath(
    String action,
    String? newPath, {
    Function(String)? onError,
  }) {
    // 路径为空时，仅清空配置，不更新输出目录
    if (newPath == null || newPath.trim().isEmpty) {
      _patchConfigs[action]?.data.value = null;
      onError?.call('$action 配置路径清空');
      return;
    }

    // 校验路径是否为文件（避免传入目录导致 dirname 异常）
    if (!FileSystemEntity.isFileSync(newPath)) {
      onError?.call('$action 选择的不是有效文件: $newPath');
      _patchConfigs[action]?.data.value = null;
      return;
    }

    final config = _patchConfigs[action];
    if (config != null) {
      config.data.value = newPath;
      final fileDir = path.dirname(newPath);
      _updateOutputDirectory(fileDir, updateAcpiDir: true);
    } else {
      onError?.call('未找到 $action 的补丁配置');
    }
  }

  /// 重置补丁状态（切换分类/页面时调用）
  void resetPatchStates({String? catName}) {
    _updateState(selectedCategory: catName ?? '核心补丁', selectedAction: {});

    // 重置所有配置可见性
    for (final config in _patchConfigs.values) {
      config.isVisible.value = false;
    }
  }

  /// 处理Legacy IRQ变更
  Future<void> handleLegacyIrqsChange(String irq) async {
    if (irq.isEmpty) {
      _updateState(
        patchContext: _state.value.patchContext.copyWith(targetIrqs: {}),
      );
      return;
    }

    _updateState(selectedHpet: irq);
    await _loadHpetData();
  }

  /// 执行单个补丁（对外入口）
  void runPatch(
    Map<String, dynamic> action, {
    bool prebuilt = false,
    Function(String)? onError,
  }) {
    if (action.isEmpty) {
      onError?.call('请先选择需要定制的SSDT后再进行操作!');
      return;
    }

    try {
      final newContext = _state.value.patchContext.copyWith(prebuilt: prebuilt);
      _updateState(patchContext: newContext);
      _runPatch(action, newContext, onError);
    } catch (e) {
      onError?.call('执行补丁失败: $e');
    }
  }

  /// 执行单个补丁（内部实现）
  void _runPatch(
    Map<String, dynamic> action,
    PatchContext context,
    Function(String)? onError,
  ) {
    try {
      final cfg = _patchConfigs[action.name];
      if (cfg != null) context.data = cfg.data.value;
      manager.runPatch(action, context: context, onError: onError);
    } catch (e) {
      onError?.call('执行补丁[$action]失败: $e');
    }
  }

  /// 批量执行补丁
  void runPatches(
    List<Map<String, dynamic>> actions, {
    bool prebuilt = false,
    String? outputFolder,
    Function(String)? onError,
  }) {
    if (actions.isEmpty) {
      onError?.call('补丁列表为空!');
      return;
    }
    final context = _state.value.patchContext.copyWith(prebuilt: prebuilt);
    manager.runPatches(
      actions,
      context: context,
      outputFolder: outputFolder,
      onError: onError,
    );
  }

  /// 检查IASL工具有效性
  void checkIaslValid({bool? local, bool? legacy, Function(String)? onError}) {
    if (legacy == true) {
      onError?.call(manager.ssdt.legacyWarning);
    }
    manager.ssdt.checkIaslValid(local: local, legacy: legacy);
  }

  /// 提取ACPI表并加载补丁
  Future<void> dumpTablesAndLoadPatches({
    Function(String)? onError,
    Function(String)? onSuccess,
    Future<String?> Function()? onRequestSudoPassword,
  }) async {
    if (_isDumping) {
      onError?.call('正在提取中，请勿重复操作!');
      return;
    }

    _isDumping = true;

    // 提取ACPI表
    try {
      if (Platform.isMacOS) {
        onError?.call(
          '当前${Platform.operatingSystem}平台提取的ACPI表极有可能被OpenCore等注入的ACPI补丁污染,强烈建议在Windows/Linux平台操作!',
        );
      }
      final currentState = _state.value;
      final dumpPath = await manager.dumpTables(
        currentState.outputDir,
        onRequestSudoPassword: onRequestSudoPassword,
      );
      if (dumpPath == null) {
        onError?.call('提取ACPI失败!');
        return;
      }

      _updateState(dumpPath: dumpPath);
      final loadResult = await manager.loadTables(dumpPath);
      if (loadResult != null && loadResult.isNotEmpty) {
        onSuccess?.call('提取ACPI成功!');
        _updateOutputDirectory(loadResult, updateAcpiDir: true);
        _updateState(tablePath: dumpPath, dsdtPath: null);
        _initTargetSSDTPath();
        await _initHpetData();
      }
    } catch (e) {
      onError?.call('准备补丁失败: $e');
    } finally {
      _isDumping = false;
    }
  }

  /// 加载外部ACPI/DSDT文件
  Future<void> loadTables({
    required String selectedPath,
    Function(String)? onError,
  }) async {
    try {
      final isFile = FileSystemEntity.isFileSync(selectedPath);
      final directory = isFile
          ? Directory(selectedPath).parent.path
          : selectedPath;

      // 更新输出目录并加载文件
      _updateState(outputDir: directory);
      final loadResult = await manager.loadTables(selectedPath);
      if (loadResult != null && loadResult.isNotEmpty) {
        _updateOutputDirectory(loadResult, updateAcpiDir: true);
        _updateState(
          tablePath: isFile ? selectedPath : directory,
          dsdtPath: isFile ? selectedPath : null,
        );
        _initTargetSSDTPath();
        await _initHpetData();
      }
    } catch (e) {
      onError?.call('加载DSDT/ACPI失败: $e');
    }
  }

  /// 获取plist文件类型
  String? getPlistType(
    String plistPath, {
    Function(String)? onSuccess,
    Function(String)? onError,
  }) {
    try {
      if (!File(plistPath).existsSync()) {
        onError?.call('config.plist文件不存在: $plistPath');
        return null;
      }

      final plistType = manager.getPlistType(plistPath);
      if (plistType == null) {
        onError?.call('无法识别的plist文件格式');
        return null;
      }

      onSuccess?.call('config.plist类型为 "$plistType"');
      return plistType;
    } catch (e) {
      onError?.call('解析plist类型失败: $e');
      return null;
    }
  }

  /// 合并plist文件（ACPI配置与config.plist整合）
  void mergePlist({Function(String)? onError}) {
    try {
      final currentState = _state.value;

      // 校验必要参数
      if (currentState.tablePath == null) {
        onError?.call('请先选择ACPIs目录!');
        return;
      }
      if (currentState.configPath == null) {
        onError?.call('请先选择EFI目录下config.plist文件!');
        return;
      }
      if (!Directory(currentState.tablePath!).existsSync() &&
          !File(currentState.tablePath!).existsSync()) {
        onError?.call('ACPI路径无效: ${currentState.tablePath}');
        return;
      }
      if (!File(currentState.configPath!).existsSync()) {
        onError?.call('config.plist文件不存在: ${currentState.configPath}');
        return;
      }

      // 执行合并操作
      manager.mergePlist(
        currentState.tablePath!,
        currentState.configPath!,
        overwrite: config.overwriteEFI,
      );
    } catch (e) {
      onError?.call('合并plist文件失败: $e');
    }
  }

  /// 更新配置文件路径（如config.plist）
  void updateConfigPath(String? newPath) {
    _updateState(configPath: newPath);
  }

  void _updateState({
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
  }) {
    _state.value = _state.value.copyWith(
      selectedCategory: selectedCategory,
      selectedAction: selectedAction,
      dumpPath: dumpPath,
      dsdtPath: dsdtPath,
      tablePath: tablePath,
      configPath: configPath,
      outputDir: outputDir,
      selectedHpet: selectedHpet,
      legacyIrqs: legacyIrqs,
      patchContext: patchContext,
    );
  }

  @override
  void dispose() {
    // 释放所有PatchConfig资源
    for (final config in _patchConfigs.values) {
      config.dispose();
    }
    _state.dispose();
    acpiConfig.dispose();
    super.dispose();
  }
}
