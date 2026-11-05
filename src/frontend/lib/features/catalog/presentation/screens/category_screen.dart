import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../providers/pictos_provider.dart';
import '../widgets/loading_catalog_view.dart';
import '../widgets/picto_card.dart';

final class CategoryScreen extends StatelessWidget {
  const CategoryScreen({required this.category, super.key});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PictosProvider>().state;
    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          PictosLoadingState() || PictosFailureState() => const LoadingCatalogView(),
          PictosLoadedState() => _CategoryContent(state: state, category: category),
        },
      ),
    );
  }
}

final class _CategoryContent extends StatelessWidget {
  const _CategoryContent({required this.state, required this.category});

  final PictosLoadedState state;
  final Category category;

  /// RF3.9: doble confirmación; si el adulto confirma, se borra la
  /// categoría con sus pictos y volvemos al home (que recarga compartido).
  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<PictosProvider>();
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Eliminar "${category.name}"?'),
        content: Text('Se borra el catálogo y su contenido (${state.pictosOf(category.id).length} pictogramas de este niño).'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Seguir')),
        ],
      ),
    );
    if (first != true || !context.mounted) {
      return;
    }
    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Confirmar el borrado?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Conservar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) {
      return;
    }
    try {
      await provider.deleteCategory(category.id);
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pictos = state.pictosOf(category.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryHeader(
          category: category,
          pictoCount: pictos.length,
          onDelete: (context) => _confirmDelete(context),
        ),
        Expanded(
          child: pictos.isEmpty
              ? Center(
                  child: Text(
                    'Todavía no hay pictogramas en esta categoría',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const cardWidth = 96.0;
                    final columns = (constraints.maxWidth / cardWidth).floor().clamp(2, 5);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: pictos.length,
                      itemBuilder: (context, index) {
                        final picto = pictos[index];
                        return PictoCard(
                          picto: picto,
                          onTap: () => _openPicto(context, picto),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openPicto(BuildContext context, Picto picto) {
    Navigator.of(context).pushNamed(AppRoutes.picto, arguments: picto);
  }
}

final class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category, required this.pictoCount, required this.onDelete});

  final Category category;
  final int pictoCount;
  final Future<void> Function(BuildContext) onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  pictoCount == 1 ? '1 pictograma' : '$pictoCount pictogramas',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // RF3.9: solo las categorías creadas por el adulto son borrables.
          if (category.custom)
            IconButton(
              onPressed: () => onDelete(context),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Eliminar catálogo',
            ),
        ],
      ),
    );
  }
}
