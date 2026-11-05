import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/child_profile.dart';

/// Avatar de perfil de niño (RF2.6): círculo con inicial, color del perfil.
/// La foto (RF2.12) reemplazará este widget cuando exista.
final class ChildAvatar extends StatelessWidget {
  const ChildAvatar({required this.child, this.radius = 24, super.key});

  final ChildProfile child;
  final double radius;

  @override
  Widget build(BuildContext context) {
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
