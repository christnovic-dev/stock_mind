import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/mock_product.dart';

class ProductService {
  ProductService({SupabaseClient? client, String? businessId})
    : _client = client ?? Supabase.instance.client,
      _businessId = businessId;

  final SupabaseClient _client;
  final String? _businessId;

  /// Vérifie que l'utilisateur est connecté et membre
  /// de l'entreprise sélectionnée.
  Future<String> getBusinessId() async {
    final businessId = _businessId;

    if (businessId == null || businessId.trim().isEmpty) {
      throw Exception(
        'Aucune entreprise sélectionnée. '
        'Transmettez le businessId depuis OverviewPage.',
      );
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Vous devez être connecté pour gérer vos produits.');
    }

    final membership = await _client
        .from('business_members')
        .select('business_id')
        .eq('user_id', user.id)
        .eq('business_id', businessId)
        .limit(1)
        .maybeSingle();

    if (membership == null) {
      throw Exception('Vous ne disposez pas d’un accès à cette entreprise.');
    }

    return businessId;
  }

  /// Récupère les catégories de l'entreprise active.
  Future<List<Map<String, dynamic>>> getCategories() async {
    final businessId = await getBusinessId();

    final rows = await _client
        .from('categories')
        .select('id, name')
        .eq('business_id', businessId)
        .order('name');

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Récupère les produits et associe leur nom de catégorie.
  Future<List<StockProduct>> getProducts() async {
    final businessId = await getBusinessId();

    final productRows = await _client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    final categoryRows = await _client
        .from('categories')
        .select('id, name')
        .eq('business_id', businessId)
        .order('name');

    final products = List<Map<String, dynamic>>.from(productRows);
    final categories = List<Map<String, dynamic>>.from(categoryRows);

    final categoryNames = <String, String>{
      for (final category in categories)
        category['id'].toString(): category['name'].toString(),
    };

    return products.map((row) {
      final categoryId = row['category_id']?.toString();

      return StockProduct(
        id: row['id'].toString(),
        name: row['name'] as String,
        reference: row['reference'] as String? ?? '',
        category: categoryNames[categoryId] ?? 'Sans catégorie',
        price: (row['price'] as num).toDouble(),
        quantity: (row['quantity'] as num).toInt(),
        minimumQuantity: (row['minimum_quantity'] as num).toInt(),
      );
    }).toList();
  }

  /// Crée ou modifie un produit.
  ///
  /// La fonction SQL enregistre automatiquement :
  /// - le stock initial lors d'une création ;
  /// - l'ajustement si la quantité change ;
  /// - l'historique des modifications de la fiche.
  Future<void> saveProduct(
    StockProduct product, {
    required String categoryName,
  }) async {
    final businessId = await getBusinessId();

    String? categoryId;
    final normalizedCategory = categoryName.trim();

    if (normalizedCategory.isNotEmpty &&
        normalizedCategory != 'Sans catégorie') {
      final category = await _client
          .from('categories')
          .select('id')
          .eq('business_id', businessId)
          .eq('name', normalizedCategory)
          .maybeSingle();

      if (category == null) {
        throw Exception(
          'La catégorie "$normalizedCategory" '
          'est introuvable dans cette entreprise.',
        );
      }

      categoryId = category['id'].toString();
    }

    final productId = product.id.trim().isEmpty ? null : product.id.trim();

    await _client.rpc(
      'save_product_with_stock_movement',
      params: {
        'p_business_id': businessId,
        'p_product_id': productId,
        'p_category_id': categoryId,
        'p_name': product.name.trim(),
        'p_reference': product.reference.trim(),
        'p_price': product.price,
        'p_quantity': product.quantity,
        'p_minimum_quantity': product.minimumQuantity,
      },
    );
  }

  /// Supprime un produit tout en conservant son historique.
  Future<void> deleteProduct(String productId) async {
    final businessId = await getBusinessId();

    if (productId.trim().isEmpty) {
      throw Exception('Identifiant du produit invalide.');
    }

    await _client.rpc(
      'delete_product_with_audit',
      params: {'p_business_id': businessId, 'p_product_id': productId.trim()},
    );
  }
}
