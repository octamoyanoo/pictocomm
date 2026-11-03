import 'package:flutter/material.dart';

import '../../domain/entities/picto.dart';
import 'picto_image.dart';

final class PictoCard extends StatelessWidget {
  const PictoCard({required this.picto, this.onTap, this.width, this.height, super.key});

  final Picto picto;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: picto.label,
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: width,
            height: height ?? _naturalHeight,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEAE3)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: PictoImage(picto: picto, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  picto.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double _naturalHeight = 96;
}
