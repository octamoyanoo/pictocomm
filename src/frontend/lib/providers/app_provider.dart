import 'package:flutter/foundation.dart' hide Category;

import '../models/category.dart';
import '../models/image_item.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  AppProvider(this._storageService);

  final StorageService _storageService;

  List<Category> _categories = [];
  List<ImageItem> _images = [];
  Category? _selectedCategory;
  bool _isLoading = true;
  String? _error;

  List<Category> get categories => _categories;
  List<ImageItem> get images => _images;
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _storageService.loadCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(Category category) async {
    _selectedCategory = category;
    _isLoading = true;
    notifyListeners();
    try {
      _images = await _storageService.loadImages(category.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}