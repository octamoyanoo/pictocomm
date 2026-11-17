import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/picto_model.dart';

/// Cola de salida (outbox) de la subida bidireccional (REQ-BCK-02, RF-5.17).
///
/// Cada cambio de catálogo custom que la app manda al backend entra acá
/// hasta que el server lo confirma. Persistente en SharedPreferences con
/// claves propias (`pictocomm.outbox_*`), separadas del cache de descarga:
/// si el backend no está, la cola espera y se reintenta al arrancar o tras
/// cada operación nueva.
///
/// Dedup por (kind, id): si el mismo item vuelve a cambiar mientras está
/// pendiente, la entrada se reemplaza por la más nueva (siempre viaja la
/// última versión, last-write-wins en el server, RNF-5.10).
final class RemoteOutboxDataSource {
  const RemoteOutboxDataSource();

  static const String _opsKey = 'pictocomm.outbox_ops';

  static const String kindPicto = 'picto';
  static const String kindCategory = 'category';

  static const String opPost = 'post';
  static const String opPut = 'put';
  static const String opDelete = 'delete';

  /// Encola (o reemplaza) la operación pendiente de un item.
  Future<void> enqueue({
    required String kind,
    required String op,
    required String id,
    PictoModel? picto,
    CategoryModel? category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ops = _decode(prefs.getString(_opsKey));
    final payload = switch (kind) {
      kindPicto => picto?.toJson(),
      kindCategory => category?.toJson(),
      _ => null,
    };
    if ((op == opPost || op == opPut) && payload == null) {
      throw ArgumentError('payload faltante para $op de kind "$kind"');
    }
    final record = <String, dynamic>{
      'kind': kind,
      'op': op,
      'id': id,
      ?(payload != null ? 'payload' : null): payload,
    };
    final remaining = ops.where((existing) => existing['kind'] != kind || existing['id'] != id).toList()
      ..add(record);
    await prefs.setString(_opsKey, jsonEncode(remaining));
  }

  /// Operaciones pendientes, en orden de encolado (FIFO para el flush).
  Future<List<OutboxOperation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final record in _decode(prefs.getString(_opsKey)))
        OutboxOperation(
          kind: record['kind'] as String,
          op: record['op'] as String,
          id: record['id'] as String,
          picto: record['kind'] == kindPicto && record['payload'] is Map<String, dynamic>
              ? PictoModel.fromJson(record['payload'] as Map<String, dynamic>)
              : null,
          category: record['kind'] == kindCategory && record['payload'] is Map<String, dynamic>
              ? CategoryModel.fromJson(record['payload'] as Map<String, dynamic>)
              : null,        ),
    ];
  }

  /// Quita la operación de un item (flush exitoso o adoptado). Matchea
  /// también la [op]: si el item ya cambió de operación mientras el flush
  /// volaba (post → delete), la versión nueva NO se toca.
  Future<void> remove({required String kind, required String op, required String id}) async {
    final prefs = await SharedPreferences.getInstance();
    final ops = _decode(prefs.getString(_opsKey));
    final remaining = ops
        .where((existing) => existing['kind'] != kind || existing['id'] != id || existing['op'] != op)
        .toList();
    await prefs.setString(_opsKey, jsonEncode(remaining));
  }

  Future<int> count() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_opsKey)).length;
  }

  static List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [for (final item in list) item as Map<String, dynamic>];
    } on FormatException {
      // Outbox corrupto: se pierde la cola (sube en el próximo cambio), pero
      // la app sigue funcionando igual que con el cache corrupto.
      return <Map<String, dynamic>>[];
    }
  }
}

/// Una operación pendiente de subida, en memoria.
final class OutboxOperation {
  const OutboxOperation({
    required this.kind,
    required this.op,
    required this.id,
    this.picto,
    this.category,
  });

  final String kind;
  final String op;
  final String id;
  final PictoModel? picto;
  final CategoryModel? category;
}
