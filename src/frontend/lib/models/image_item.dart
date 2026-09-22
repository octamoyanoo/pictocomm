class ImageItem {
  final String id;
  final String name;
  final String imagePath;
  final String categoryId;
  final bool isLocal;

  const ImageItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.categoryId,
    this.isLocal = false,
  });
}