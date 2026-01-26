//  tip_switch.dart 
//  Created by JeoJay127 
//


import 'package:flutter/material.dart';
import 'package:rapidssdt/widgets/toggle.dart';

class TipSwitch extends StatefulWidget {
  const TipSwitch(
      {super.key, this.checked = false, this.title, this.tip, this.onChanged});
  final bool checked;
  final String? title;
  final String? tip;
  final ValueChanged? onChanged;

  @override
  State<TipSwitch> createState() => _TipSwitchState();
}

class _TipSwitchState extends State<TipSwitch> {
  late bool checked = widget.checked;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tip ?? '',
      child: ToggleSwitch(
        value: checked,
        text: widget.title,
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).unselectedWidgetColor.withAlpha(60),
        onChanged: (v) {
          setState(() => checked = v);
          widget.onChanged?.call(v);
        },
      ),
    );
  }
}
