import 'dart:async';

import 'package:flutter/foundation.dart';

import '../catalog/data/repositories/local_picto_repository.dart';

/// REQ-BCK-02 (RF-5.19): estado observable del sync bidireccional.
///
/// Es un `ChangeNotifier` a propósito: la UI de modo adulto (pantalla
/// Perfil) lo observa directo y el botón "Sincronizar ahora" llama a
/// [syncNow]. El modo chico no lo ve (invisible por diseño).
///
/// Estados:
/// - [SyncStatus.idle]: todavía no corrió ningún sync (arranque en curso).
/// - [SyncStatus.syncing]: descarga o flush en curso.
/// - [SyncStatus.synced]: todo subido y descargado.
/// - [SyncStatus.pending]: hay N cambios en el outbox esperando el backend.
/// - [SyncStatus.offline]: el último intento no pudo conectar (igual que
///   siempre, silencioso: la app funciona con lo local).
final class SyncService extends ChangeNotifier {
  SyncService({this.catalogRepository});

  /// Repositorio concreto (con outbox y sync). `null` solo en tests que
  /// inyectan fakes sin backend.
  final LocalPictoRepository? catalogRepository;

  SyncStatus _status = SyncStatus.idle;

  int _pendingCount = 0;

  SyncStatus get status => _status;

  /// Cambios pendientes de subida (RF-5.19: "pendiente (N)").
  int get pendingCount => _pendingCount;

  /// Disparado por el repositorio cada vez que se encola un cambio: el
  /// contador refresca sin esperar el próximo sync.
  void markDirty() {
    refresh();
  }

  /// Refresca el contador de pendientes sin tocar el backend.
  Future<void> refresh() async {
    final repository = catalogRepository;
    if (repository == null) {
      return;
    }
    final count = await repository.pendingUploadsCount();
    if (count != _pendingCount) {
      _pendingCount = count;
      if (count > 0 && _status != SyncStatus.syncing) {
        _status = SyncStatus.pending;
      }
      notifyListeners();
    }
  }

  /// RF-5.20: descarga + flush ahora, actualizando el indicador. Silencioso
  /// como el sync de arranque: si el backend no está queda [offline] o
  /// [pending], sin errores.
  Future<void> syncNow() async {
    final repository = catalogRepository;
    if (repository == null) {
      return;
    }
    _status = SyncStatus.syncing;
    notifyListeners();
    await repository.syncNow();
    await refresh();
    _pendingCount = await repository.pendingUploadsCount();
    if (_pendingCount > 0) {
      _status = SyncStatus.pending;
    } else if (repository.lastSyncFailed) {
      _status = SyncStatus.offline;
    } else {
      _status = SyncStatus.synced;
    }
    notifyListeners();
  }

  /// Arranque de la app: sync en background (fire-and-forget).
  Future<void> bootstrap() async {
    final repository = catalogRepository;
    if (repository == null) {
      return;
    }
    await refresh();
    unawaited(syncNow());
  }
}

enum SyncStatus { idle, syncing, synced, pending, offline }
