import 'package:flutter/material.dart';

import '../../domain/entities/picto.dart';
import '../widgets/picto_image.dart';

final class PictoDetailScreen extends StatelessWidget {
  const PictoDetailScreen({required this.picto, super.key});

  final Picto picto;

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
