import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/app_provider.dart';
import '../widgets/category_card.dart';
import 'category_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.error != null) {
      return Scaffold(
        body: Center(child: Text('Error: ${provider.error}')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('PictoComm')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (final Category category in provider.categories)
            CategoryCard(
              category: category,
              onTap: () => _openCategory(context, category),
            ),
        ],
      ),
    );
  }

  void _openCategory(BuildContext context, Category category) {
    final provider = context.read<AppProvider>();
    provider.selectCategory(category);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const CategoryScreen(),
    ));
  }
}