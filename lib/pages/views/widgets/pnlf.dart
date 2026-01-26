//  pnlf.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rapidssdt/pages/views/widgets/path_textfield.dart';
import 'package:rapidssdt/utils/ssdttool/config.dart';
import 'package:rapidssdt/widgets/custom_dropdown_button.dart';
import 'package:rapidssdt/widgets/custom_textfield.dart';
import 'package:rapidssdt/widgets/tip_switch.dart';

class PNLFPatchOptions extends StatefulWidget {
  const PNLFPatchOptions({super.key, this.onChanged});
  final ValueChanged<(int?, String, bool)>? onChanged;
  @override
  State<PNLFPatchOptions> createState() => _PNLFPatchOptionsState();
}

class _PNLFPatchOptionsState extends State<PNLFPatchOptions> {
  late final TextEditingController _controllerUID = TextEditingController(
    text: '',
  );
  final FocusNode _focusNodeUID = FocusNode();
  final FocusNode dropdownFocusNode = FocusNode();
  int? selectedUID; // 初始 UID 值
  String manualIGPUPath = '';
  bool getIGPU = false; // 是否补充IGPU寄存器信息
  final String placeholder = '为PNLF选择UID';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged?.call((selectedUID, manualIGPUPath, getIGPU));
    });
  }

  @override
  void dispose() {
    _controllerUID.dispose();
    _focusNodeUID.dispose();
    dropdownFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 60, minWidth: double.infinity),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                const Text(
                  '设备ACPI路径:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Flexible(
                  child: PathTextField(
                    pathType: PathType.acpi,
                    initialPath: '',
                    hintText: '当选择UID=14时,建议补充IGPU ACPI路径',
                    onChanged: (value, _) {
                      manualIGPUPath = value;
                      widget.onChanged?.call((selectedUID, value, getIGPU));
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 15,
              children: [
                const Text(
                  'UID类型:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                CustomTextField(
                  controller: _controllerUID,
                  focusNode: _focusNodeUID,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(3),
                  ],
                  hintText: '必填项',
                  errorText: 'UID值无效',
                  validator: (value) {
                    return value.isEmpty ||
                        int.tryParse(value) != null &&
                            int.tryParse(value)! >= 0 &&
                            int.tryParse(value)! <= 999;
                  },
                  onChanged: (value, _) {
                    selectedUID = int.tryParse(value);
                    widget.onChanged?.call((
                      selectedUID,
                      manualIGPUPath,
                      getIGPU,
                    ));
                  },
                ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: CustomDropdownButton(
                      value: _controllerUID.text,
                      placeholder: placeholder,
                      options: PNLFUIDs.map((item) {
                        final uid = item['UID'] as int;
                        final platform = item['Platform'] as String;
                        return DropdownOption(
                          value: uid.toString(),
                          label: 'UID: $uid  |  $platform',
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == placeholder) {
                          _controllerUID.text = '';
                          selectedUID = null;
                        } else {
                          _controllerUID.text = val ?? '';
                          selectedUID = int.tryParse(val ?? '');
                        }
                        widget.onChanged?.call((
                          selectedUID,
                          manualIGPUPath,
                          getIGPU,
                        ));
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            TipSwitch(
              checked: getIGPU,
              title: '是否补充IGPU寄存器信息',
              tip: '当选择UID=14时,建议开启。如果不开启,可能会遇到最大亮度受限或其他问题',
              onChanged: (v) {
                getIGPU = v;
                widget.onChanged?.call((selectedUID, manualIGPUPath, v));
              },
            ),
          ],
        ),
      ),
    );
  }
}
