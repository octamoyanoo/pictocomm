import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/data_url.dart';
import '../../domain/entities/child_profile.dart';

/// Avatar de perfil de niño (RF2.6/RF3.11): foto real si existe, con
/// fallback al círculo de color con inicial.
final class ChildAvatar extends StatelessWidget {
  const ChildAvatar({required this.child, this.radius = 24, super.key});

  final ChildProfile child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photoUrl = child.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: radius,
          backgroundColor: child.avatarColor ?? AppColors.accent,
          backgroundImage: MemoryImage(DataUrl.decode(photoUrl)),
        );
      } on FormatException {
        // Foto corrupta: cae al avatar de color, nunca rompe la pantalla.
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: child.avatarColor ?? AppColors.accent,
      child: Text(
        child.name.isEmpty ? '?' : child.name.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: AppColors.surface,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
