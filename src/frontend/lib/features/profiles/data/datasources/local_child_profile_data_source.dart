import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile_model.dart';

/// Almacén local de perfiles de niños (RF2.9): SharedPreferences como JSON.
/// Local-first puro: no hay remoto en perfiles todavía.
final class LocalChildProfileDataSource {
  const LocalChildProfileDataSource();

  static const String _childrenKey = 'pictocomm.children_profiles';

  /// REQ-PER-01: sin cuenta logueada (legacy o gestión) la preselección
  /// vive en su propia clave, siguiendo el patrón `pictocomm.*`.
  static const String _lastChildLegacyKey = 'pictocomm.last_child_legacy';

  /// REQ-PER-01: la preselección es POR CUENTA (`pictocomm.last_child_<id>`),
  /// así entrar con otra cuenta no hereda el chico marcado de la anterior.
  static String _lastChildKey(String? accountId) =>
      accountId == null ? _lastChildLegacyKey : 'pictocomm.last_child_$accountId';

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

  /// REQ-PER-01: lee el último chico activo de la cuenta (null si no hay).
  Future<String?> loadLastChildId({String? accountId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastChildKey(accountId));
  }

  /// REQ-PER-01: guarda (o limpia, con `null`) el último chico activo.
  Future<void> saveLastChildId(String? childId, {String? accountId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _lastChildKey(accountId);
    if (childId == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, childId);
    }
  }
}
