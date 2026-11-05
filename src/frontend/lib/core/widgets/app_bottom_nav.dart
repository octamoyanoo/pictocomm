import 'package:flutter/material.dart';

import '../constants/app_routes.dart';
import '../theme/app_theme.dart';

final class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.currentIndex, super.key});

  static const List<(IconData icon, IconData selectedIcon, String label, String route)> destinations = [
    (Icons.home_outlined, Icons.home, 'Inicio', AppRoutes.home),
    (Icons.image_outlined, Icons.image, 'Pictogramas', AppRoutes.pictogramas),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Comunicar', AppRoutes.comunicar),
    (Icons.person_outline, Icons.person, 'Perfil', AppRoutes.perfil),
  ];

  final int currentIndex;

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(destinations[index].$4);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onDestinationSelected(context, index),
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accentLight,
      destinations: [
        for (final (icon, selectedIcon, label, _) in destinations)
          NavigationDestination(
            key: Key('bottom_nav_${label.toLowerCase()}'),
            icon: Icon(icon, color: AppColors.textSecondary),
            selectedIcon: Icon(selectedIcon, color: AppColors.accent),
            label: label,
          ),
      ],
    );
  }
}
