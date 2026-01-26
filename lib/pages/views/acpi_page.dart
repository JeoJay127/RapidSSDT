//  acpi_page.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/pages/model/patch_state.dart';
import 'package:rapidssdt/pages/provider/patch_viewmodel_provider.dart';
import 'package:rapidssdt/pages/views/about_page.dart';
import 'package:rapidssdt/pages/views/acpi_options.dart';
import 'package:rapidssdt/pages/views/markdown_page.dart';
import 'package:rapidssdt/pages/views/ssdt_platform.dart';
import 'package:rapidssdt/pages/views/update_check.dart';
import 'package:rapidssdt/pages/views/widgets/gpu_spoof.dart';
import 'package:rapidssdt/pages/views/widgets/hpet.dart';
import 'package:rapidssdt/pages/views/widgets/imei.dart';
import 'package:rapidssdt/pages/views/widgets/pci_bridge.dart';
import 'package:rapidssdt/pages/views/widgets/pci_disable.dart';
import 'package:rapidssdt/pages/views/widgets/pnlf.dart';
import 'package:rapidssdt/pages/views/widgets/table_selection.dart';
import 'package:rapidssdt/pages/views/widgets/usbx.dart';
import 'package:rapidssdt/pages/views/widgets/xosi.dart';
import 'package:rapidssdt/utils/log/log.dart';
import 'package:rapidssdt/utils/log/logwidet.dart';
import 'package:rapidssdt/utils/ssdttool/config.dart';
import 'package:rapidssdt/utils/ssdttool/table.dart';
import 'package:rapidssdt/widgets/choose_file.dart';
import 'package:rapidssdt/widgets/inkwell_widget.dart';
import 'package:rapidssdt/pages/viewmodel/patch_viewmodel.dart';

class AcpiPage extends StatefulWidget {
  const AcpiPage({super.key});
  @override
  State<AcpiPage> createState() => _AcpiPageState();
}

class _AcpiPageState extends State<AcpiPage> {
  late PatchViewModel patchViewModel = PatchViewModelProvider.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateDialog.checkLatestRelease(context);
    });
  }

  /// 构建ACPI选项
  /// [action] ACPI选项名称
  Widget _buildPatchOption(String action) {
    final config = patchViewModel.patchConfigs[action];
    if (config == null) return const SizedBox.shrink();

    Widget buildWithConfig(Widget Function(dynamic data) builder) {
      return ValueListenableBuilder<dynamic>(
        valueListenable: config.data,
        builder: (context, data, _) => builder(data),
      );
    }

    Widget bindConfig(
      Widget Function(dynamic data, ValueChanged<dynamic> onChanged) builder,
    ) {
      return buildWithConfig(
        (data) => builder(data, (v) => config.data.value = v),
      );
    }

    final widgetBuilders = <String, Widget Function()>{
      ACPITable.ssdtHPET.name: () => ValueListenableBuilder<PatchState>(
        valueListenable: patchViewModel.state,
        builder: (context, state, _) => HPETPatchOptions(
          currentLegacyIRQs: state.legacyIrqs,
          onOptionChanged: patchViewModel.handleLegacyIrqsChange,
          onCustomIRQChanged: patchViewModel.handleLegacyIrqsChange,
        ),
      ),

      ACPITable.ssdtUSBX.name: () => bindConfig(
        (data, onChanged) => USBXPatchOptions(onChanged: onChanged),
      ),

      ACPITable.ssdtPNLF.name: () => bindConfig(
        (data, onChanged) => PNLFPatchOptions(onChanged: onChanged),
      ),

      ACPITable.ssdtXOSI.name: () => bindConfig(
        (data, onChanged) => XOSIPatchOptions(onChanged: onChanged),
      ),

      ACPITable.ssdtBridge.name: () => bindConfig(
        (data, onChanged) => PCIBridgePatchOptions(onChanged: onChanged),
      ),

      ACPITable.ssdtDMAR.name: () => buildWithConfig(
        (data) => TableSelectionWidget(
          buttonText: '选择DMAR',
          hintText: '请选择需要定制的DMAR表',
          initialPath: data,
          onChanged: (value) => patchViewModel.updatePatchConfigPath(
            action,
            value,
            onError: (error) => Log.warning(error),
          ),
        ),
      ),

      ACPITable.ssdtIMEI.name: () => bindConfig(
        (data, onChanged) => IMEIPatchOptions(onChanged: onChanged),
      ),
      ACPITable.checkAOAC.name: () => buildWithConfig(
        (data) => TableSelectionWidget(
          buttonText: '选择FACP',
          hintText: '请选择FACP表',
          initialPath: data,
          onChanged: (value) => patchViewModel.updatePatchConfigPath(
            action,
            value,
            onError: (error) => Log.warning(error),
          ),
        ),
      ),
      ACPITable.ssdtFACP.name: () => buildWithConfig(
        (data) => TableSelectionWidget(
          buttonText: '选择FACP',
          hintText: '请选择FACP表',
          initialPath: data,
          onChanged: (value) => patchViewModel.updatePatchConfigPath(
            action,
            value,
            onError: (error) => Log.warning(error),
          ),
        ),
      ),

      ACPITable.ssdtPCIDISABLE.name: () =>
          bindConfig((data, onChanged) => PciDisable(onChanged: onChanged)),

      ACPITable.ssdtGPUSPOOF.name: () =>
          bindConfig((data, onChanged) => GpuSpoof(onChanged: onChanged)),
          
    };

    return widgetBuilders[action]?.call() ?? const SizedBox.shrink();
  }

  // 可见补丁UI
  Widget _buildVisiblePatches() {
    return ValueListenableBuilder<PatchState>(
      valueListenable: patchViewModel.state,
      builder: (context, state, _) {
        final selectedAction = state.selectedAction;
        if (selectedAction.isEmpty) return const SizedBox.shrink();

        final config = patchViewModel.patchConfigs[selectedAction.name];
        if (config == null) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: config.isVisible,
          builder: (context, isVisible, _) {
            if (!isVisible) return const SizedBox.shrink();
            return Flexible(child: _buildPatchOption(selectedAction.name));
          },
        );
      },
    );
  }

  // 日志面板
  Widget _buildLogPanel() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 600),
      child: Column(
        spacing: 10,
        children: [
          const Text('日志', style: TextStyle(fontSize: 11)),
          Flexible(
            flex: 2,
            child: LogWidget(showChannelTag: false, allChannel: true),
          ),
          ValueListenableBuilder<PatchState>(
            valueListenable: patchViewModel.state,
            builder: (context, state, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 15,
                children: [
                  InkWellWidget.common(
                    onTap: Log.clearAll,
                    child: const Text(
                      '清除日志',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                  InkWellWidget.common(
                    onTap: () async {
                      Log.exportToDirectory(
                        targetDirectory: patchViewModel.desktopDirectory,
                        onSuccess: (log) => Log(log),
                        onError: (error) => Log.error(error),
                      );
                    },
                    child: const Text(
                      '导出日志',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                  InkWellWidget.common(
                    onTap: () => patchViewModel.runPatch(
                      state.selectedAction,
                      prebuilt: state.selectedCategory == '预制补丁',
                      onError: (error) => Log.warning(error),
                    ),
                    child: const Text(
                      '执行补丁',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 自定义列表项
  Widget _buildListTile({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isSelected,
    required bool isDark,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Material(
      color: isSelected
          ? (isDark ? const Color(0xFF464646) : const Color(0xFFE6E6E6))
          : (isDark ? const Color(0xFF323232) : Colors.white),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        splashColor: isDark ? Colors.white12 : Colors.black12,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: ListTile(
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSelected ? primaryColor : null,
                fontSize: 12,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? primaryColor.withAlpha(200) : null,
                    ),
                    maxLines: 3,
                  )
                : null,
            selected: isSelected,
            selectedTileColor: isDark
                ? const Color(0xFF464646)
                : const Color(0xFFE6E6E6),
          ),
        ),
      ),
    );
  }

  // 文件选择器
  Widget _buildFilePicker({
    required String buttonText,
    required OpenMode mode,
    required String? Function() getPath,
    required void Function(String?) setPath,
    String hint = '请选择文件/目录',
    List<String>? extensions,
    Function(String)? onChanged,
  }) {
    return ValueListenableBuilder<PatchState>(
      valueListenable: patchViewModel.state,
      builder: (context, state, _) {
        final path = getPath();
        return ChooseFileWidget(
          onChanged: (newPath) {
            setPath(newPath);
            onChanged?.call(newPath);
          },
          initialPath: path,
          hintText: path ?? hint,
          buttons: [
            ChooseFileButton(
              text: buttonText,
              mode: mode,
              allowedExtensions: extensions,
            ),
          ],
        );
      },
    );
  }

  // 类别列表
  Widget _buildCategoryList(bool isDark) {
    return ValueListenableBuilder<PatchState>(
      valueListenable: patchViewModel.state,
      builder: (context, state, _) {
        return ListView(
          children: patchViewModel.patchCategories.map((category) {
            final catName = category.name;
            return _buildListTile(
              title: catName,
              onTap: () => patchViewModel.resetPatchStates(catName: catName),
              isSelected: state.selectedCategory == catName,
              isDark: isDark,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionList(bool isDark) {
    return ValueListenableBuilder<PatchState>(
      valueListenable: patchViewModel.state,
      builder: (context, state, _) {
        final selectedCat = state.selectedCategory;
        final selectedAction = state.selectedAction;

        final category = patchViewModel.patchCategories.firstWhere(
          (c) => c.name == selectedCat,
          orElse: () => <String, Object>{'actions': []},
        );

        final actions = category['actions'] as List;

        return ListView(
          children: actions.map((action) {
            final actionName = action['name'] as String;
            final actionRemark = action['remark'] as String;
            final prebuilt = selectedCat == '预制补丁';
            return _buildListTile(
              title: actionName,
              subtitle: actionRemark,
              onTap: () =>
                  patchViewModel.updatePatchVisibility(action, prebuilt),
              isSelected: selectedAction.name == actionName,
              isDark: isDark,
            );
          }).toList(),
        );
      },
    );
  }

  // 补丁说明
  Widget _buildPatchNote() {
    return ValueListenableBuilder<PatchState>(
      valueListenable: patchViewModel.state,
      builder: (context, state, _) {
        if (state.selectedAction.isEmpty) return const SizedBox.shrink();
        return Flexible(
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 10,
              maxHeight: 200,
              minWidth: double.infinity,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: SelectableText.rich(
                TextSpan(text: patchViewModel.getActionNote()),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        );
      },
    );
  }

  // ACPI提取+输出目录
  Widget _buildAcpiExtractRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        // 提取ACPI按钮
        InkWellWidget.common(
          child: const Text(
            '提取ACPI',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
          onTap: () async {
            await patchViewModel.dumpTablesAndLoadPatches(
              onError: (msg) => Log.error(msg),
              onRequestSudoPassword: () async {
                // 弹窗输入密码
                return await showDialog<String>(
                  context: context,
                  builder: (context) {
                    String password = '';
                    return AlertDialog(
                      title: const Text('需要管理员权限'),
                      content: TextField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '请输入电脑开机密码',
                        ),
                        onChanged: (v) => password = v,
                        onSubmitted: (value) => Navigator.pop(context, value),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, password),
                          child: const Text('确定'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        // 输出目录选择
        Flexible(
          child: ValueListenableBuilder<PatchState>(
            valueListenable: patchViewModel.state,
            builder: (context, state, _) {
              return ChooseFileWidget(
                onChanged: (newDir) => patchViewModel.acpiConfig.value.copyWith(
                  outputDirectory: newDir,
                ),
                initialPath: state.outputDir,
                hintText: state.outputDir,
                buttons: [
                  ChooseFileButton(text: '输出目录', mode: OpenMode.directory),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // DSDT/ACPI选择器
  Widget _buildDsdtAcpiPicker() {
    return ValueListenableBuilder<PatchState>(
      valueListenable: patchViewModel.state,
      builder: (context, state, _) {
        return ChooseFileWidget(
          onChanged: (selectedPath) => patchViewModel.loadTables(
            selectedPath: selectedPath,
            onError: (msg) => Log.error(msg),
          ),
          initialPath: state.tablePath,
          hintText: '请选择DSDT文件或ACPIs目录',
          buttons: [
            ChooseFileButton(
              text: '选择DSDT',
              mode: OpenMode.file,
              allowedExtensions: ['aml', 'dat'],
            ),
            ChooseFileButton(text: '选择ACPIs', mode: OpenMode.directory),
          ],
        );
      },
    );
  }

  Widget _buildConfigSection() {
    return Row(
      spacing: 10,
      children: [
        InkWellWidget.common(
          child: const Text(
            '合并config',
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
          onTap: () =>
              patchViewModel.mergePlist(onError: (msg) => Log.error(msg)),
        ),
        Flexible(
          child: _buildFilePicker(
            buttonText: '选择config',
            mode: OpenMode.file,
            getPath: () => patchViewModel.state.value.configPath,
            setPath: (newPath) => patchViewModel.updateConfigPath(newPath),
            hint: '请选择config.plist文件',
            extensions: ['plist'],
            onChanged: (newPath) {
              patchViewModel.getPlistType(
                newPath,
                onSuccess: (msg) => Log(msg),
                onError: (msg) => Log.error(msg),
              );
            },
          ),
        ),
      ],
    );
  }

  // 文件选择区域
  Widget _buildFileSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAcpiExtractRow(),
        _buildDsdtAcpiPicker(),
        _buildConfigSection(),
      ],
    );
  }

  // 类别 + 操作列表区域
  Widget _buildCategoryActionList(bool isDark) {
    return Flexible(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(flex: 1, child: _buildCategoryList(isDark)),
          const VerticalDivider(width: 1),
          Flexible(flex: 2, child: _buildActionList(isDark)),
        ],
      ),
    );
  }

  // 偏好设置
  Widget _buildHeaderOptions() {
    return ValueListenableBuilder<AcpiConfig>(
      valueListenable: patchViewModel.acpiConfig,
      builder: (_, config, _) {
        return AcpiOptions(
          config: config,
          onChanged: (newConfig) => patchViewModel.updateConfig(
            newConfig,
            onLog: (msg) => Log(msg),
            onError: (msg) => Log.warning(msg),
          ),
        );
      },
    );
  }

  void showOptionsDialog({
    Widget? child,
    double? heightScale,
    double? widthScale,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        elevation: 0,
        alignment: Alignment.topLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.hardEdge,
        insetPadding: const EdgeInsets.only(left: 15, top: 50, bottom: 15),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * (widthScale ?? 0.45),
          height: MediaQuery.of(context).size.height * (heightScale ?? 1),
          child: child ?? Container(),
        ),
      ),
    );
  }

  // 选项面板
  Widget _buildOptionPanel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 15,
      children: [
        InkWellWidget.common(
          backgroundColor: Colors.brown,
          onTap: () => showOptionsDialog(child: _buildHeaderOptions()),
          child: const Text(
            '偏好设置',
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
        InkWellWidget.common(
          backgroundColor: Colors.pink,
          onTap: () => showOptionsDialog(child: SsdtPlatformWidget()),
          child: const Text(
            '平台补丁',
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
        InkWellWidget.common(
          backgroundColor: Colors.deepPurple,
          onTap: () => showOptionsDialog(
            child: MarkdownPage(mdPath: 'assets/guide/guide.md'),
          ),
          child: const Text(
            '补丁指南',
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
        InkWellWidget.common(
          backgroundColor: Colors.indigo,
          onTap: () => showOptionsDialog(heightScale: 0.72, child: AboutPage()),
          child: const Text(
            '关于应用',
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn(bool isDark) {
    return Flexible(
      flex: 1,
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionPanel(),
          _buildFileSection(),
          _buildCategoryActionList(isDark),
        ],
      ),
    );
  }

  // 选中操作提示
  Widget _buildSelectedActionTip() {
    return ValueListenableBuilder<PatchState>(
      valueListenable: patchViewModel.state,
      builder: (context, state, _) {
        if (state.selectedAction.isEmpty) return const SizedBox.shrink();
        return Text(
          '选择补丁: ${state.selectedAction.name}',
          style: const TextStyle(fontSize: 11),
        );
      },
    );
  }

  Widget _buildRightColumn(bool isDark) {
    return Flexible(
      flex: 1,
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSelectedActionTip(),
          _buildPatchNote(),
          _buildVisiblePatches(),
          Flexible(flex: 2, child: _buildLogPanel()),
        ],
      ),
    );
  }

  // 主内容区域
  Widget _buildMainContent(bool isDark) {
    return Row(
      spacing: 15,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeftColumn(isDark),
        const VerticalDivider(width: 1),
        _buildRightColumn(isDark),
      ],
    );
  }

  // 资源释放
  @override
  void dispose() {
    patchViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: _buildMainContent(isDark),
      ),
    );
  }
}
