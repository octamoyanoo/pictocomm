import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../providers/catalog_provider.dart';

final class AddPictoScreen extends StatefulWidget {
  const AddPictoScreen({super.key});

  @override
  State<AddPictoScreen> createState() => _AddPictoScreenState();
}

final class _AddPictoScreenState extends State<AddPictoScreen> {
  final _labelController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String? _imageDataUrl;

  String? _categoryId;

  String? _errorText;

  bool _loadingImage = false;

  bool _saving = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _loadingImage = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 70);
      if (!mounted) {
        return;
      }
      if (picked == null) {
        setState(() => _loadingImage = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }
      final mime = _mimeOf(picked.name);
      setState(() {
        _imageDataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
        _loadingImage = false;
        _errorText = null;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingImage = false;
        _errorText = 'No se pudo cargar la imagen';
      });
    }
  }

  String _mimeOf(String fileName) {
    final lowered = fileName.toLowerCase();
    if (lowered.endsWith('.png')) {
      return 'image/png';
    }
    if (lowered.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    final categoryId = _categoryId;
    if (label.isEmpty) {
      setState(() => _errorText = 'Ingresá un nombre');
      return;
    }
    if (_imageDataUrl == null) {
      setState(() => _errorText = 'Elegí una imagen');
      return;
    }
    if (categoryId == null) {
      setState(() => _errorText = 'Elegí una categoría');
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final now = DateTime.now().toUtc();
      final picto = Picto(
        id: '',
        label: label,
        categoryId: categoryId,
        source: PictoSource.custom,
        imageUrl: _imageDataUrl,
        createdAt: now,
        updatedAt: now,
      );
      await context.read<CatalogProvider>().createPicto(picto);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _errorText = 'No se pudo guardar. Intentá de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogProvider>().state;
    final categories = state is CatalogLoadedState ? state.categories : const <Category>[];
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddScreenHeader(title: 'Nuevo pictograma', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ImagePickerTile(
                      imageDataUrl: _imageDataUrl,
                      loading: _loadingImage,
                      onPick: _pickImage,
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: _FieldLabel('Nombre'),
                    ),
                    TextField(
                      controller: _labelController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Ej: Agua'),
                    ),
                    const SizedBox(height: 16),
                    if (categories.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Primero creá un catálogo para poder guardar pictogramas',
                          style: TextStyle(fontSize: 13, color: AppColors.warning),
                        ),
                      )
                    else
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: _FieldLabel('Categoría'),
                      ),
                    if (categories.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final category in categories)
                            ChoiceChip(
                              label: Text(category.name),
                              selected: _categoryId == category.id,
                              onSelected: (selected) => setState(() {
                                _categoryId = selected ? category.id : null;
                              }),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _categoryId == category.id ? AppColors.accent : AppColors.textSecondary,
                              ),
                              selectedColor: AppColors.accentLight,
                              showCheckmark: false,
                            ),
                        ],
                      ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorText!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Guardar pictograma'),
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

final class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({required this.imageDataUrl, required this.loading, required this.onPick});

  final String? imageDataUrl;
  final bool loading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accentLight, width: 1.5),
          ),
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : imageDataUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_outlined, size: 48, color: AppColors.accent),
                        const SizedBox(height: 8),
                        const Text(
                          'Tocá para elegir una imagen',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(base64Decode(imageDataUrl!.split(',').last), fit: BoxFit.cover),
                    ),
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
