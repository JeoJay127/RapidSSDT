//  string_extension.dart 
//  Created by JeoJay127 
//
extension StringExtension on String? {
  String get nullSafe => this ?? '';

  bool containsAny(List<String> list) {
    if (list.isEmpty) return false;
    return list.any((item) => nullSafe.contains(item));
  }
}
