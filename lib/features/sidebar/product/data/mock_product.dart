class StockProduct {
  final String id;
  final String name;
  final String reference;
  final String category;
  final double price;
  final int quantity;
  final int minimumQuantity;
  final String? imageUrl;

  const StockProduct({
    required this.id,
    required this.name,
    required this.reference,
    required this.category,
    required this.price,
    required this.quantity,
    required this.minimumQuantity,
    this.imageUrl,
  });

  StockProduct copyWith({
    String? name,
    String? reference,
    String? category,
    double? price,
    int? quantity,
    int? minimumQuantity,
    String? imageUrl,
  }) {
    return StockProduct(
      id: id,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String get stockStatus {
    if (quantity == 0) return 'Rupture';
    if (quantity <= minimumQuantity) return 'Stock faible';
    return 'Disponible';
  }
}
