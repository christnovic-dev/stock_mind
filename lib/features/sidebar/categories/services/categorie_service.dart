import 'package:supabase_flutter/supabase_flutter.dart';

import '../../product/services/product_services.dart';
import '../data/mock_categorie.dart';

class CategoryService {
  CategoryService({SupabaseClient? client, required String businessId})
    : _client = client ?? Supabase.instance.client,
      _productService = ProductService(client: client, businessId: businessId),
      _businessId = businessId;

  final SupabaseClient _client;
  final ProductService _productService;
  final String _businessId;

  /// Vérifie que l'utilisateur est connecté et membre de l'entreprise.
  Future<String> _getAuthorizedBusinessId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Vous devez être connecté pour gérer les catégories.');
    }

    if (_businessId.trim().isEmpty) {
      throw Exception('Aucune entreprise sélectionnée.');
    }

    // Vérification de l'appartenance à l'entreprise sélectionnée.
    final membership = await _client
        .from('business_members')
        .select('business_id')
        .eq('user_id', user.id)
        .eq('business_id', _businessId)
        .limit(1)
        .maybeSingle();

    if (membership == null) {
      throw Exception('Vous ne disposez pas d’un accès à cette entreprise.');
    }

    return _businessId;
  }

  /// Charge les catégories et compte leurs produits.
  Future<List<StockCategory>> getCategories() async {
    final businessId = await _getAuthorizedBusinessId();

    final results = await Future.wait([
      _client
          .from('categories')
          .select('id, name, description')
          .eq('business_id', businessId)
          .order('name'),
      _client
          .from('products')
          .select('id, category_id')
          .eq('business_id', businessId),
    ]);

    final categoryRows = List<Map<String, dynamic>>.from(results[0] as List);

    final productRows = List<Map<String, dynamic>>.from(results[1] as List);

    final counts = <String, int>{};

    for (final product in productRows) {
      final categoryId = product['category_id']?.toString();

      if (categoryId != null) {
        counts[categoryId] = (counts[categoryId] ?? 0) + 1;
      }
    }

    return categoryRows.map((row) {
      final id = row['id'].toString();

      return StockCategory(
        id: id,
        name: row['name'] as String,
        description: row['description'] as String? ?? '',
        productCount: counts[id] ?? 0,
      );
    }).toList();
  }

  /// Crée ou modifie une catégorie.
  Future<void> saveCategory(StockCategory category) async {
    final businessId = await _getAuthorizedBusinessId();

    final data = <String, dynamic>{
      'business_id': businessId,
      'name': category.name.trim(),
      'description': category.description.trim(),
    };

    if (category.id.isEmpty) {
      await _client.from('categories').insert(data);
    } else {
      final response = await _client
          .from('categories')
          .update(data)
          .eq('id', category.id)
          .eq('business_id', businessId)
          .select('id');

      if ((response as List).isEmpty) {
        throw Exception('Catégorie introuvable ou modification non autorisée.');
      }
    }
  }

  /// Supprime une catégorie vide appartenant à l'entreprise active.
  Future<void> deleteCategory(String categoryId) async {
    final businessId = await _getAuthorizedBusinessId();

    final products = await _client
        .from('products')
        .select('id')
        .eq('business_id', businessId)
        .eq('category_id', categoryId)
        .limit(1);

    if ((products as List).isNotEmpty) {
      throw Exception(
        'Cette catégorie contient des produits et ne peut pas être supprimée.',
      );
    }

    final response = await _client
        .from('categories')
        .delete()
        .eq('id', categoryId)
        .eq('business_id', businessId)
        .select('id');

    if ((response as List).isEmpty) {
      throw Exception('Catégorie introuvable ou suppression non autorisée.');
    }
  }
}
