import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/mock_product.dart';

class ProductService {
  ProductService({SupabaseClient? client, String? businessId})
    : _client = client ?? Supabase.instance.client,
      _businessId = businessId;

  final SupabaseClient _client;
  final String? _businessId;

  static const String _bucket = 'product-images';

  /// Vérifie que l'utilisateur connecté est membre de l'entreprise.
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

  Future<List<Map<String, dynamic>>> getCategories() async {
    final businessId = await getBusinessId();

    final rows = await _client
        .from('categories')
        .select('id, name')
        .eq('business_id', businessId)
        .order('name');

    return List<Map<String, dynamic>>.from(rows);
  }

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
        imageUrl: row['image_url'] as String?,
      );
    }).toList();
  }

  /// Crée ou modifie le produit, puis enregistre son image si fournie.
  ///
  /// La fonction SQL existante reste responsable du stock et de l'audit.
  Future<String> saveProduct(
    StockProduct product, {
    required String categoryName,
    XFile? imageFile,
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

    final existingId = product.id.trim().isEmpty ? null : product.id.trim();

    final result = await _client.rpc(
      'save_product_with_stock_movement',
      params: {
        'p_business_id': businessId,
        'p_product_id': existingId,
        'p_category_id': categoryId,
        'p_name': product.name.trim(),
        'p_reference': product.reference.trim(),
        'p_price': product.price,
        'p_quantity': product.quantity,
        'p_minimum_quantity': product.minimumQuantity,
      },
    );

    final productId = result.toString();

    if (productId.isEmpty || productId == 'null') {
      throw Exception(
        'La sauvegarde du produit n’a retourné aucun identifiant.',
      );
    }

    if (imageFile != null) {
      await _uploadProductImage(
        businessId: businessId,
        productId: productId,
        imageFile: imageFile,
      );
    }

    return productId;
  }

  Future<void> _uploadProductImage({
    required String businessId,
    required String productId,
    required XFile imageFile,
  }) async {
    final bytes = await imageFile.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('Le fichier image est vide.');
    }

    final fileName = imageFile.name.toLowerCase();

    final contentType =
        imageFile.mimeType ??
        (fileName.endsWith('.png')
            ? 'image/png'
            : fileName.endsWith('.webp')
            ? 'image/webp'
            : fileName.endsWith('.gif')
            ? 'image/gif'
            : fileName.endsWith('.avif')
            ? 'image/avif'
            : 'image/jpeg');

    // Un chemin stable permet de remplacer l'image sans multiplier
    // les fichiers pour le même produit.
    final storagePath = '$businessId/$productId/image';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );

    final imageUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);

    await _client.rpc(
      'set_product_image_url',
      params: {
        'p_business_id': businessId,
        'p_product_id': productId,
        'p_image_url': imageUrl,
      },
    );
  }

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
