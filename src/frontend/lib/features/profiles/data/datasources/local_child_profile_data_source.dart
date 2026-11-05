import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile_model.dart';

/// Almacén local de perfiles de niños (RF2.9): SharedPreferences como JSON.
/// Local-first puro: no hay remoto en perfiles todavía.
final class LocalChildProfileDataSource {
  const LocalChildProfileDataSource();

  static const String _childrenKey = 'pictocomm.children_profiles';

  Future<List<ChildProfileModel>> loadChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_childrenKey);
    if (raw == null || raw.isEmpty) {
      // Lista nueva y modificable: nunca const, el repositorio muta al agregar.
      return <ChildProfileModel>[];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return <ChildProfileModel>[
        for (final item in list) ChildProfileModel.fromJson(item as Map<String, dynamic>),
      ];
    } on FormatException {
      return <ChildProfileModel>[];
    }
  }

  Future<void> saveChildren(List<ChildProfileModel> children) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode([for (final child in children) child.toJson()]);
    await prefs.setString(_childrenKey, encoded);
  }
}
