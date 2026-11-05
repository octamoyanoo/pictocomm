import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';

final class EmptyCatalogView extends StatelessWidget {
  const EmptyCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.image_outlined, color: AppColors.accent, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.emptyCatalogTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyCatalogSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
