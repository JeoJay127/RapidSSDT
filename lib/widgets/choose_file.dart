//  choose_file.dart 
//  Created by JeoJay127 
//
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rapidssdt/utils/file_util.dart';
import 'package:rapidssdt/widgets/inkwell_widget.dart';

enum OpenMode { file, directory }

class ChooseFileButton {
  final String text;
  final OpenMode mode;
  final List<String>? allowedExtensions;
  final bool allowMultiple;
  final Future<bool> Function(String path)? onValid;

  ChooseFileButton({
    required this.text,
    this.mode = OpenMode.directory,
    this.allowedExtensions,
    this.allowMultiple = false,
    this.onValid,
  });
}

class ChooseFileWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? hintText;
  final String? initialPath;
  final bool buttonOnLeft;
  final double? radius;
  final double? buttonWidth;
  final double? buttonHeight;
  final double buttonTextSize;
  final double spacing;
  final List<ChooseFileButton> buttons;

  const ChooseFileWidget({
    super.key,
    required this.onChanged,
    required this.buttons,
    this.buttonOnLeft = true,
    this.initialPath,
    this.hintText = '',
    this.radius,
    this.buttonWidth,
    this.buttonHeight,
    this.buttonTextSize = 11,
    this.spacing = 10,
  });

  @override
  State<ChooseFileWidget> createState() => _ChooseFileWidgetState();
}

class _ChooseFileWidgetState extends State<ChooseFileWidget> {
  late String outputPath;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    outputPath = widget.initialPath ?? '';
    _textController = TextEditingController(text: outputPath);
  }

  @override
  void didUpdateWidget(covariant ChooseFileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPath != oldWidget.initialPath &&
        widget.initialPath != _textController.text) {
      outputPath = widget.initialPath ?? '';
      _textController.text = outputPath;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> onClick(ChooseFileButton btn) async {
    if (kIsWeb) return;

    String selectPath = '';

    switch (btn.mode) {
      case OpenMode.file:
        selectPath = await FileUtils.openFile(
          outputPath,
          allowedExtensions: btn.allowedExtensions,
          allowMultiple: btn.allowMultiple,
        );
        break;
      case OpenMode.directory:
        selectPath = await FileUtils.openFileExplorer(outputPath);
        break;
    }

    if (selectPath.isEmpty) return;

    bool isValid = btn.onValid != null ? await btn.onValid!(selectPath) : true;

    if (isValid) {
      outputPath = selectPath;
      _textController.text = outputPath;
      widget.onChanged(outputPath);
      setState(() {});
    } else {
      _textController.text = '';
      widget.onChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidgets = widget.buttons.map((btn) {
      return InkWellWidget.common(
        height: widget.buttonHeight,
        width: widget.buttonWidth,
        radius: widget.radius,
        onTap: () => onClick(btn),
        child: Text(
          btn.text,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.buttonTextSize,
          ),
        ),
      );
    }).toList();

    return Row(
      spacing: widget.spacing,
      children: [
        if (widget.buttonOnLeft) ...[...buttonWidgets],
        Expanded(
          child: TextField(
            enabled: false,
            controller: _textController,
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: widget.buttonTextSize,
              ),
            ),
          ),
        ),
        if (!widget.buttonOnLeft) ...[...buttonWidgets],
      ],
    );
  }
}
