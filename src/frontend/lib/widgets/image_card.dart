import 'dart:io';

import 'package:flutter/material.dart';

import '../models/image_item.dart';

class ImageCard extends StatelessWidget {
  const ImageCard({super.key, required this.image, required this.onTap});

  final ImageItem image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image.isLocal)
              Image.file(
                File(image.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
              )
            else
              Image.asset(
                image.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                image.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}