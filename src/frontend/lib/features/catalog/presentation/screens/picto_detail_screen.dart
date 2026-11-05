import 'package:flutter/material.dart';
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
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Eliminar "${picto.label}"?'),
        content: const Text('El pictograma se borra del dispositivo para este niño.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Seguir')),
        ],
      ),
    );
    if (first != true || !context.mounted) {
      return;
    }
    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Confirmar el borrado?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Conservar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar definitivamente'),
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
                  label: const Text('Eliminar pictograma', style: TextStyle(color: AppColors.error)),
                ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
                label: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
