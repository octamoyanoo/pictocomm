import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pictocomm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/data_url.dart';
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
    final newChild = await showDialog<(String, int?, String?)>(
      context: context,
      builder: (_) => const AddChildDialog(),
    );
    if (newChild == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    await context.read<ChildrenProvider>().createChild(newChild.$1, null, newChild.$2, newChild.$3);
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
          ChildrenFailureState() => Center(child: Text(AppLocalizations.of(context)!.profilesLoadError(state.message))),
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
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(l10n.profileTitle, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 20),
        const _CaregiverCard(),
        const SizedBox(height: 20),
        // RF4.2: selector de idioma de la UI, espacio del adulto. El cambio
        // aplica en el momento (RF4.3) vía LocaleController sobre MaterialApp.
        const _LanguageSection(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.childrenSection, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              tooltip: l10n.addChildTooltip,
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
              l10n.noChildrenYet,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
        for (final child in children) _ChildTile(child: child, onDelete: () => onDelete(child)),
      ],
    );
  }
}

/// RF4.2: selector de idioma. Los nombres de idioma se muestran SIEMPRE en su
/// propio idioma (Español/English/Português): no dependen del activo.
final class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  static const Map<String, String> _nativeNames = <String, String>{
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.languageSection,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          // Tiles propios (no RadioListTile): tap directo al controller. Los
          // Margin/Icon replican la métrica de un radio compacto.
          Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (final code in LocaleController.supportedLanguageCodes)
                  _LanguageOptionTile(
                    isSelected: controller.languageCode == code,
                    name: _nativeNames[code]!,
                    onTap: () => controller.setLanguage(code),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de radio propio: tap directo (sin depender del RadioGroup nuevo
/// de Flutter) e indicador visual del idioma activo (RF4.2).
final class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.isSelected,
    required this.name,
    required this.onTap,
  });

  final bool isSelected;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.accent : AppColors.textMuted,
        size: 22,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
    );
  }
}

final class _CaregiverCard extends StatelessWidget {
  const _CaregiverCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.accountSection, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                const Text('casa@pictocomm.app', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(l10n.signOut, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
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
    final l10n = AppLocalizations.of(context)!;
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
            tooltip: l10n.deleteProfileTooltip,
          ),
        ],
      ),
    );
  }
}

/// Crear perfil (RF2.6 + RF3.11): nombre, avatar de paleta fija y foto opcional.
final class AddChildDialog extends StatefulWidget {
  const AddChildDialog({super.key});

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

final class _AddChildDialogState extends State<AddChildDialog> {
  final _nameController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  int _selectedIndex = 0;
  String? _photoDataUrl;

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
    Navigator.of(context).pop((name, AppColors.avatarPalette[_selectedIndex].toARGB32(), _photoDataUrl));
  }

  /// RF3.11: foto opcional del chico. Cámara solo en móvil.
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: Text(AppLocalizations.of(context)!.gallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                enabled: !kIsWeb,
                leading: Icon(Icons.photo_camera_outlined, color: kIsWeb ? AppColors.textMuted : AppColors.accent),
                title: Text(AppLocalizations.of(context)!.camera),
                onTap: kIsWeb ? null : () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null) {
      return;
    }
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 400, imageQuality: 70);
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      final mime = picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      setState(() => _photoDataUrl = DataUrl.encode(bytes, mime));
    } on Object {
      // Sin foto: el avatar cae al círculo de color (RF3.11).
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addChildDialog),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_photoDataUrl == null)
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.accentLight,
                    child: Icon(Icons.add_a_photo_outlined, color: AppColors.accent),
                  )
                else
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: MemoryImage(DataUrl.decode(_photoDataUrl!)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.nameLabel),
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(onPressed: _submit, child: Text(l10n.addChildAction)),
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.deleteChildTitle(child.name)),
      content: Text(l10n.deleteChildContent),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.next)),
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.confirmDeleteTitle),
      content: Text(l10n.deleteChildFinalContent(child.name)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.keep)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(l10n.deleteForever),
        ),
      ],
    );
  }
}
