//  button_segment_widget.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';

class ButtonSegmentWidget extends StatefulWidget {
  const ButtonSegmentWidget({
    super.key,
    required this.labels,
    this.onSelectionChanged,
    this.initialSelection,
  });

  final List<String> labels;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final Set<String>? initialSelection;

  @override
  State<ButtonSegmentWidget> createState() => _ButtonSegmentWidgetState();
}

class _ButtonSegmentWidgetState extends State<ButtonSegmentWidget> {
  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialSelection ?? {widget.labels.first};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeColor = theme.colorScheme.primary;

    final segments = widget.labels.map((text) {
      final isSelected = selected.contains(text);
      return ButtonSegment<String>(
        value: text,
        label: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.grey[500] : Colors.black),
            fontSize: 11,
          ),
        ),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: segments,
        selected: selected,
        showSelectedIcon: false,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? themeColor
                : Colors.transparent,
          ),
          side: WidgetStateBorderSide.resolveWith(
            (states) => BorderSide(
              color: Colors.grey.withAlpha(
                (255.0 * (isDarkMode ? 0.6 : 0.5)).round(),
              ),
            ),
          ),
        ),
        onSelectionChanged: (newSelection) {
          setState(() => selected = newSelection);
          widget.onSelectionChanged?.call(newSelection);
        },
      ),
    );
  }
}
