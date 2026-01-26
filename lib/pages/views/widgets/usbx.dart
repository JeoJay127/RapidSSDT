//  usbx.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/utils/ssdttool/config.dart';
import 'package:rapidssdt/widgets/checkboxlist/smart_checkbox_list.dart';

class USBXPatchOptions extends StatefulWidget {
  const USBXPatchOptions({super.key, this.onChanged});
  final ValueChanged<Map<String, String>>? onChanged;
  @override
  State<USBXPatchOptions> createState() => _USBXPatchOptionsState();
}

class _USBXPatchOptionsState extends State<USBXPatchOptions> {
  final Map<String, String> _defaultProps = defaultProps;
  final String _split = ": ";

  late Map<String, String> _current = Map.from(_defaultProps);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged?.call(Map.unmodifiable(_current));
    });
  }

  void _toggle(List<String> keys) {
    _current = Map.fromEntries(
      keys.map((key) => MapEntry(key, _defaultProps[key] ?? '')),
    )..removeWhere((key, value) => value.isEmpty);
    widget.onChanged?.call(Map.unmodifiable(_current));
  }

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 40, minWidth: double.infinity),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(6),
    ),
    child: SingleChildScrollView(
      child: SmartCheckBoxList(
        isMultipleSelection: true,
        title: 'USBX 补丁:',
        choices: _defaultProps.entries
            .map((e) => '${e.key}$_split${e.value}')
            .toList(),
        selectedChoices: _current.entries
            .map((e) => '${e.key}$_split${e.value}')
            .toList(),
        onChanged: (value) {
          var keys = value.map((e) => e.split(_split).first).toList();
          _toggle(keys);
        },
      ),
    ),
  );
}
