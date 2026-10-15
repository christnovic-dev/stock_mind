import 'package:supabase_flutter/supabase_flutter.dart';

import '../../product/data/mock_product.dart';

class PublicStorefrontService {
  PublicStorefrontService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Récupère les informations publiques d'une boutique via son slug.
  Future<Map<String, dynamic>> getStore(String slug) async {
    final result = await _client
        .from('businesses')
        .select('id, name, description, slug')
        .eq('slug', slug)
        .maybeSingle();

    if (result == null) {
      throw Exception('Cette boutique est introuvable.');
    }

    return Map<String, dynamic>.from(result);
  }

  /// Charge les produits appartenant à cette boutique.
  Future<List<StockProduct>> getProducts(String businessId) async {
    final result = await _client
        .from('products')
        .select(
          'id, name, reference, price, quantity, minimum_quantity, category_id',
        )
        .eq('business_id', businessId)
        .order('name');

    final rows = List<Map<String, dynamic>>.from(result);

    // Charge les noms des catégories sans supposer qu'une relation
    // PostgREST particulière est déjà configurée.
    final categoryIds = rows
        .map((row) => row['category_id'])
        .where((id) => id != null)
        .map((id) => id.toString())
        .toSet()
        .toList();

    final categoryNames = <String, String>{};

    if (categoryIds.isNotEmpty) {
      final categoryRows = await _client
          .from('categories')
          .select('id, name')
          .inFilter('id', categoryIds);

      for (final row in categoryRows) {
        final category = Map<String, dynamic>.from(row);
        categoryNames[category['id'].toString()] =
            category['name']?.toString() ?? 'Sans catégorie';
      }
    }

    return rows.map((row) {
      final categoryId = row['category_id']?.toString();

      return StockProduct(
        id: row['id'].toString(),
        name: row['name']?.toString() ?? '',
        reference: row['reference']?.toString() ?? '',
        category: categoryNames[categoryId] ?? 'Sans catégorie',
        price: (row['price'] as num).toDouble(),
        quantity: (row['quantity'] as num).toInt(),
        minimumQuantity: (row['minimum_quantity'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  /// Enregistre une commande via une fonction SQL sécurisée.
  /// Les prix sont calculés côté base de données, pas par l'application.
  Future<String> createOrder({
    required String storeSlug,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String customerCity,
    required Map<String, int> cart,
  }) async {
    if (cart.isEmpty) {
      throw Exception('Le panier est vide.');
    }

    final items = cart.entries
        .map((entry) => {'product_id': entry.key, 'quantity': entry.value})
        .toList();

    final result = await _client.rpc(
      'create_public_store_order',
      params: {
        'p_store_slug': storeSlug,
        'p_customer_name': customerName.trim(),
        'p_customer_phone': customerPhone.trim(),
        'p_customer_address': customerAddress.trim(),
        'p_customer_city': customerCity.trim(),
        'p_items': items,
      },
    );

    return result.toString();
  }
}
