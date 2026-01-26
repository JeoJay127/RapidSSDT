//  ssdt_listview.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/pages/model/ssdt_item.dart';
import 'package:rapidssdt/utils/constant.dart';

class SsdtListView extends StatefulWidget {
  final List<SsdtItem> items;
  final List<SsdtItem>? initialSelectedItems;
  final ValueChanged<List<SsdtItem>>? onSelectionChanged;

  const SsdtListView({
    super.key,
    required this.items,
    this.initialSelectedItems,
    this.onSelectionChanged,
  });

  @override
  State<SsdtListView> createState() => _SsdtListViewState();
}

class _SsdtListViewState extends State<SsdtListView> {
  late Map<String, bool> _selectedMap;

  @override
  void initState() {
    super.initState();
    _initSelectedMap();
  }

  @override
  void didUpdateWidget(covariant SsdtListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialSelectedItems != widget.initialSelectedItems ||
        oldWidget.items != widget.items) {
      _initSelectedMap();
      setState(() {});
    }
  }

  void _initSelectedMap() {
    final preset = widget.initialSelectedItems;

    _selectedMap = {
      for (final it in widget.items)
        it.name:
            it.isBasic ||
            (preset != null && preset.any((e) => e.name == it.name)),
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectionChanged?.call(_getSelectedItems());
    });
  }

  List<SsdtItem> _getSelectedItems() {
    final List<SsdtItem> list = [];
    for (final it in widget.items) {
      final selected = _selectedMap[it.name] ?? it.isBasic;
      if (selected) list.add(it);
    }
    return list;
  }

  void _toggleByName(String name) {
    final itemIndex = widget.items.indexWhere(
      (element) => element.name == name,
    );
    if (itemIndex == -1) return;
    final item = widget.items[itemIndex];
    if (item.isBasic) {
      return;
    }
    setState(() {
      _selectedMap[name] = !(_selectedMap[name] ?? false);
    });
    widget.onSelectionChanged?.call(_getSelectedItems());
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final selected = _selectedMap[item.name] ?? item.isBasic;
    
        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            _toggleByName(item.name);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 10,
                  child: Transform.translate(
                    offset: const Offset(0, 2),
                    child: Text(
                      '*',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18,
                        color: item.isBasic
                            ? Constant.ssdtBasicColor
                            : item.isRecommend
                            ? Constant.ssdtRecommendColor
                            : item.isOptional
                            ? Constant.ssdtOptionalColor
                            : Constant.ssdtDefaultColor,
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: selected,
                    onChanged: (val) {
                      _toggleByName(item.name);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    checkColor: Colors.white,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(item.name, style: const TextStyle(fontSize: 11)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    item.remark,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}