//  pci_bridge.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/pages/views/widgets/path_textfield.dart';
import 'package:rapidssdt/widgets/copyable_text.dart';
import 'package:rapidssdt/widgets/inkwell_widget.dart';

class PCIBridgePatchOptions extends StatefulWidget {
  const PCIBridgePatchOptions({super.key, required this.onChanged});
  final ValueChanged<Set<String>> onChanged;

  @override
  State<PCIBridgePatchOptions> createState() => _PCIBridgePatchOptionsState();
}

class _PCIBridgePatchOptionsState extends State<PCIBridgePatchOptions> {
  String? pciBridge;
  Set<String> pciBridges = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(pciBridges);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 60, minWidth: double.infinity),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text(
              '符合要求的设备路径应具有以下格式之一:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            CopyableText(
              title: 'macOS:',
              text: 'PciRoot(0x0)/Pci(0x0,0x0)/Pci(0x0,0x0)',
              titleStyle: TextStyle(fontSize: 10),
              style: TextStyle(fontSize: 10),
            ),
            CopyableText(
              title: 'Windows:',
              text: 'PCIROOT(0)#PCI(0000)#PCI(0000)',
              titleStyle: TextStyle(fontSize: 10),
              style: TextStyle(fontSize: 10),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 15,
              children: [
                const Text(
                  'PCI桥接路径:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Flexible(
                  child: IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 120, 
                        maxWidth: 600,
                      ),
                      child: PathTextField(
                        pathType: PathType.pci,
                        initialPath: pciBridge,
                        hintText: '填写PCI路径',
                        onChanged: (value, _) {
                          pciBridge = value;
                        },
                      ),
                    ),
                  ),
                ),
                InkWellWidget.common(
                  width: 44,
                  height: 24,
                  onTap: () {
                    setState(() {
                      if (pciBridge != null && pciBridge!.isNotEmpty) {
                        pciBridges.add(pciBridge!);
                        widget.onChanged(pciBridges);
                      }
                    });
                  },
                  child: Text(
                    '添加',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
            Text('已添加PCI列表:', style: TextStyle(fontSize: 11)),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...pciBridges.map((bridge) {
                  return Chip(
                    label: Text(bridge, style: TextStyle(fontSize: 11)),
                    deleteButtonTooltipMessage: '删除',
                    onDeleted: () {
                      setState(() {
                        pciBridges.remove(bridge);
                        widget.onChanged(pciBridges);
                      });
                    },
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
