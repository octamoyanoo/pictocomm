import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../profiles/presentation/providers/session_provider.dart';
import '../../../profiles/presentation/widgets/child_avatar.dart';
import '../../../profiles/domain/entities/child_profile.dart';
import '../../domain/entities/category.dart';
import '../providers/catalog_provider.dart';
import '../widgets/empty_catalog_view.dart';
import '../widgets/loading_catalog_view.dart';

final class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  Future<void> _openAddMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.folder_special_outlined, color: AppColors.accent),
                title: Text(l10n.newCatalog, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.newCatalogSub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                onTap: () => Navigator.of(context).pop(AppRoutes.addCategory),
              ),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.accent),
                title: Text(l10n.newPicto, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.newPictoSub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                onTap: () => Navigator.of(context).pop(AppRoutes.addPicto),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (choice == null || !mounted) {
      return;
    }
    await Navigator.of(context).pushNamed(choice);
    if (mounted) {
      context.read<CatalogProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogProvider>().state;
    final activeChild = context.watch<SessionProvider>().activeChild;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(activeChild: activeChild, onAddTapped: _openAddMenu),
            Expanded(
              child: switch (state) {
                CatalogLoadingState() => const LoadingCatalogView(),
                CatalogLoadedState() when state.isEmpty => const EmptyCatalogView(),
                CatalogLoadedState() => _CatalogContent(state: state, query: _query, onQueryChanged: _onQueryChanged),
                CatalogFailureState() => const EmptyCatalogView(),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.activeChild, required this.onAddTapped});

  final ChildProfile? activeChild;
  final VoidCallback onAddTapped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final child = activeChild;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Saludo ligado a la sesión activa (RF2.2). Sin chico elegido,
          // el saludo genérico de las primeras corridas.
          if (child == null)
            Text(l10n.hola, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
          else
            Row(
              children: [
                ChildAvatar(child: child, radius: 16),
                const SizedBox(width: 10),
                Text(
                  l10n.holaName(child.name),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          Row(
            children: [
              // Salida simple y visible al selector (RF2.3, decisión del usuario).
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.childSelector),
                icon: const Icon(Icons.swap_horiz),
                tooltip: l10n.changeChildTooltip,
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onAddTapped,
                icon: const Icon(Icons.add),
                tooltip: l10n.addMenuTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.surface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _CatalogContent extends StatelessWidget {
  const _CatalogContent({required this.state, required this.query, required this.onQueryChanged});

  final CatalogLoadedState state;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return _CatalogColumn(
        children: [_SearchField(onQueryChanged), const _SectionRow(), _CategoryList(state: state)],
      );
    }
    final results = state.categories.where((c) => c.name.toLowerCase().contains(query)).toList();
    if (results.isEmpty) {
      return _CatalogColumn(
        children: [
          _SearchField(onQueryChanged),
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.noResults(query),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      );
    }
    return _CatalogColumn(
      children: [_SearchField(onQueryChanged), const _SectionRow(), _CategoryList(state: state, categories: results)],
    );
  }
}

final class _CatalogColumn extends StatelessWidget {
  const _CatalogColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

final class _SearchField extends StatelessWidget {
  const _SearchField(this.onQueryChanged);

  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        onChanged: onQueryChanged,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchHint,
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

final class _SectionRow extends StatelessWidget {
  const _SectionRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.myCatalogs, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.pictogramas),
            style: TextButton.styleFrom(textStyle: const TextStyle(fontSize: 13)),
            child: Text(l10n.verTodos),
          ),
        ],
      ),
    );
  }
}

final class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.state, this.categories});

  final CatalogLoadedState state;
  final List<Category>? categories;

  @override
  Widget build(BuildContext context) {
    final items = categories ?? state.categories;
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const cardWidth = 340.0;
          final columns = (constraints.maxWidth / cardWidth).floor().clamp(1, 3);
          if (columns == 1) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _CategoryCard(category: items[index], pictoCount: state.pictoCountOf(items[index].id));
              },
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 340 / 95),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _CategoryCard(category: items[index], pictoCount: state.pictoCountOf(items[index].id));
            },
          );
        },
      ),
    );
  }
}

final class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.pictoCount});

  final Category category;
  final int pictoCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.category, arguments: category),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.color?.withValues(alpha: 0.15) ?? AppColors.accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_categoryIcon(category.name), color: category.color ?? AppColors.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.pictogramaCount(pictoCount),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  static final Map<String, IconData> _iconsByName = <String, IconData>{
    'alimentos': Icons.restaurant,
    'emociones': Icons.sentiment_satisfied,
    'juguetes': Icons.toys,
    'escuela': Icons.school,
  };

  static IconData _categoryIcon(String name) {
    return _iconsByName[name.toLowerCase()] ?? Icons.category;
  }
}
