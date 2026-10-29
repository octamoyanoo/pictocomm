import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

final class EmptyCatalogView extends StatelessWidget {
  const EmptyCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Aún no hay pictogramas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando agregues imágenes aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
