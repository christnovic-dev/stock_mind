import 'package:supabase_flutter/supabase_flutter.dart';

class BoutiqueService {
  BoutiqueService({SupabaseClient? client, required String businessId})
    : _client = client ?? Supabase.instance.client,
      _businessId = businessId;

  final SupabaseClient _client;
  final String _businessId;

  /// Récupère les informations de la boutique
  /// correspondant à l'entreprise sélectionnée.
  Future<Map<String, dynamic>> getBoutique() async {
    if (_businessId.trim().isEmpty) {
      throw Exception('Aucune entreprise sélectionnée.');
    }

    final result = await _client
        .from('businesses')
        .select(
          'id, name, phone, city, address, shop_name, '
          'slug, logo_url, brand_color, description',
        )
        .eq('id', _businessId)
        .single();

    return Map<String, dynamic>.from(result);
  }

  /// Enregistre les informations de la boutique.
  Future<void> saveBoutique({
    required String shopName,
    required String description,
    required String phone,
    required String address,
  }) async {
    if (_businessId.trim().isEmpty) {
      throw Exception('Aucune entreprise sélectionnée.');
    }

    final normalizedName = shopName.trim();

    if (normalizedName.isEmpty) {
      throw Exception('Le nom de la boutique est obligatoire.');
    }

    final slug = _slugify(normalizedName);

    // Vérifie que le lien n'est pas utilisé par une autre entreprise.
    final existing = await _client
        .from('businesses')
        .select('id')
        .eq('slug', slug)
        .neq('id', _businessId)
        .limit(1);

    if ((existing as List).isNotEmpty) {
      throw Exception(
        'Ce nom génère un lien déjà utilisé. '
        'Choisissez un autre nom.',
      );
    }

    await _client
        .from('businesses')
        .update({
          'shop_name': normalizedName,
          'description': description.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'slug': slug,
        })
        .eq('id', _businessId);
  }

  /// Transforme le nom en identifiant utilisable dans une URL.
  String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return slug.isEmpty ? 'ma-boutique' : slug;
  }
}
