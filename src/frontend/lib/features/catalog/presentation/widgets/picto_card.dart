import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/picto.dart';
import '../../domain/picto_source.dart';

/// Celda del tablero de pictos.
///
/// El [Picto.source] decide el widget de imagen, así el resto del árbol no
/// necesita saber de dónde salió el archivo.
class PictoCard extends StatelessWidget {
  const PictoCard({super.key, required this.picto, required this.onTap});

  final Picto picto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: picto.label,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: _PictoImage(picto: picto),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  picto.label,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PictoImage extends StatelessWidget {
  const _PictoImage({required this.picto});

  final Picto picto;

  @override
  Widget build(BuildContext context) {
    switch (picto.source) {
      case PictoSource.custom:
        return Image.file(
          File(picto.imagePath),
          fit: BoxFit.cover,
          errorBuilder: _placeholder,
        );
      case PictoSource.remote:
        return Image.network(
          picto.imagePath,
          fit: BoxFit.cover,
          errorBuilder: _placeholder,
          loadingBuilder: _loading,
        );
      case PictoSource.bundled:
        return Image.asset(
          picto.imagePath,
          fit: BoxFit.cover,
          errorBuilder: _placeholder,
        );
    }
  }

  Widget _placeholder(BuildContext context, Object error, StackTrace? stack) {
    return const ColoredBox(
      color: Color(0xFFE3E8EF),
      child: Center(child: Icon(Icons.image_not_supported_outlined, size: 40)),
    );
  }

  Widget _loading(
    BuildContext context,
    Widget child,
    ImageChunkEvent? progress,
  ) {
    if (progress == null) return child;
    return const ColoredBox(
      color: Color(0xFFE3E8EF),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
