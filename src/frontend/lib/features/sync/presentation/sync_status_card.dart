import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../sync_service.dart';

/// REQ-BCK-02 (RF-5.19): indicador de estado de sync + botón "Sincronizar
/// ahora". **Solo modo adulto** (pantalla Perfil): el modo chico no ve nada
/// de sync (invisible por diseño).
final class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final l10n = AppLocalizations.of(context)!;
    final (icon, color, label) = _presentation(sync, l10n);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: sync.status == SyncStatus.syncing ? null : () => sync.syncNow(),
              icon: const Icon(Icons.sync, size: 18, color: AppColors.accent),
              label: Text(l10n.syncNowButton, style: const TextStyle(color: AppColors.accent)),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _presentation(SyncService sync, AppLocalizations l10n) {
    return switch (sync.status) {
      SyncStatus.idle => (Icons.cloud_sync_outlined, AppColors.textMuted, l10n.syncStatusIdle),
      SyncStatus.syncing => (Icons.sync, AppColors.accent, l10n.syncStatusSyncing),
      SyncStatus.synced => (Icons.cloud_done_outlined, const Color(0xFF4CAF50), l10n.syncStatusSynced),
      SyncStatus.pending => (
        Icons.cloud_upload_outlined,
        AppColors.warning,
        l10n.syncStatusPending(sync.pendingCount),
      ),
      SyncStatus.offline => (Icons.cloud_off_outlined, AppColors.error, l10n.syncStatusOffline),
    };
  }
}
