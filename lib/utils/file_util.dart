//  file_util.dart
//  Created by JeoJay127
//
import 'package:file_picker/file_picker.dart';

class FileUtils {
  //打开目录
  static Future<String> openFileExplorer(String path) async =>
      await FilePicker.platform.getDirectoryPath(
        lockParentWindow: true,
        initialDirectory: path,
      ) ??
      '';

  //打开文件
  static Future<String> openFile(
    String initialDirectory, {
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: allowMultiple,
      allowedExtensions: allowedExtensions,
      initialDirectory: initialDirectory,
    );

    if (result != null && result.files.isNotEmpty) {
      final selectedPath = result.files.first.path ?? '';
      // 返回第一个符合条件的文件路径
      return selectedPath;
    }

    return '';
  }
}
