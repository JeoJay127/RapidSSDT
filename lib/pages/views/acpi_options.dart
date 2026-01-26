//  acpi_options.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/utils/ssdttool/config.dart';
import 'package:rapidssdt/widgets/radio_option_group.dart';

class OptionItem<T> {
  final T value;
  final String label;
  const OptionItem(this.value, this.label);
}

const acpiOptions = [OptionItem(true, '内置'), OptionItem(false, '远程')];

const legacyIaslOptions = [
  OptionItem(false, '新版iasl'),
  OptionItem(true, '旧版iasl-legacy'),
];

const dslOptions = [OptionItem(true, '是'), OptionItem(false, '否')];

const forceOptions = [OptionItem(true, '是'), OptionItem(false, '否')];

const overwriteEFIOptions = [OptionItem(true, '是'), OptionItem(false, '否')];

/// ACPI选项组件
class AcpiOptions extends StatefulWidget {
  const AcpiOptions({super.key, required this.config, this.onChanged});

  final AcpiConfig config;
  final ValueChanged<AcpiConfig>? onChanged;

  @override
  State<AcpiOptions> createState() => _AcpiOptionsState();
}

class _AcpiOptionsState extends State<AcpiOptions> {
  late AcpiConfig config;

  @override
  void initState() {
    super.initState();
    config = widget.config;
  }

  void _update(AcpiConfig newConfig) {
    setState(() => config = newConfig);
    widget.onChanged?.call(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          width: double.infinity,
          color: Colors.black.withAlpha((255.0 * 0.7).round()),
          child: Text(
            '偏好设置',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                _buildOptionRow<bool>(
                  label: 'iasl模式',
                  groupValue: config.useLocaliAsl,
                  choices: acpiOptions,
                  onChanged: (val) =>
                      _update(config.copyWith(useLocaliAsl: val)),
                ),
                _buildOptionRow<bool>(
                  label: 'iasl编译类型',
                  groupValue: config.useLeagcyiAsl,
                  choices: legacyIaslOptions,
                  onChanged: (val) =>
                      _update(config.copyWith(useLeagcyiAsl: val)),
                ),
                _buildOptionRow<bool>(
                  label: '删除反编译.dsl文件',
                  groupValue: config.deleteDsl,
                  choices: dslOptions,
                  onChanged: (val) => _update(config.copyWith(deleteDsl: val)),
                ),
                _buildOptionRow<bool>(
                  label: '强制编译',
                  groupValue: config.force,
                  choices: forceOptions,
                  onChanged: (val) => _update(config.copyWith(force: val)),
                ),
                _buildOptionRow<bool>(
                  label: '是否覆盖目标EFI',
                  groupValue: config.overwriteEFI,
                  choices: overwriteEFIOptions,
                  onChanged: (val) =>
                      _update(config.copyWith(overwriteEFI: val)),
                ),
                _buildOptionRow<ACPIMatchMode>(
                  label: 'ACPI匹配模式',
                  groupValue: config.acpiMatchMode,
                  choices: ACPIMatchMode.values
                      .map((m) => OptionItem(m, m.value))
                      .toList(),
                  onChanged: (val) =>
                      _update(config.copyWith(acpiMatchMode: val)),
                  direction: RadioGroupDirection.wrap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionRow<T>({
    required String label,
    required T groupValue,
    required List<OptionItem<T>> choices,
    required ValueChanged<T> onChanged,
    RadioGroupDirection direction = RadioGroupDirection.row,
  }) {
    final List<Widget> children = [];
    final RadioOptionGroup radioOptionGroup = RadioOptionGroup(
      direction: direction,
      groupValue: choices.firstWhere((o) => o.value == groupValue).label,
      onChanged: (val) {
        final selected = choices.firstWhere((o) => o.label == val);
        onChanged(selected.value);
      },
      options: choices
          .map((e) => RadioOptionData(value: e.label, label: e.label))
          .toList(),
    );
    children.add(Text('$label:', style: const TextStyle(fontSize: 11)));
    children.add(const SizedBox(height: 5));
    children.add(radioOptionGroup);
    Widget child;
    if (direction == RadioGroupDirection.row) {
      child = Row(children: children);
    } else {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }
    return child;
  }
}
