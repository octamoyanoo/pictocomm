import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

final class LoadingCatalogView extends StatelessWidget {
  const LoadingCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accent),
    );
  }
}
