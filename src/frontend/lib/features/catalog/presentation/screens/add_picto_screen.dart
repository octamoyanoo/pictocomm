import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pictocomm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/data_url.dart';
import '../../../profiles/domain/entities/child_profile.dart';
import '../../../profiles/presentation/providers/session_provider.dart';
import '../../data/utils/custom_image_compressor.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../providers/catalog_provider.dart';

/// REQ-CAT-02 (RNF-3.11): un solo formulario para **crear** y **editar**
/// pictogramas. Crea sin argumentos (entrada global, RF-3.14); con
/// [categoryToPreselect] esa categoría viene marcada; con [pictoToEdit]
/// edita (RF-3.16) y, si es legacy sin dueño, ofrece asignarle chico
/// (RF-3.19).
final class AddPictoScreen extends StatefulWidget {
  const AddPictoScreen({this.categoryToPreselect, this.pictoToEdit, super.key});

  final String? categoryToPreselect;

  final Picto? pictoToEdit;

  @override
  State<AddPictoScreen> createState() => _AddPictoScreenState();
}

final class _AddPictoScreenState extends State<AddPictoScreen> {
  final _labelController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool get _editing => widget.pictoToEdit != null;

  String? _imageDataUrl;

  final Set<String> _selectedCategoryIds = {};

  /// RF-3.19: chico elegido para un picto legacy sin dueño (`null` = sin
  /// asignar, sigue visible para todos).
  String? _assignedChildId;

  List<ChildProfile> _children = const [];

  String? _errorText;

  bool _loadingImage = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.pictoToEdit;
    if (editing != null) {
      _labelController.text = editing.label;
      _imageDataUrl = editing.imageUrl;
      _selectedCategoryIds.addAll(editing.categoryIds);
      _assignedChildId = editing.childProfileId;
      if (editing.childProfileId == null) {
        _loadChildren();
      }
    } else if (widget.categoryToPreselect != null) {
      _selectedCategoryIds.add(widget.categoryToPreselect!);
    }
  }

  Future<void> _loadChildren() async {
    final children = await context.read<CatalogProvider>().childrenForAssignment();
    if (!mounted) {
      return;
    }
    setState(() => _children = children);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  /// RF3.2: menú de fuentes — galería, cámara (solo móvil) o URL web pegada
  /// (RF3.3). En todos los casos los bytes terminan guardados en data URL
  /// local: el picto funciona offline después de crearse. Todas las fuentes
  /// pasan por [CustomImageCompressor.compress] (REQ-CAT-01: reescala a
  /// máx 1024px y comprime) antes de persistirse.
  Future<void> _chooseSource() async {
    final l10n = AppLocalizations.of(context)!;
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
                title: Text(l10n.gallery, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              ListTile(
                enabled: !kIsWeb,
                leading: Icon(Icons.photo_camera_outlined, color: kIsWeb ? AppColors.textMuted : AppColors.accent),
                title: Text(l10n.camera, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: kIsWeb ? Text(l10n.cameraUnavailable, style: const TextStyle(fontSize: 12)) : null,
                onTap: kIsWeb ? null : () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.accent),
                title: Text(l10n.pasteImageUrl, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.pasteUrlSub, style: const TextStyle(fontSize: 12)),
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
      // REQ-CAT-01 (RF-CAT): la imagen se comprime a máx 1024px antes de
      // guardarse, tanto para el storage local como para subir al backend.
      final compressed = CustomImageCompressor.compress(bytes);
      setState(() {
        _imageDataUrl = DataUrl.encode(compressed.bytes, compressed.mime);
        _loadingImage = false;
        _errorText = null;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingImage = false;
        _errorText = AppLocalizations.of(context)!.imageLoadError;
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
      // REQ-CAT-01 (RF-CAT): la imagen de la web también pasa por el límite
      // de 1024px y la compresión, igual que galería/cámara. Si los bytes no
      // son una imagen válida, [CustomImageCompressor.compress] lanza y
      // cae al catch de abajo.
      final compressed = CustomImageCompressor.compress(response.bodyBytes);
      setState(() {
        _imageDataUrl = DataUrl.encode(compressed.bytes, compressed.mime);
        _loadingImage = false;
        _errorText = null;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingImage = false;
        _errorText = AppLocalizations.of(context)!.urlDownloadError;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final label = _labelController.text.trim();
    final childId = _editing
        ? (widget.pictoToEdit!.childProfileId ?? _assignedChildId)
        : context.read<SessionProvider>().activeChild?.id;
    if (!_editing && childId == null) {
      setState(() => _errorText = l10n.selectChildFirst);
      return;
    }
    if (label.isEmpty) {
      setState(() => _errorText = l10n.nameFieldRequired);
      return;
    }
    if (_imageDataUrl == null) {
      setState(() => _errorText = l10n.imageRequired);
      return;
    }
    // RF-3.13: al menos una categoría.
    if (_selectedCategoryIds.isEmpty) {
      setState(() => _errorText = l10n.categoryRequired);
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final now = DateTime.now().toUtc();
      final picto = Picto(
        id: widget.pictoToEdit?.id ?? '',
        label: label,
        categoryIds: [..._selectedCategoryIds],
        source: PictoSource.custom,
        imageUrl: _imageDataUrl,
        childProfileId: childId,
        createdAt: widget.pictoToEdit?.createdAt ?? now,
        updatedAt: now,
      );
      final provider = context.read<CatalogProvider>();
      if (_editing) {
        await provider.updatePicto(picto);
      } else {
        await provider.createPicto(picto);
      }
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
        _errorText = AppLocalizations.of(context)!.saveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<CatalogProvider>().state;
    final categories = state is CatalogLoadedState ? state.categories : const <Category>[];
    final showAssignChild = _editing && widget.pictoToEdit!.childProfileId == null;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddScreenHeader(
              title: _editing ? l10n.editPictoTitle : l10n.addPictoTitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _FieldLabel(l10n.nameFieldLabel),
                    ),
                    TextField(
                      controller: _labelController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(hintText: l10n.nameFieldHint),
                    ),
                    const SizedBox(height: 16),
                    if (categories.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.firstCatalogWarning,
                          style: const TextStyle(fontSize: 13, color: AppColors.warning),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _FieldLabel(l10n.categoryFieldLabel),
                      ),
                    if (categories.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // RF-3.13: chips multi-select (FilterChip).
                          for (final category in categories)
                            FilterChip(
                              label: Text(category.nameFor(Localizations.localeOf(context).languageCode)),
                              selected: _selectedCategoryIds.contains(category.id),
                              onSelected: (selected) => setState(() {
                                selected ? _selectedCategoryIds.add(category.id) : _selectedCategoryIds.remove(category.id);
                              }),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedCategoryIds.contains(category.id)
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                              ),
                              selectedColor: AppColors.accentLight,
                              showCheckmark: false,
                            ),
                        ],
                      ),
                    // RF-3.19: asignación de dueño para pictos legacy.
                    if (showAssignChild) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _FieldLabel(l10n.assignChildLabel),
                      ),
                      Text(
                        l10n.assignChildOptional,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: _assignedChildId,
                        items: [
                          DropdownMenuItem<String?>(child: Text(l10n.assignChildNone)),
                          for (final child in _children)
                            DropdownMenuItem<String?>(value: child.id, child: Text(child.name)),
                        ],
                        onChanged: (value) => setState(() => _assignedChildId = value),
                      ),
                    ],
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
                          : Text(_editing ? l10n.updatePictoButton : l10n.savePictoButton),
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
                        Text(
                          AppLocalizations.of(context)!.tapToPickImage,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent),
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.webImageTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.webImageContent,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.urlInputHint),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(onPressed: () => Navigator.of(context).pop(_urlController.text), child: Text(l10n.download)),
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
