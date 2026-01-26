//  custom_checkbox_list_tile.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';

class CustomCheckboxListTile extends StatefulWidget {
  // == 控制部分 ==
  final bool value;
  final ValueChanged<bool>? onChanged;

  // == 官方属性完整保留 ==
  final MouseCursor? mouseCursor;
  final Color? activeColor;
  final WidgetStateProperty<Color?>? fillColor;
  final Color? checkColor;
  final Color? hoverColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  final FocusNode? focusNode;
  final bool autofocus;
  final OutlinedBorder? shape;
  final BorderSide? side;
  final bool isError;
  final bool? enabled;
  final Color? tileColor;
  final Widget? title;
  final Widget? subtitle;
  final bool isThreeLine;
  final bool? dense;
  final Widget? secondary;
  final ListTileControlAffinity? controlAffinity;
  final EdgeInsetsGeometry? contentPadding;
  final bool tristate;
  final bool selected;
  final OutlinedBorder? checkboxShape;
  final Color? selectedTileColor;
  final ValueChanged<bool>? onFocusChange;
  final bool? enableFeedback;
  final String? checkboxSemanticLabel;
  final double checkboxScaleFactor;

  // == 自定义扩展样式 ==
  final double borderRadius;
  final Color? selectedBackgroundColor;
  final Color? selectedTitleTextColor;
  final Color? selectedSubtitleTextColor;

  const CustomCheckboxListTile(
      {super.key,
      this.value = false,
      this.onChanged,
      this.mouseCursor,
      this.activeColor,
      this.fillColor,
      this.checkColor,
      this.hoverColor,
      this.overlayColor,
      this.splashRadius,
      this.materialTapTargetSize,
      this.visualDensity,
      this.focusNode,
      this.autofocus = false,
      this.shape,
      this.side,
      this.isError = false,
      this.enabled,
      this.tileColor,
      this.title,
      this.subtitle,
      this.isThreeLine = false,
      this.dense,
      this.secondary,
      this.controlAffinity = ListTileControlAffinity.leading,
      this.contentPadding,
      this.tristate = false,
      this.selected = false,
      this.checkboxShape,
      this.selectedTileColor,
      this.onFocusChange,
      this.enableFeedback,
      this.checkboxSemanticLabel,
      this.checkboxScaleFactor = 1.0,
      this.borderRadius = 0.0,
      this.selectedBackgroundColor,
      this.selectedTitleTextColor,
      this.selectedSubtitleTextColor});

  @override
  State<CustomCheckboxListTile> createState() => _CustomCheckboxListTileState();
}

class _CustomCheckboxListTileState extends State<CustomCheckboxListTile> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.value;
  }

  void _handleChanged(bool? value) {
    setState(() {
      isChecked = value ?? false;
    });
    widget.onChanged?.call(isChecked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBackgroundColor =
        widget.selectedBackgroundColor ?? Colors.transparent;
    final selectedTitleTextColor =
        widget.selectedTitleTextColor ?? theme.colorScheme.primary;
    final selectedSubtitleTextColor =
        widget.selectedSubtitleTextColor ?? theme.colorScheme.primary;
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Material(
          color: isChecked ? selectedBackgroundColor : Colors.transparent,
          child: CheckboxListTile(
            value: isChecked,
            onChanged: _handleChanged,
            mouseCursor: widget.mouseCursor,
            activeColor: activeColor,
            fillColor: widget.fillColor,
            checkColor: widget.checkColor,
            hoverColor: widget.hoverColor,
            overlayColor: widget.overlayColor,
            splashRadius: widget.splashRadius,
            materialTapTargetSize: widget.materialTapTargetSize,
            visualDensity: widget.visualDensity,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            shape: widget.shape,
            side: widget.side,
            isError: widget.isError,
            enabled: widget.enabled,
            tileColor: widget.tileColor,
            selectedTileColor: widget.selectedTileColor,
            title: isChecked && widget.title != null
                ? DefaultTextStyle.merge(
                    style: TextStyle(color: selectedTitleTextColor),
                    child: widget.title!,
                  )
                : widget.title,
            subtitle: isChecked && widget.subtitle != null
                ? DefaultTextStyle.merge(
                    style: TextStyle(color: selectedSubtitleTextColor),
                    child: widget.subtitle!,
                  )
                : widget.subtitle,
            isThreeLine: widget.isThreeLine,
            dense: widget.dense,
            secondary: widget.secondary,
            selected: widget.selected,
            controlAffinity: widget.controlAffinity,
            contentPadding: widget.contentPadding,
            tristate: widget.tristate,
            checkboxShape: widget.checkboxShape,
            onFocusChange: widget.onFocusChange,
            enableFeedback: widget.enableFeedback,
            checkboxSemanticLabel: widget.checkboxSemanticLabel,
            checkboxScaleFactor: widget.checkboxScaleFactor,
          )),
    );
  }
}
