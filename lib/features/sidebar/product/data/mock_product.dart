class StockProduct {
  final String id;
  final String name;
  final String reference;
  final String category;
  final double price;
  final int quantity;
  final int minimumQuantity;

  const StockProduct({
    required this.id,
    required this.name,
    required this.reference,
    required this.category,
    required this.price,
    required this.quantity,
    required this.minimumQuantity,
  });

  StockProduct copyWith({
    String? name,
    String? reference,
    String? category,
    double? price,
    int? quantity,
    int? minimumQuantity,
  }) {
    return StockProduct(
      id: id,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
    );
  }

  String get stockStatus {
    if (quantity == 0) return 'Rupture';
    if (quantity <= minimumQuantity) return 'Stock faible';
    return 'Disponible';
  }
}

const mockProducts = <StockProduct>[
  StockProduct(
    id: '1',
    name: 'Casque Bluetooth',
    reference: 'ACC-024',
    category: 'Accessoires',
    price: 85,
    quantity: 3,
    minimumQuantity: 10,
  ),
  StockProduct(
    id: '2',
    name: 'Chargeur USB-C',
    reference: 'ACC-018',
    category: 'Accessoires',
    price: 35,
    quantity: 25,
    minimumQuantity: 10,
  ),
  StockProduct(
    id: '3',
    name: 'Souris sans fil',
    reference: 'INF-009',
    category: 'Informatique',
    price: 48,
    quantity: 2,
    minimumQuantity: 8,
  ),
  StockProduct(
    id: '4',
    name: 'Clavier mécanique',
    reference: 'INF-014',
    category: 'Informatique',
    price: 150,
    quantity: 0,
    minimumQuantity: 5,
  ),
  StockProduct(
    id: '5',
    name: 'Support ordinateur',
    reference: 'BUR-005',
    category: 'Bureau',
    price: 65,
    quantity: 18,
    minimumQuantity: 5,
  ),
  StockProduct(
    id: '6',
    name: 'Écran 24 pouces',
    reference: 'INF-021',
    category: 'Informatique',
    price: 520,
    quantity: 7,
    minimumQuantity: 3,
  ),
];
