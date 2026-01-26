//  radio_option_group.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/widgets/radio_option_item.dart';

enum RadioGroupDirection { row, column, wrap }

class RadioOptionGroup extends StatelessWidget {
  final List<RadioOptionData> options;
  final String groupValue;
  final ValueChanged<String> onChanged;

  final RadioGroupDirection direction;
  final double horizontalSpacing;
  final double verticalSpacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  final WrapAlignment wrapAlignment;
  final WrapCrossAlignment wrapCrossAlignment;
  final WrapAlignment wrapRunAlignment;
  final double radioScale;

  const RadioOptionGroup({
    super.key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
    this.direction = RadioGroupDirection.row,
    this.horizontalSpacing = 8.0,
    this.verticalSpacing = 6.0,
    this.radioScale = 0.8,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapAlignment = WrapAlignment.start,
    this.wrapCrossAlignment = WrapCrossAlignment.center,
    this.wrapRunAlignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    final children = options.map((option) {
      return RadioOptionItem(
        radioScale: radioScale,
        value: option.value,
        label: option.label,
        onChanged: onChanged,
      );
    }).toList();

    switch (direction) {
      case RadioGroupDirection.column:
        return Column(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: mainAxisAlignment,
          children: _addSpacing(children, verticalSpacing, Axis.vertical),
        );
      case RadioGroupDirection.row:
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: mainAxisAlignment,
          children: _addSpacing(children, horizontalSpacing, Axis.horizontal),
        );
      case RadioGroupDirection.wrap:
        return Wrap(
          spacing: horizontalSpacing,
          runSpacing: verticalSpacing,
          alignment: wrapAlignment,
          crossAxisAlignment: wrapCrossAlignment,
          runAlignment: wrapRunAlignment,
          children: children,
        );
    }
  }

  List<Widget> _addSpacing(List<Widget> items, double spacing, Axis axis) {
    if (items.isEmpty) return [];
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(
          SizedBox(
            width: axis == Axis.horizontal ? spacing : 0,
            height: axis == Axis.vertical ? spacing : 0,
          ),
        );
      }
    }
    return result;
  }
}

class RadioOptionData {
  final String value;
  final String label;

  const RadioOptionData({required this.value, required this.label});
}
