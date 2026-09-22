import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/image_card.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final category = provider.selectedCategory;

    return Scaffold(
      appBar: AppBar(title: Text(category?.name ?? '')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                for (final image in provider.images)
                  ImageCard(
                    image: image,
                    onTap: () {
                      // TODO: reproducir sonido y feedback visual
                    },
                  ),
              ],
            ),
    );
  }
}