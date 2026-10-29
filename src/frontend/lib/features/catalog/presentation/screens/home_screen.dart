import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/empty_catalog_view.dart';
import '../widgets/loading_catalog_view.dart';
import '../providers/catalog_provider.dart';

final class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogProvider>().state;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hola 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.surface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Mis Catálogos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: switch (state) {
                  CatalogLoadingState() => const LoadingCatalogView(),
                  CatalogLoadedState() when state.isEmpty => const EmptyCatalogView(),
                  CatalogLoadedState() => const SizedBox.shrink(),
                  CatalogFailureState() => const EmptyCatalogView(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
