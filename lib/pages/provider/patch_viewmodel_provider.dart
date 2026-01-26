//  patch_viewmodel_provider.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';
import 'package:rapidssdt/pages/viewmodel/patch_viewmodel.dart';

class PatchViewModelProvider extends InheritedNotifier<PatchViewModel> {
  const PatchViewModelProvider({
    required PatchViewModel patchViewModel,
    required super.child,
    super.key,
  }) : super(notifier: patchViewModel);

  static PatchViewModel of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<PatchViewModelProvider>();
    assert(provider != null, 'PatchViewModelProvider not found in context');
    return provider!.notifier!;
  }
}
