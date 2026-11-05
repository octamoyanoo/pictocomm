import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';

import '../constants/app_routes.dart';
import '../theme/app_theme.dart';

final class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.currentIndex, super.key});

  /// Los labels van por l10n (RF4.6); el `key` de test sale del nombre de
  /// ruta para no depender del idioma.
  static const List<(IconData icon, IconData selectedIcon, String route)> destinations = [
    (Icons.home_outlined, Icons.home, AppRoutes.home),
    (Icons.image_outlined, Icons.image, AppRoutes.pictogramas),
    (Icons.chat_bubble_outline, Icons.chat_bubble, AppRoutes.comunicar),
    (Icons.person_outline, Icons.person, AppRoutes.perfil),
  ];

  final int currentIndex;

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(destinations[index].$3);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.navInicio,
      l10n.navPictogramas,
      l10n.navComunicar,
      l10n.navPerfil,
    ];
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onDestinationSelected(context, index),
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accentLight,
      destinations: [
        for (final (index, (icon, selectedIcon, route)) in destinations.indexed)
          NavigationDestination(
            key: Key('bottom_nav_$route'),
            icon: Icon(icon, color: AppColors.textSecondary),
            selectedIcon: Icon(selectedIcon, color: AppColors.accent),
            label: labels[index],
          ),
      ],
    );
  }
}
