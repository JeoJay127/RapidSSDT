//  radio_option_item.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';

class RadioOptionItem extends StatelessWidget {
  final String value;
  final String label;
  final double radioScale;
  final ValueChanged<String> onChanged;

  const RadioOptionItem({
    super.key,
    required this.value,
    required this.label,
    this.radioScale = 1.0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.only(left: 3, right: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: radioScale,
              child: Radio<String>(
                value: value,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
