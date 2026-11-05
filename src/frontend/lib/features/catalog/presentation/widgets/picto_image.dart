import 'package:flutter/material.dart';

import '../../../../core/utils/data_url.dart';
import '../../domain/entities/picto.dart';

/// Renderiza la imagen de un pictograma según su fuente, resolviendo el
/// `switch` en un solo lugar (`PictoSource`).
final class PictoImage extends StatelessWidget {
  const PictoImage({required this.picto, this.fit = BoxFit.contain, this.width, this.height, super.key});

  final Picto picto;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final url = picto.imageUrl ?? '';
    return switch (picto.source) {
      PictoSource.bundled => Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const _ImagePlaceholder(),
      ),
      PictoSource.custom => _custom(url),
      PictoSource.remote => Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const _ImagePlaceholder(),
      ),
    };
  }

  Widget _custom(String url) {
    try {
      return Image.memory(
        DataUrl.decode(url),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const _ImagePlaceholder(),
      );
    } on FormatException {
      return const _ImagePlaceholder();
    }
  }
}

final class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.secondary,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: colorScheme.primary, size: 28),
    );
  }
}
