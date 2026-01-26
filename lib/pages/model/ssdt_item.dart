//  ssdt_item.dart
//  Created by JeoJay127
//
class SsdtItem {
  String name;
  String remark;
  String? note;
  dynamic extra;
  bool isBasic;
  bool isRecommend;
  bool isOptional;
  bool? prebuilt;

  SsdtItem({
    required this.name,
    required this.remark,
    this.note,
    this.extra,
    this.isBasic = false,
    this.isRecommend = false,
    this.isOptional = false,
    this.prebuilt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'remark': remark,
    'note': note,
    'extra': extra,
    'isBasic': isBasic,
    'isRecommend': isRecommend,
    'isOptional': isOptional,
    'prebuilt': prebuilt,
  };
}
