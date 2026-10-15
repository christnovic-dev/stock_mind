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
