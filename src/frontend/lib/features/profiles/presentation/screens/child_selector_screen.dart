import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/child_profile.dart';
import '../providers/children_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/child_avatar.dart';

/// Selector de chico (RF2.1): primero sesión activa, después uso.
///
/// Pantalla sin barra: no es una pestaña más de navegación, es un portón.
final class ChildSelectorScreen extends StatefulWidget {
  const ChildSelectorScreen({super.key});

  @override
  State<ChildSelectorScreen> createState() => _ChildSelectorScreenState();
}

final class _ChildSelectorScreenState extends State<ChildSelectorScreen> {
  // El ChildrenProvider llega cargado desde la ruta (_childrenRoute): initState
  // no recarga, para no disparar notifyListeners durante el build del árbol.

  void _selectChild(ChildProfile child) {
    context.read<SessionProvider>().setActiveChild(child);
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChildrenProvider>().state;
    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          ChildrenLoadingState() => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          ChildrenFailureState() => Center(
              child: Text(
                AppLocalizations.of(context)!.selectorLoadError(state.message),
                textAlign: TextAlign.center,
              ),
            ),
          ChildrenLoadedState() => _SelectorContent(
              children: state.children,
              onSelect: _selectChild,
            ),
        },
      ),
    );
  }
}

final class _SelectorContent extends StatelessWidget {
  const _SelectorContent({required this.children, required this.onSelect});

  final List<ChildProfile> children;
  final ValueChanged<ChildProfile> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Text(
          l10n.selectorTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.selectorSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: children.isEmpty
              ? _EmptyChildrenHint(onCreate: () => Navigator.of(context).pushNamed(AppRoutes.perfil))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return _ChildPickerCard(child: child, onSelect: () => onSelect(child));
                  },
                ),
        ),
      ],
    );
  }
}

final class _ChildPickerCard extends StatelessWidget {
  const _ChildPickerCard({required this.child, required this.onSelect});

  final ChildProfile child;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              ChildAvatar(child: child, radius: 38),
              Text(
                child.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EmptyChildrenHint extends StatelessWidget {
  const _EmptyChildrenHint({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.child_care_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              l10n.selectorEmptyTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.selectorEmptySubtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onCreate, child: Text(l10n.createProfile)),
          ],
        ),
      ),
    );
  }
}
