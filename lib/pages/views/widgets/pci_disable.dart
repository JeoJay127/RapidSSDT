//  pci_disable.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/pages/views/widgets/path_textfield.dart';
import 'package:rapidssdt/widgets/radio_option_group.dart';

class PciDisable extends StatefulWidget {
  const PciDisable({super.key, this.onChanged});
  final ValueChanged<(String, String, String)>? onChanged;
  @override
  State<PciDisable> createState() => _PciDisableState();
}

class _PciDisableState extends State<PciDisable> {
  String acpiPath = '\\_SB.PCI0.PEG0.PEGP';
  String selectedDisableMethod = 'OFF';
  String pciType = 'GPU';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  void _notifyChange() {
    widget.onChanged?.call((acpiPath, selectedDisableMethod, pciType));
  }

  @override
  Widget build(BuildContext context) {
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
          spacing: 5,
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
                    initialPath: acpiPath,
                    onChanged: (value, _) {
                      acpiPath = value;
                      _notifyChange();
                    },
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 2,
              children: [
                const Text(
                  '禁用方式:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: RadioOptionGroup(
                      direction: RadioGroupDirection.row,
                      horizontalSpacing: 0,
                      groupValue: selectedDisableMethod,
                      onChanged: (val) {
                        selectedDisableMethod = val;
                        _notifyChange();
                      },
                      options: const [
                        RadioOptionData(value: 'OFF', label: 'OFF方法'),
                        RadioOptionData(value: 'PS3', label: 'PS3方法'),
                        RadioOptionData(value: 'IOName', label: 'IOName方法')
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 2,
              children: [
                const Text(
                  '设备类型:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: RadioOptionGroup(
                      direction: RadioGroupDirection.row,
                      horizontalSpacing: 0,
                      groupValue: pciType,
                      onChanged: (val) {
                        pciType = val;
                        _notifyChange();
                      },
                      options: const [
                        RadioOptionData(value: 'GPU', label: 'GPU显卡'),
                        RadioOptionData(value: 'NVMe', label: 'NVMe固态硬盘'),
                        RadioOptionData(value: 'PCIe', label: '其他PCIe'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
