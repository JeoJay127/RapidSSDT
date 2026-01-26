//  imei.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/widgets/checkboxlist/smart_checkbox_list.dart';

class IMEIPatchOptions extends StatefulWidget {
  const IMEIPatchOptions({super.key, this.onChanged});
  final ValueChanged<String?>? onChanged;

  @override
  State<IMEIPatchOptions> createState() => _IMEIPatchOptionsState();
}

class _IMEIPatchOptionsState extends State<IMEIPatchOptions> {
  // 原始IMEI映射（key: 描述, value: 代码）
  static const Map<String, String> _imeiMap = {
    "搭配 7 系列芯片组的 Sandy Bridge CPU": "3A1C",
    "搭配 6 系列芯片组的 Ivy Bridge CPU": "3A1E",
    "需要使用 DeviceProperties 设置device-id": "",
  };

  // 生成标题到IMEI值的映射
  late final Map<String, String> _titleToValue;
  String? _selectedIMEI;

  @override
  void initState() {
    super.initState();
    _titleToValue = {
      for (final entry in _imeiMap.entries)
        _getTitle(entry.key, entry.value): entry.value,
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged?.call(_selectedIMEI);
    });
  }

  String _getTitle(String key, String value) {
    if (value.isEmpty) {
      return '未启用仿冒IMEI, $key';
    }
    return '启用仿冒IMEI: $value, 适用于$key';
  }

  @override
  Widget build(BuildContext context) {
    final List<String> selectedTitles = _selectedIMEI != null
        ? _titleToValue.entries
              .where((entry) => entry.value == _selectedIMEI)
              .map((entry) => entry.key)
              .toList()
        : [];

    return Container(
      constraints: const BoxConstraints(
        minHeight: 60,
        minWidth: double.infinity,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmartCheckBoxList(
              title: 'IMEI 补丁:',
              choices: _titleToValue.keys.toList(),
              selectedChoices: selectedTitles,
              isMultipleSelection: false,
              onChanged: (List<String> selectedTitles) {
                if (selectedTitles.isEmpty) {
                  _selectedIMEI = null;
                } else {
                  _selectedIMEI = _titleToValue[selectedTitles.first];
                }
                widget.onChanged?.call(_selectedIMEI);
              },
            ),
          ],
        ),
      ),
    );
  }
}
