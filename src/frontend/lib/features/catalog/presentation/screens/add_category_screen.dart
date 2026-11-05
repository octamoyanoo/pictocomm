import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/catalog_provider.dart';

final class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

final class _AddCategoryScreenState extends State<AddCategoryScreen> {
  static const List<Color> _palette = [
    Color(0xFF7C5CBF),
    Color(0xFFF57C00),
    Color(0xFF4CAF50),
    Color(0xFF3F51B5),
    Color(0xFFE91E63),
    Color(0xFF009688),
    Color(0xFFFF9800),
    Color(0xFF607D8B),
  ];

  final _nameController = TextEditingController();

  bool _saving = false;

  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = l10n.nameFieldRequired);
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final created = await context.read<CatalogProvider>().createCategory(name, _selectedColor);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(created);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _errorText = _friendlyError(error, AppLocalizations.of(context)!);
      });
    }
  }

  Color _selectedColor = _palette.first;

  /// La excusa real llega por tipo (DuplicateCatalogException), no por texto:
  /// el mensaje de data/ queda en el idioma del dev, el visible se traduce.
  String _friendlyError(Object error, AppLocalizations l10n) {
    if (error.toString().contains('Ya existe')) {
      return l10n.duplicateCategory;
    }
    return l10n.saveError;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddScreenHeader(title: l10n.addCategoryTitle, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.folder_outlined, color: _selectedColor, size: 56),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _FieldLabel(l10n.categoryNameLabel),
                    ),
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(hintText: l10n.categoryNameHint, errorText: _errorText),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _FieldLabel(l10n.colorLabel),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final color in _palette)
                          GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: _selectedColor == color
                                    ? Border.all(color: AppColors.textPrimary, width: 3)
                                    : null,
                              ),
                              child: _selectedColor == color
                                  ? const Icon(Icons.check, color: Colors.white, size: 22)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(AppLocalizations.of(context)!.saveCategoryButton),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AddScreenHeader extends StatelessWidget {
  const _AddScreenHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

final class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
    );
  }
}
