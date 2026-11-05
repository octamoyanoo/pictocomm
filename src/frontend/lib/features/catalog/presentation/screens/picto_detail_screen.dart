import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/picto.dart';
import '../providers/pictos_provider.dart';
import '../widgets/picto_image.dart';

final class PictoDetailScreen extends StatelessWidget {
  const PictoDetailScreen({required this.picto, super.key});

  final Picto picto;

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<PictosProvider>();
    final l10n = AppLocalizations.of(context)!;
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deletePictoTitle(picto.label)),
        content: Text(l10n.deletePictoContent),
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
      await provider.deletePicto(picto.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                picto.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: PictoImage(picto: picto, fit: BoxFit.contain),
                ),
              ),
              // RF3.8: solo los pictos personalizados son borrables.
              if (picto.source == PictoSource.custom)
                TextButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: Text(
                    AppLocalizations.of(context)!.deletePictoButton,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
                label: Text(
                  AppLocalizations.of(context)!.close,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
