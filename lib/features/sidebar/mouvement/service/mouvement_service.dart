import 'package:supabase_flutter/supabase_flutter.dart';

/// Produit disponible pour les formulaires de mouvements.
class MovementProduct {
  final String id;
  final String name;
  final int quantity;

  const MovementProduct({
    required this.id,
    required this.name,
    required this.quantity,
  });

  factory MovementProduct.fromMap(Map<String, dynamic> map) {
    return MovementProduct(
      id: map['id'].toString(),
      name: (map['name'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Modèle d'un mouvement de stock.
class StockMovement {
  final String id;
  final String? productId;
  final String product;
  final String type;
  final int quantity;
  final String reason;
  final String? counterpartyType;
  final String? counterpartyName;
  final String? counterpartyCity;
  final String? counterpartyPhone;
  final String? confirmedByName;
  final DateTime date;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.product,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.counterpartyType,
    required this.counterpartyName,
    required this.counterpartyCity,
    required this.counterpartyPhone,
    required this.confirmedByName,
    required this.date,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    final rawDate = map['confirmed_at'] ?? map['created_at'];

    return StockMovement(
      id: map['id'].toString(),
      productId: map['product_id']?.toString(),
      product: (map['product_name'] ?? 'Produit supprimé').toString(),
      type: (map['movement_type'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      reason: (map['reason'] ?? '').toString(),
      counterpartyType: map['counterparty_type']?.toString(),
      counterpartyName: map['counterparty_name']?.toString(),
      counterpartyCity: map['counterparty_city']?.toString(),
      counterpartyPhone: map['counterparty_phone']?.toString(),
      confirmedByName: map['confirmed_by_name']?.toString(),
      date: rawDate != null
          ? DateTime.parse(rawDate.toString()).toLocal()
          : DateTime.now(),
    );
  }
}

class MovementService {
  MovementService({required String businessId, SupabaseClient? client})
    : _businessId = businessId.trim(),
      _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final String _businessId;

  /// Vérifie la connexion et l'accès à l'entreprise sélectionnée.
  Future<String> _getBusinessId() async {
    if (_businessId.isEmpty) {
      throw Exception('Aucune entreprise sélectionnée.');
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Vous devez être connecté.');
    }

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

  /// Récupère les produits de l'entreprise active.
  Future<List<MovementProduct>> getProducts() async {
    final businessId = await _getBusinessId();

    final response = await _client
        .from('products')
        .select('id, name, quantity')
        .eq('business_id', businessId)
        .order('name', ascending: true);

    return (response as List)
        .map(
          (item) =>
              MovementProduct.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  /// Récupère les mouvements, téléphone compris.
  Future<List<StockMovement>> getMovements() async {
    final businessId = await _getBusinessId();

    final response = await _client
        .from('stock_movements')
        .select(
          'id, business_id, product_id, product_name, '
          'movement_type, quantity, reason, '
          'counterparty_type, counterparty_name, '
          'counterparty_city, counterparty_phone, '
          'confirmed_by_name, confirmed_at, created_at',
        )
        .eq('business_id', businessId)
        .order('confirmed_at', ascending: false);

    return (response as List)
        .map(
          (item) =>
              StockMovement.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  /// Crée un mouvement via PostgreSQL.
  ///
  /// La fonction SQL met à jour le stock, enregistre le mouvement
  /// et synchronise le contact correspondant dans la même transaction.
  Future<String> createMovement({
    required String productId,
    required String movementType,
    required int quantity,
    required String reason,
    String? counterpartyType,
    String? counterpartyName,
    String? counterpartyCity,
    String? counterpartyPhone,
    String? adjustmentDirection,
  }) async {
    final businessId = await _getBusinessId();

    if (productId.trim().isEmpty) {
      throw Exception('Veuillez sélectionner un produit.');
    }

    if (quantity <= 0) {
      throw Exception('La quantité doit être supérieure à zéro.');
    }

    const validTypes = ['entree', 'sortie', 'ajustement'];

    if (!validTypes.contains(movementType)) {
      throw Exception('Type de mouvement invalide.');
    }

    if (reason.trim().isEmpty) {
      throw Exception('Veuillez saisir un motif.');
    }

    if (movementType == 'ajustement' &&
        !['entree', 'sortie'].contains(adjustmentDirection)) {
      throw Exception(
        'Pour un ajustement, choisissez augmentation ou diminution.',
      );
    }

    if (counterpartyType != null &&
        !['client', 'fournisseur', 'autre'].contains(counterpartyType)) {
      throw Exception('Type de tiers invalide.');
    }

    // Vérification préalable du produit dans l'entreprise active.
    final product = await _client
        .from('products')
        .select('id')
        .eq('id', productId)
        .eq('business_id', businessId)
        .maybeSingle();

    if (product == null) {
      throw Exception(
        'Le produit sélectionné n’appartient pas à cette entreprise.',
      );
    }

    // Appel du RPC : ne pas modifier le stock directement depuis Flutter.
    final response = await _client.rpc(
      'create_stock_movement',
      params: {
        'p_business_id': businessId,
        'p_product_id': productId,
        'p_movement_type': movementType,
        'p_quantity': quantity,
        'p_reason': reason.trim(),
        'p_counterparty_type': counterpartyType,
        'p_counterparty_name': counterpartyName?.trim(),
        'p_counterparty_city': counterpartyCity?.trim(),
        'p_counterparty_phone': counterpartyPhone?.trim(),
        'p_adjustment_direction': adjustmentDirection,
      },
    );

    if (response == null) {
      throw Exception('Aucun identifiant de mouvement n’a été retourné.');
    }

    return response.toString();
  }
}
