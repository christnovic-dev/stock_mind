import 'package:flutter/material.dart';

import '../sidebar/categories/data/mock_categorie.dart';
import '../sidebar/product/data/mock_product.dart';

class StockStore extends ChangeNotifier {
  StockStore._();

  static final StockStore instance = StockStore._();

  final List<StockProduct> products = List.of(mockProducts);
  final List<StockCategory> categories = List.of(mockCategories);

  int productCountFor(String categoryName) {
    return products.where((product) => product.category == categoryName).length;
  }

  void saveProduct(StockProduct product) {
    final index = products.indexWhere((item) => item.id == product.id);

    if (index >= 0) {
      products[index] = product;
    } else {
      products.insert(0, product);
    }

    notifyListeners();
  }

  void removeProduct(String productId) {
    products.removeWhere((product) => product.id == productId);
    notifyListeners();
  }

  void saveCategory(StockCategory category) {
    final index = categories.indexWhere((item) => item.id == category.id);

    if (index >= 0) {
      final oldCategory = categories[index];

      // Si le nom change, conserver le lien avec les produits existants.
      if (oldCategory.name != category.name) {
        for (var i = 0; i < products.length; i++) {
          if (products[i].category == oldCategory.name) {
            products[i] = products[i].copyWith(category: category.name);
          }
        }
      }

      categories[index] = category;
    } else {
      categories.insert(0, category);
    }

    notifyListeners();
  }

  bool removeCategory(String categoryId) {
    final index = categories.indexWhere((item) => item.id == categoryId);

    if (index < 0) return false;

    final category = categories[index];

    if (productCountFor(category.name) > 0) {
      return false;
    }

    categories.removeAt(index);
    notifyListeners();
    return true;
  }
}
