import 'package:supabase_flutter/supabase_flutter.dart';

class VenteService {
  VenteService({required this.businessId, SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final String businessId;
  final SupabaseClient _client;

  Future<Map<String, dynamic>> checkout({
    required String customerName,
    required String customerPhone,
    required String customerCity,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final id = businessId.trim();

    if (id.isEmpty) {
      throw Exception('Aucune entreprise sélectionnée.');
    }

    if (_client.auth.currentUser == null) {
      throw Exception('Vous devez être connecté.');
    }

    if (items.isEmpty) {
      throw Exception('Le panier est vide.');
    }

    final payload = items.map((item) {
      return <String, dynamic>{
        'product_id': item['product_id'].toString(),
        'quantity': item['quantity'] as int,
      };
    }).toList();

    final response = await _client.rpc(
      'checkout_sale',
      params: {
        'p_business_id': id,
        'p_customer_name': customerName.trim().isEmpty
            ? 'Client comptant'
            : customerName.trim(),
        'p_customer_phone': customerPhone.trim(),
        'p_customer_city': customerCity.trim(),
        'p_payment_method': paymentMethod,
        'p_items': payload,
      },
    );

    if (response == null) {
      throw Exception('La vente n’a retourné aucun résultat.');
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception('Réponse inattendue du serveur.');
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    final id = businessId.trim();

    if (id.isEmpty) {
      throw Exception('Aucune entreprise sélectionnée.');
    }

    final rows = await _client
        .from('sales')
        .select(
          'id, sale_number, customer_name, customer_phone, '
          'customer_city, payment_method, total_amount, status, created_at',
        )
        .eq('business_id', id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getSaleItems(String saleId) async {
    final rows = await _client
        .from('sale_items')
        .select('product_id, product_name, quantity, unit_price, subtotal')
        .eq('sale_id', saleId);

    return List<Map<String, dynamic>>.from(rows);
  }
}
