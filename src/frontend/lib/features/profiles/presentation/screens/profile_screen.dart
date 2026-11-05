import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../domain/entities/child_profile.dart';
import '../providers/children_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/child_avatar.dart';

/// Gestión de perfiles de niño, modo adulto (RF2.5–RF2.8).
final class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

final class _ProfileScreenState extends State<ProfileScreen> {

  Future<void> _addChild() async {
    final newChild = await showDialog<(String, int?)>(
      context: context,
      builder: (_) => const _AddChildDialog(),
    );
    if (newChild == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    await context.read<ChildrenProvider>().createChild(newChild.$1, null, newChild.$2);
  }

  Future<void> _deleteChild(ChildProfile child) async {
    final session = context.read<SessionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDeleteStepOne(child: child),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final reallyConfirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDeleteStepTwo(child: child),
    );
    if (reallyConfirmed != true || !mounted) {
      return;
    }
    await context.read<ChildrenProvider>().deleteChild(child.id);
    session.clearIfDeleted(child.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChildrenProvider>().state;
    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          ChildrenLoadingState() => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          ChildrenFailureState() => Center(child: Text('No se pudo leer los perfiles: ${state.message}')),
          ChildrenLoadedState() => _ProfileContent(children: state.children, onAdd: _addChild, onDelete: _deleteChild),
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

final class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.children, required this.onAdd, required this.onDelete});

  final List<ChildProfile> children;
  final Future<void> Function() onAdd;
  final ValueChanged<ChildProfile> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Perfil', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 20),
        const _CaregiverCard(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Niños', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              tooltip: 'Agregar niño',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.surface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No hay niños cargados todavía',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
        for (final child in children) _ChildTile(child: child, onDelete: () => onDelete(child)),
      ],
    );
  }
}

final class _CaregiverCard extends StatelessWidget {
  const _CaregiverCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.accentLight,
            child: Icon(Icons.face_outlined, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mi cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('casa@pictocomm.app', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('Cerrar sesión', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
        ],
      ),
    );
  }
}

final class _ChildTile extends StatelessWidget {
  const _ChildTile({required this.child, required this.onDelete});

  final ChildProfile child;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          ChildAvatar(child: child),
          const SizedBox(width: 12),
          Expanded(
            child: Text(child.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          // RF2.7: el borrado justo pide doble confirmación en el diálogo.
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Eliminar perfil',
          ),
        ],
      ),
    );
  }
}

/// Crear perfil (RF2.6): nombre + color de avatar de paleta fija.
final class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog();

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

final class _AddChildDialogState extends State<_AddChildDialog> {
  final _nameController = TextEditingController();

  int _selectedIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop((name, AppColors.avatarPalette[_selectedIndex].toARGB32()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar niño'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nombre'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              for (final (index, color) in AppColors.avatarPalette.indexed)
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedIndex == index ? AppColors.textPrimary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: _submit, child: const Text('Agregar')),
      ],
    );
  }
}

/// Paso 1 de la confirmación doble (RF2.7): advertencia con consecuencias.
final class _ConfirmDeleteStepOne extends StatelessWidget {
  const _ConfirmDeleteStepOne({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('¿Eliminar a ${child.name}?'),
      content: const Text('El perfil del niño se borra del dispositivo, junto a su configuración.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Seguir')),
      ],
    );
  }
}

/// Paso 2 (RF2.7): confirmación final, explícito que es irreversible.
final class _ConfirmDeleteStepTwo extends StatelessWidget {
  const _ConfirmDeleteStepTwo({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Confirmar el borrado?'),
      content: Text('"${child.name}" se borrará definitivamente. Esta acción no se puede deshacer.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Conservar')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Eliminar definitivamente'),
        ),
      ],
    );
  }
}
