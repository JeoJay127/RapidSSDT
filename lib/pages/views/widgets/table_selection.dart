//  table_selection.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/widgets/choose_file.dart';

class TableSelectionWidget extends StatelessWidget {
  const TableSelectionWidget({
    super.key,
    required this.buttonText,
    required this.hintText,
    this.initialPath,
    this.onChanged,
    this.allowedExtensions = const ['aml', 'dat'],
  });

  final String buttonText;
  final String hintText;
  final String? initialPath;
  final ValueChanged<String?>? onChanged;
  final List<String> allowedExtensions;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 60,
        minWidth: double.infinity,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChooseFileWidget(
              onChanged: (selectedPath) => onChanged?.call(selectedPath),
              initialPath: initialPath,
              hintText: hintText,
              buttons: [
                ChooseFileButton(
                  text: buttonText,
                  mode: OpenMode.file,
                  allowedExtensions: allowedExtensions,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
