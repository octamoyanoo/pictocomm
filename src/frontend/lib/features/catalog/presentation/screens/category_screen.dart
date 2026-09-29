import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/category.dart';
import '../../domain/picto.dart';
import '../providers/catalog_provider.dart';
import '../widgets/picto_card.dart';

/// Tablero de pictos de una categoría.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CatalogProvider provider = context.watch<CatalogProvider>();
    final Category? category = provider.selectedCategory;
    final List<Picto> pictos = provider.pictos;

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name ?? ''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 30,
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (BuildContext context) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    provider.error!.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            }
            if (pictos.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Todavía no hay pictos en esta categoría.'),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(AppTheme.pagePadding),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisSpacing: AppTheme.gridSpacing,
                crossAxisSpacing: AppTheme.gridSpacing,
                childAspectRatio: 0.85,
              ),
              itemCount: pictos.length,
              itemBuilder: (BuildContext context, int index) {
                final Picto picto = pictos[index];
                return PictoCard(
                  picto: picto,
                  onTap: () => _onPictoTap(context, provider, picto),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _onPictoTap(
    BuildContext context,
    CatalogProvider provider,
    Picto picto,
  ) {
    provider.onPictoTap(picto);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(picto.label),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 800),
        ),
      );
  }
}
