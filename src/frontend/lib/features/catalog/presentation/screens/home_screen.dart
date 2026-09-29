import 'package:flutter/material.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/category.dart';
import '../providers/catalog_provider.dart';
import '../widgets/category_card.dart';

/// Pantalla principal: grid de categorías.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CatalogProvider provider = context.catalogWatch;
    final List<Category> categories = provider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PictoComm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            iconSize: 28,
            tooltip: 'Ajustes',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (BuildContext context) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null) {
              return _ErrorView(
                message: provider.error!.message,
                onRetry: () {
                  final CatalogProvider p = context.catalog..clearError();
                  p.loadCategories();
                },
              );
            }
            if (categories.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Todavía no hay categorías. Agregá imágenes en '
                    'assets/images/ y declaralas en pubspec.yaml.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(AppTheme.pagePadding),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: AppTheme.gridSpacing,
                crossAxisSpacing: AppTheme.gridSpacing,
                childAspectRatio: 1.15,
              ),
              itemCount: categories.length,
              itemBuilder: (BuildContext context, int index) {
                final Category category = categories[index];
                return CategoryCard(
                  category: category,
                  onTap: () => _openCategory(context, category),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, Category category) {
    context.catalog.selectCategory(category);
    Navigator.of(context).pushNamed(AppRoutes.category);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
