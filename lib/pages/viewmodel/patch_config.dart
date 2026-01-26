//  patch_config.dart 
//  Created by JeoJay127 
//
import 'package:flutter/foundation.dart';

class PatchConfig {
  final ValueNotifier<bool> isVisible;
  final ValueNotifier<dynamic> data;

  PatchConfig({bool initialVisible = false, dynamic initialData})
    : isVisible = ValueNotifier(initialVisible),
      data = ValueNotifier(initialData);

  void dispose() {
    isVisible.dispose();
    data.dispose();
  }
}