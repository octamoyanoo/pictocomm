import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/data_url.dart';
import '../../../profiles/presentation/providers/session_provider.dart';
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

  /// RF3.2: menú de fuentes — galería, cámara (solo móvil) o URL web pegada
  /// (RF3.3). En todos los casos los bytes terminan guardados en data URL
  /// local: el picto funciona offline después de crearse.
  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<String>(
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
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: const Text('Galería', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              ListTile(
                enabled: !kIsWeb,
                leading: Icon(Icons.photo_camera_outlined, color: kIsWeb ? AppColors.textMuted : AppColors.accent),
                title: const Text('Cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: kIsWeb ? const Text('No disponible en el navegador', style: TextStyle(fontSize: 12)) : null,
                onTap: kIsWeb ? null : () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.accent),
                title: const Text('Pegar URL de imagen', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ej: una imagen de Google Imágenes', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.of(context).pop('url'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) {
      return;
    }
    switch (source) {
      case 'gallery':
        await _pickImage(ImageSource.gallery);
      case 'camera':
        await _pickImage(ImageSource.camera);
      case 'url':
        await _promptImageUrl();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _loadingImage = true);
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 600, imageQuality: 70);
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
      setState(() {
        _imageDataUrl = DataUrl.encode(bytes, _mimeOf(picked.name));
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

  /// RF3.3: descarga la imagen de la URL y la guarda local. Si el host
  /// bloquea la descarga desde el navegador, guía hacia la galería.
  Future<void> _promptImageUrl() async {
    final url = await showDialog<String>(
      context: context,
      builder: (_) => const _ImageUrlDialog(),
    );
    if (url == null || url.trim().isEmpty || !mounted) {
      return;
    }
    setState(() => _loadingImage = true);
    try {
      final response = await http.get(Uri.parse(url.trim())).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const DataSourceException('La imagen no se pudo descargar');
      }
      final mime = (response.headers['content-type'] ?? 'image/jpeg').split(';').first;
      setState(() {
        _imageDataUrl = DataUrl.encode(response.bodyBytes, mime);
        _loadingImage = false;
        _errorText = null;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingImage = false;
        _errorText = 'No se pudo descargar la imagen (el sitio puede bloquearlo). '
            'Guardala en el dispositivo y elegila desde la galería.';
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
    final childId = context.read<SessionProvider>().activeChild?.id;
    if (childId == null) {
      setState(() => _errorText = 'Elegí primero un niño en "Cambiar de niño" (RF3.4)');
      return;
    }
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
        childProfileId: childId,
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
                      onPick: _chooseSource,
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
                      child: Image.memory(DataUrl.decode(imageDataUrl!), fit: BoxFit.cover),
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

final class _ImageUrlDialog extends StatefulWidget {
  const _ImageUrlDialog();

  @override
  State<_ImageUrlDialog> createState() => _ImageUrlDialogState();
}

final class _ImageUrlDialogState extends State<_ImageUrlDialog> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Imagen desde la web'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'En Google Imágenes: mantené apretada la imagen → "Copiar dirección de imagen" y pegala acá.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.of(context).pop(_urlController.text), child: const Text('Descargar')),
      ],
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
