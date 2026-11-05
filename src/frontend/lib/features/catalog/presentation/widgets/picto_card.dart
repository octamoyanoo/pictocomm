import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/picto.dart';
import 'picto_image.dart';

final class PictoCard extends StatefulWidget {
  const PictoCard({required this.picto, this.onTap, this.width, this.height, super.key});

  final Picto picto;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  State<PictoCard> createState() => _PictoCardState();
}

final class _PictoCardState extends State<PictoCard> {
  bool _flash = false;

  void _handleTap() {
    // RF1.2: feedback visual inequívoco del toque — destaque breve del picto
    // tocado, además de su aparición en la barra. El sonido NO entra acá:
    // el Play es bajo demanda (RF1.5).
    setState(() => _flash = true);
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() => _flash = false);
      }
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: _flash ? const Key('picto_highlighted') : null,
      label: widget.picto.label,
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedScale(
            scale: _flash ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: widget.width,
              height: widget.height ?? _naturalHeight,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _flash ? AppColors.accent : const Color(0xFFEFEAE3),
                  width: _flash ? 2.5 : 1,
                ),
                boxShadow: _flash
                    ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)]
                    : null,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PictoImage(picto: widget.picto, fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.picto.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _flash ? AppColors.accent : null),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _naturalHeight = 96;
}
