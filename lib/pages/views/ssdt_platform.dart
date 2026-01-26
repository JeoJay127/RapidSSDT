//  ssdt_platform.dart
//  Created by JeoJay127
//
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rapidssdt/pages/model/ssdt_platform.dart';
import 'package:rapidssdt/pages/model/ssdt_item.dart';
import 'package:rapidssdt/pages/provider/patch_viewmodel_provider.dart';
import 'package:rapidssdt/pages/viewmodel/patch_viewmodel.dart';
import 'package:rapidssdt/pages/views/widgets/ssdt_listview.dart';
import 'package:rapidssdt/utils/log/log.dart';
import 'package:rapidssdt/utils/ssdttool/table.dart';
import 'package:rapidssdt/widgets/button_segment_widget.dart';
import 'package:rapidssdt/widgets/checkboxlist/checkbox_title.dart';
import 'package:rapidssdt/widgets/custom_dropdown_button.dart';
import 'package:rapidssdt/widgets/inkwell_widget.dart';
import 'package:rapidssdt/utils/constant.dart';

class SsdtPlatformWidget extends StatefulWidget {
  const SsdtPlatformWidget({super.key, this.cpuType, this.platformType});
  final String? cpuType;
  final String? platformType;

  @override
  State<SsdtPlatformWidget> createState() => _SsdtPlatformState();
}

class _SsdtPlatformState extends State<SsdtPlatformWidget> {
  late String cpuType;
  late String platformType;
  late PatchViewModel patchViewModel = PatchViewModelProvider.of(context);
  final ValueNotifier<String?> selectedComboBoxValue = ValueNotifier(null);
  final ValueNotifier<Set<SsdtItem>> selectedSsdtNotifier = ValueNotifier(
    <SsdtItem>{},
  );

  @override
  void initState() {
    super.initState();
    cpuType = widget.cpuType ?? 'Intel';
    platformType = widget.platformType ?? '台式机';
    _resolvePlatformSSDT();
  }

  // 解析 SSDT 状态
  void _resolveSSDTState(List<SsdtItem> ssdtItems, {bool all = false}) {
    selectedSsdtNotifier.value = all
        ? Set.from(ssdtItems)
        : {
            for (final e in ssdtItems)
              if (e.isBasic) e,
          };
  }

  // 解析平台 SSDT 状态
  void _resolvePlatformSSDT() {
    final mapping = SsdtPlatform.platform_mapping[cpuType]?[platformType];
    final List<String> platforms = mapping?['platform']?.keys.toList() ?? [];

    if (platforms.isEmpty) {
      selectedComboBoxValue.value = null;
      return;
    }

    // 当前值仍然有效,直接保留
    if (platforms.contains(selectedComboBoxValue.value)) {
      return;
    }

    // 回退到默认 index
    final int index = mapping?['index'] ?? 0;

    selectedComboBoxValue.value = index >= 0 && index < platforms.length
        ? platforms[index]
        : platforms.first;
  }

  // 执行 SSDT 补丁
  void _runSelectedSsdt({required bool prebuilt}) {
    if (selectedSsdtNotifier.value.isEmpty) {
      Log('未选择任何 SSDT');
      return;
    }

    final ssdts = selectedSsdtNotifier.value.map((e) {
      e.prebuilt = prebuilt;
      return e.toMap();
    }).toList();
    Log('当前平台信息: ${selectedComboBoxValue.value}');
    Log(
      '${prebuilt ? "预制" : "定制"} SSDT 列表: ${ssdts.map((e) => e.name).toList()}',
    );
    Log("");
    String outputFolder =
        "${selectedComboBoxValue.value}-${prebuilt ? '预制SSDT' : '定制SSDT'}";
    patchViewModel.runPatches(
      ssdts,
      prebuilt: prebuilt,
      outputFolder: outputFolder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final platformList =
        SsdtPlatform.platform_mapping[cpuType]?[platformType]?['platform']?.keys
            .toList() ??
        [];
    final List<DropdownOption> platformOptions = platformList
        .toSet()
        .map<DropdownOption>(
          (p) => DropdownOption(value: p.toString(), label: p.toString()),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSegmentRow(
            label: 'CPU类型:',
            options: SsdtPlatform.platform_mapping.keys.toList(),
            onChanged: (cpu) {
              setState(() {
                cpuType = cpu.first.toString();
                _resolvePlatformSSDT();
              });
            },
          ),
          _buildSegmentRow(
            label: '平台类型:',
            options:
                SsdtPlatform.platform_mapping[cpuType]?.keys.toList() ?? [],
            onChanged: (platform) {
              setState(() {
                platformType = platform.first.toString();
                _resolvePlatformSSDT();
              });
            },
          ),

          // 平台信息下拉 + SSDT 列表
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: selectedComboBoxValue,
              builder: (context, value, _) {
                final platformDetail =
                    SsdtPlatform
                        .platform_mapping[cpuType]?[platformType]?['platform']?[value] ??
                    {};
                final ssdtItems = _buildSsdtItems(platformDetail);
                _resolveSSDTState(ssdtItems);
                return ValueListenableBuilder<Set<SsdtItem>>(
                  valueListenable: selectedSsdtNotifier,
                  builder: (_, selectedSet, _) {
                    final selectedItems = selectedSet.toList();
                    // Log(
                    //   '当前选中 SSDT 列表: ${selectedItems.map((e) => e.name).toList()}',
                    // );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlatformDropdown(
                          value,
                          platformOptions,
                          ssdtItems,
                        ),
                        Expanded(
                          child: SsdtListView(
                            items: ssdtItems,
                            initialSelectedItems: selectedItems,
                            onSelectionChanged: (selected) {
                              if (!listEquals(selectedItems, selected)) {
                                selectedSsdtNotifier.value = selected.toSet();
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          _buildLegendRow(),
          const SizedBox(height: 5),
          _buildActionRow(),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  /// 构建 CPU / 平台 Segment 行
  Widget _buildSegmentRow({
    required String label,
    required List<String> options,
    required ValueChanged<Set<Object>> onChanged,
  }) {
    return Row(
      spacing: 10,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        ButtonSegmentWidget(labels: options, onSelectionChanged: onChanged),
      ],
    );
  }

  /// 构建平台信息下拉框
  Widget _buildPlatformDropdown(
    String? value,
    List<DropdownOption> options,
    List<SsdtItem> ssdtItems,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text(
            '平台信息:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          CustomDropdownButton(
            value: value,
            showPlaceholder: false,
            options: options,
            onChanged: (selectedValue) {
              // 避免重复选择
              if (selectedValue == selectedComboBoxValue.value) return;
              selectedComboBoxValue.value = selectedValue;
              _resolveSSDTState(ssdtItems);
            },
          ),
          ValueListenableBuilder<Set<SsdtItem>>(
            valueListenable: selectedSsdtNotifier,
            builder: (_, state, _) {
              final allSelected = state.length == ssdtItems.length;
              return CheckboxTile(
                label: '勾选所有',
                selected: allSelected,
                onChanged: (value) => _resolveSSDTState(ssdtItems, all: value),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 生成 SsdtItem 列表
  List<SsdtItem> _buildSsdtItems(Map<String, dynamic> detail) {
    List<SsdtItem> parseList(
      List<dynamic> list, {
      bool isBasic = false,
      bool isRecommend = false,
      bool isOptional = false,
    }) {
      return list.map((e) {
        return SsdtItem(
          name: e['name'],
          remark: e['remark'] ?? '',
          note: e['note'],
          extra: e['extra'],
          isBasic: isBasic,
          isRecommend: isRecommend,
          isOptional: isOptional,
        );
      }).toList();
    }

    return [
      ...parseList(detail['basic'] ?? [], isBasic: true),
      ...parseList(detail['recommend'] ?? [], isRecommend: true),
      ...parseList(detail['optional'] ?? [], isOptional: true),
    ];
  }

  Widget _buildLegendRow() {
    Widget buildLegend(String text, Color color) {
      return Row(
        children: [
          Transform.translate(
            offset: const Offset(0, 2),
            child: Text('*', style: TextStyle(fontSize: 15, color: color)),
          ),
          const SizedBox(width: 2),
          Text(text, style: TextStyle(fontSize: 11, color: color)),
        ],
      );
    }

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildLegend('核心(官方推荐)', Constant.ssdtBasicColor),
          const SizedBox(width: 8),
          buildLegend('推荐(功能修复)', Constant.ssdtRecommendColor),
          const SizedBox(width: 8),
          buildLegend('可选(功能完善)', Constant.ssdtOptionalColor),
        ],
      ),
    );
  }

  /// 定制 / 预制 SSDT
  Widget _buildActionRow() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWellWidget.common(
            child: const Text(
              "定制SSDT",
              style: TextStyle(fontSize: 11, color: Colors.white),
            ),
            onTap: () => _runSelectedSsdt(prebuilt: false),
          ),
          const SizedBox(width: 10),
          InkWellWidget.common(
            child: const Text(
              "预制SSDT",
              style: TextStyle(fontSize: 11, color: Colors.white),
            ),
            onTap: () => _runSelectedSsdt(prebuilt: true),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    selectedComboBoxValue.dispose();
    selectedSsdtNotifier.dispose();
    super.dispose();
  }
}
