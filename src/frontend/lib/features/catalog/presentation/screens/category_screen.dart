import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';
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

  /// RF3.9 con multi-pertenencia (REQ-CAT-02, RF-3.20): doble confirmación
  /// con el impacto real — cuántos pictos se eliminan (quedan sin ninguna
  /// categoría y son del chico activo) y cuántos solo pierden esta
  /// membresía. Si el adulto confirma, se borra la categoría y volvemos al
  /// home (que recarga compartido).
  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<PictosProvider>();
    final l10n = AppLocalizations.of(context)!;
    final impact = await provider.deletionImpact(category.id);
    if (!context.mounted) {
      return;
    }
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteCategoryTitle(category.nameFor(l10n.localeName))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteCategoryContent(impact.toDelete)),
            if (impact.toKeep > 0) ...[
              const SizedBox(height: 8),
              Text(l10n.deleteCategoryKeepContent(impact.toKeep)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.next)),
        ],
      ),
    );
    if (first != true || !context.mounted) {
      return;
    }
    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.deleteIrreversible),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.keep)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deleteForever),
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
        // REQ-ACC-01: se conserva la ruta raíz (AuthGate) — si el stack se
        // limpia por completo, el logout pierde a dónde volver (RF-6.5).
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => route.isFirst);
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
          onEdit: (context) => _edit(context),
        ),
        Expanded(
          child: pictos.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.categoryEmpty,
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

  /// REQ-CAT-02 (RF-3.17): abre el formulario de categoría en modo edición;
  /// al volver, refresca pictos y conteos.
  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRoutes.addCategory, arguments: category);
    if (context.mounted) {
      await context.read<PictosProvider>().refresh();
    }
  }
}

final class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category, required this.pictoCount, required this.onDelete, required this.onEdit});

  final Category category;
  final int pictoCount;
  final Future<void> Function(BuildContext) onDelete;
  final Future<void> Function(BuildContext) onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  category.nameFor(Localizations.localeOf(context).languageCode),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.pictogramaCount(pictoCount),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // RF3.9: solo las categorías creadas por el adulto son borrables.
          if (category.custom) ...[
            // REQ-CAT-02 (RF-3.17): lápiz de edición (nombre/color).
            IconButton(
              onPressed: () => onEdit(context),
              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
              tooltip: l10n.editCategoryTooltip,
            ),
            IconButton(
              onPressed: () => onDelete(context),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: l10n.deleteCatalogTooltip,
            ),
          ],
        ],
      ),
    );
  }
}
