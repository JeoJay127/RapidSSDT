//  smart_checkbox_list.dart 
//  Created by JeoJay127 
//
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rapidssdt/widgets/checkboxlist/checkbox_title.dart';

class SmartCheckBoxList extends StatefulWidget {
  final List<String> choices;
  final List<String> selectedChoices;
  final bool isMultipleSelection;
  final bool allowToggle;
  final String title;
  final String subTitle;
  final Widget header;
  final Widget footer;
  final double width;
  final List<String> tiplist;
  final bool showTip;
  final bool initiallyExpanded;
  final String? expandTitle;
  final bool alwaysShowTitle;
  final bool showBorder;
  final double titleFontSize;
  final double subTitleSize;
  final ValueChanged<List<String>>? onChanged;

  const SmartCheckBoxList({
    super.key,
    required this.choices,
    this.onChanged,
    this.selectedChoices = const [],
    this.isMultipleSelection = false,
    this.allowToggle = true,
    this.showBorder = false,
    this.title = '',
    this.subTitle = '',
    this.titleFontSize = 13,
    this.subTitleSize = 11,
    this.header = const SizedBox.shrink(),
    this.footer = const SizedBox.shrink(),
    this.width = double.infinity,
    this.tiplist = const [],
    this.showTip = false,
    this.initiallyExpanded = false,
    this.alwaysShowTitle = true,
    this.expandTitle,
  });

  @override
  State createState() => _SmartCheckBoxListState();
}

class _SmartCheckBoxListState extends State<SmartCheckBoxList> {
  late List<String> _selectedChoices;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedChoices = List.from(widget.selectedChoices);
  }

  @override
  void didUpdateWidget(covariant SmartCheckBoxList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.selectedChoices, oldWidget.selectedChoices)) {
      _selectedChoices = List.from(widget.selectedChoices);
    }
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
    if (!listEquals(widget.choices, oldWidget.choices)) {
      _selectedChoices.retainWhere((choice) => widget.choices.contains(choice));
    }
  }

  bool get _isAllSelected => _selectedChoices.length == widget.choices.length;
  bool get _isNoneSelected => _selectedChoices.isEmpty;

  void _toggleAllSelection() {
    setState(() {
      if (_isAllSelected) {
        _selectedChoices.clear();
      } else {
        _selectedChoices.addAll(
          widget.choices.where((choice) => !_selectedChoices.contains(choice)),
        );
      }
      widget.onChanged?.call(_selectedChoices);
    });
  }

  void _handleChipSelection(String choice, bool isSelected) {
    setState(() {
      if (widget.isMultipleSelection) {
        if (isSelected) {
          _selectedChoices.add(choice);
        } else {
          _selectedChoices.remove(choice);
        }
      } else {
        if (!widget.allowToggle && _selectedChoices.contains(choice)) {
          return;
        }
        _selectedChoices = isSelected ? [choice] : [];
      }
      widget.onChanged?.call(_selectedChoices);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subWidgets = widget.choices.asMap().entries.map((entry) {
      final index = entry.key;
      final choice = entry.value;
      final isSelected = _selectedChoices.contains(choice);

      return Padding(
        padding: const EdgeInsets.all(0.0),
        child: CheckboxTile(
          label: choice,
          selected: isSelected,
          showBorder: widget.showBorder,
          onChanged: (value) => _handleChipSelection(choice, value),
          tooltip: widget.showTip && widget.tiplist.isNotEmpty
              ? widget.tiplist[index]
              : "",
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.header,
        if (widget.title.isNotEmpty || widget.subTitle.isNotEmpty)
          _buildTitle(),
        if (widget.expandTitle != null && widget.expandTitle!.isNotEmpty)
          _buildExpandableContent(subWidgets)
        else
          Wrap(children: subWidgets),
        widget.footer,
      ],
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: widget.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.subTitle.isNotEmpty) const SizedBox(width: 5),
          if (widget.subTitle.isNotEmpty)
            Text(
              widget.subTitle,
              style: TextStyle(
                fontSize: widget.subTitleSize,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableContent(List<Widget> subWidgets) {
    final expansionContent = Wrap(children: subWidgets);

    return widget.alwaysShowTitle
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildExpandableTitle(), expansionContent],
          )
        : ExpansionTile(
            dense: true,
            childrenPadding: EdgeInsets.zero,
            collapsedBackgroundColor: Colors.black.withAlpha(
              (255.0 * 0.08).round(),
            ),
            initiallyExpanded: widget.initiallyExpanded,
            title: _buildExpandableTitle(),
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            children: _isExpanded ? [expansionContent] : [],
          );
  }

  Widget _buildExpandableTitle() {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final textColor = _isAllSelected
        ? selectedColor
        : Theme.of(context).textTheme.bodyLarge!.color;
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              tristate: true,
              checkColor: Colors.white,
              value: _isAllSelected
                  ? true
                  : _isNoneSelected
                  ? false
                  : null,
              onChanged: (value) => _toggleAllSelection(),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                widget.expandTitle!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () => _toggleAllSelection(),
    );
  }
}
