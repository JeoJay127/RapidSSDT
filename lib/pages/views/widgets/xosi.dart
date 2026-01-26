//  xosi.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/utils/ssdttool/config.dart';
import 'package:rapidssdt/widgets/custom_dropdown_button.dart';

class XOSIPatchOptions extends StatefulWidget {
  const XOSIPatchOptions({super.key, this.onChanged});
  final ValueChanged<String?>? onChanged;

  @override
  State<XOSIPatchOptions> createState() => _XOSIPatchOptionsState();
}

class _XOSIPatchOptionsState extends State<XOSIPatchOptions> {
  String? targetString;
  final String placeholder = '选择XOSI的目标系统';
  String? selectedOSIValue;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged?.call(selectedOSIValue);
    });
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
            const Text('不选择则会根据DSDT自动探测OSID版本', style: TextStyle(fontSize: 11)),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                const Text(
                  'OSID选择:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: CustomDropdownButton(
                      value: selectedOSIValue,
                      placeholder: placeholder,
                      options: osiStrings.keys.toList().reversed.map((key) {
                        final label = '$key  (${osiStrings[key]})';
                        return DropdownOption(value: key, label: label);
                      }).toList(),
                      onChanged: (val) {
                        selectedOSIValue = val;
                        widget.onChanged?.call(val);
                      },
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
