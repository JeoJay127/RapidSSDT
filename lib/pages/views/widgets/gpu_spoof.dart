//  gpu_spoof.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rapidssdt/pages/views/widgets/path_textfield.dart';
import 'package:rapidssdt/utils/dataset/pci_data.dart';
import 'package:rapidssdt/widgets/custom_dropdown_button.dart';
import 'package:rapidssdt/widgets/custom_textfield.dart';

class GpuSpoof extends StatefulWidget {
  const GpuSpoof({super.key, this.onChanged});
  final ValueChanged<(String, String, String)>? onChanged;
  @override
  State<GpuSpoof> createState() => _GpuSpoofState();
}

class _GpuSpoofState extends State<GpuSpoof> {
  late final TextEditingController _controllerFakeID = TextEditingController(
    text: '',
  );
  late final TextEditingController _controllerFakeModel = TextEditingController(
    text: '',
  );
  final FocusNode _focusNodeFakeid = FocusNode();
  final FocusNode _focusNodeFakeModel = FocusNode();
  String acpiPath = '\\_SB.PCI0.PEG0.PEGP';
  final String placeholder = '选择需要仿冒的显卡设备';
  String? selectedComboBoxValue = '选择需要仿冒的显卡设备';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  @override
  void dispose() {
    _controllerFakeID.dispose();
    _controllerFakeModel.dispose();
    _focusNodeFakeid.dispose();
    _focusNodeFakeModel.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged?.call((
      acpiPath,
      _controllerFakeID.text,
      _controllerFakeModel.text,
    ));
  }

  // 构建 ACPI 路径输入框
  Widget _buildAcpiPathInput(bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 15,
      children: [
        const Text(
          '设备ACPI路径:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Flexible(
          child: PathTextField(
            pathType: PathType.acpi,
            initialPath: acpiPath,
            onChanged: (value, _) {
              acpiPath = value;
              _notifyChange();
            },
          ),
        ),
      ],
    );
  }

  // 构建仿冒显卡 ID 数据库下拉框
  Widget _buildFakeIDDatabaseDropdown(bool isDarkMode) {
    final gpuOptions = PciData.gpuInfoMap.keys.toList().reversed.map((
      originalId,
    ) {
      final gpuName = PciData.getGpuNameWithOriginId(originalId) ?? '未知显卡型号';
      final label = '$gpuName  :  [$originalId]';
      return DropdownOption(value: label, label: label);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          const Text(
            '仿冒显卡ID数据库:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          CustomDropdownButton(
            value: selectedComboBoxValue,
            placeholder: placeholder,
            options: gpuOptions,
            onChanged: (selectedValue) {
              selectedComboBoxValue = selectedValue ?? '';

              if (selectedValue != null && selectedValue != placeholder) {
                final parts = selectedValue.split('  :  ');
                if (parts.length == 2) {
                  final originalId = parts[1].trim().replaceAll(
                    RegExp(r'^\[|\]$'),
                    '',
                  );
                  _controllerFakeID.text =
                      PciData.getDevicespoofId(originalId) ?? '';
                  _controllerFakeModel.text =
                      PciData.getGpuNameWithOriginId(originalId) ?? '';
                }
              } else {
                _controllerFakeID.text = '';
                _controllerFakeModel.text = '';
              }

              _notifyChange();
            },
          ),
        ],
      ),
    );
  }

  // 构建仿冒显卡 ID 输入框
  Widget _buildFakeIDInput(bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        const Text(
          ' 仿冒显卡ID:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        CustomTextField(
          controller: _controllerFakeID,
          focusNode: _focusNodeFakeid,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
            LengthLimitingTextInputFormatter(4),
          ],
          hintText: '例如: 73BF',
          errorText: '需要4位十六进制字符',
          validator: (value) {
            return value.length == 4 || value.isEmpty;
          },
          onChanged: (value, _) {
            _notifyChange();
          },
        ),
        Flexible(child: _buildFakeModelInput(isDarkMode)),
      ],
    );
  }

  // 构建仿冒显卡名称输入框
  Widget _buildFakeModelInput(bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        const Text(
          ' 仿冒显卡名称:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Flexible(
          child: CustomTextField(
            controller: _controllerFakeModel,
            focusNode: _focusNodeFakeModel,
            hintText: '选填项,显卡名称',
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\u4e00-\u9fa5]')),
            ],
            onChanged: (value, _) => _notifyChange(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(minHeight: 60, minWidth: double.infinity),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAcpiPathInput(isDarkMode),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFakeIDDatabaseDropdown(isDarkMode),
                _buildFakeIDInput(isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
