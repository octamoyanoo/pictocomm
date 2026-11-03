import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../domain/entities/child_profile.dart';

final class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

final class _ProfileScreenState extends State<ProfileScreen> {
  final List<ChildProfile> _children = [
    const ChildProfile(id: 'nina', name: 'Nina', age: 4, avatarColor: AppColors.accent),
    const ChildProfile(id: 'benja', name: 'Benja', age: 6, avatarColor: Color(0xFF4CAF50)),
  ];

  void _addChild() async {
    final created = await showDialog<ChildProfile>(
      context: context,
      builder: (_) => const _AddChildDialog(),
    );
    if (created == null) {
      return;
    }
    setState(() => _children.add(created));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
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
                  onPressed: _addChild,
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
            for (final child in _children) _ChildTile(child: child),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
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
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.accentLight,
            child: const Icon(Icons.face_outlined, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mi cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('casa@pictocomm.app', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('Cerrar sesión', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
        ],
      ),
    );
  }
}

final class _ChildTile extends StatelessWidget {
  const _ChildTile({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final subtitle = child.age == null ? 'Sin edad configurada' : '${child.age} años';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: child.avatarColor ?? AppColors.accentLight,
            child: Text(child.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

final class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog();

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

final class _AddChildDialogState extends State<_AddChildDialog> {
  final _nameController = TextEditingController();

  int _age = 4;

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
    final id = 'child-${DateTime.now().microsecondsSinceEpoch}';
    Navigator.of(context).pop(ChildProfile(id: id, name: name, age: _age));
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Edad'),
              Expanded(
                child: Slider(
                  value: _age.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  label: '$_age años',
                  activeColor: AppColors.accent,
                  onChanged: (value) => setState(() => _age = value.round()),
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
