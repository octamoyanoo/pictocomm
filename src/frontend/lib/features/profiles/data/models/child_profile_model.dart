import 'dart:convert';

/// Modelo para [ChildProfile].
class ChildProfileModel {
  const ChildProfileModel({
    required this.id,
    required this.name,
    required this.color,
    this.avatarPath,
    this.categoryOrder = const <String>[],
  });

  final String id;
  final String name;
  final int color;
  final String? avatarPath;
  final List<String> categoryOrder;

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) =>
      ChildProfileModel(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as int,
        avatarPath: json['avatarPath'] as String?,
        categoryOrder: json['categoryOrder'] is List
            ? (json['categoryOrder'] as List).whereType<String>().toList()
            : const <String>[],
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'color': color,
        if (avatarPath != null) 'avatarPath': avatarPath,
        'categoryOrder': categoryOrder,
      };

  static List<ChildProfileModel> fromJsonList(String source) {
    final List<dynamic> list = json.decode(source) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChildProfileModel.fromJson)
        .toList();
  }
}
