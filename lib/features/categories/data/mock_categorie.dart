class StockCategory {
  final String id;
  final String name;
  final String description;
  final int productCount;

  const StockCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.productCount,
  });

  StockCategory copyWith({
    String? name,
    String? description,
    int? productCount,
  }) {
    return StockCategory(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      productCount: productCount ?? this.productCount,
    );
  }
}

const mockCategories = <StockCategory>[
  StockCategory(
    id: '1',
    name: 'Informatique',
    description: 'Ordinateurs, écrans et périphériques',
    productCount: 3,
  ),
  StockCategory(
    id: '2',
    name: 'Accessoires',
    description: 'Chargeurs, câbles et accessoires',
    productCount: 2,
  ),
  StockCategory(
    id: '3',
    name: 'Bureau',
    description: 'Équipements et fournitures de bureau',
    productCount: 1,
  ),
  StockCategory(
    id: '4',
    name: 'Autres',
    description: 'Produits divers',
    productCount: 0,
  ),
];
