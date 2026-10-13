import 'package:flutter/material.dart';

import '../../../data/stock_store.dart';
import '../data/mock_product.dart';

const _red = Color(0xFFF21D3D);
const _navy = Color(0xFF14264B);
const _muted = Color(0xFF7B8498);
const _border = Color(0xFFE9ECF3);
const _background = Color(0xFFF7F8FC);

class ProductsPage extends StatefulWidget {
  final String? initialCategory;
  const ProductsPage({super.key, this.initialCategory});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String search = '';
  String categoryFilter = 'Toutes';
  String statusFilter = 'Tous';

  List<String> get categories =>
      StockStore.instance.categories.map((category) => category.name).toList();

  final StockStore store = StockStore.instance;

  List<StockProduct> get products => store.products;

  @override
  void initState() {
    super.initState();

    if (widget.initialCategory != null &&
        StockStore.instance.categories.any(
          (category) => category.name == widget.initialCategory,
        )) {
      categoryFilter = widget.initialCategory!;
    }

    store.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(_onStoreChanged);
    super.dispose();
  }

  List<StockProduct> get filteredProducts {
    return products.where((product) {
      final query = search.trim().toLowerCase();

      final matchesSearch =
          product.name.toLowerCase().contains(query) ||
          product.reference.toLowerCase().contains(query);

      final matchesCategory =
          categoryFilter == 'Toutes' || product.category == categoryFilter;

      final matchesStatus =
          statusFilter == 'Tous' || product.stockStatus == statusFilter;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  Future<void> openProductForm({StockProduct? product}) async {
    final result = await showDialog<StockProduct>(
      context: context,
      builder: (_) =>
          _ProductFormDialog(product: product, categories: categories),
    );

    if (result == null || !mounted) return;

    store.saveProduct(result);
  }

  Future<void> deleteProduct(StockProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le produit ?'),
        content: Text('Voulez-vous vraiment supprimer « ${product.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      store.removeProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = filteredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestion des produits',
          style: TextStyle(
            color: _navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Consultez, recherchez et gérez les produits de votre stock.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 22),

        // Indicateurs
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 600 ? 2 : 4;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

            final stats = [
              (
                'Total produits',
                '${products.length}',
                Icons.inventory_2_outlined,
              ),
              (
                'Disponibles',
                '${products.where((p) => p.stockStatus == 'Disponible').length}',
                Icons.check_circle_outline,
              ),
              (
                'Stock faible',
                '${products.where((p) => p.stockStatus == 'Stock faible').length}',
                Icons.trending_down_rounded,
              ),
              (
                'En rupture',
                '${products.where((p) => p.stockStatus == 'Rupture').length}',
                Icons.warning_amber_rounded,
              ),
            ];

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats.map((stat) {
                return SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(stat.$3, color: _red, size: 21),
                        const SizedBox(height: 12),
                        Text(
                          stat.$2,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat.$1,
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 22),

        // Recherche et filtres
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;

              final searchField = TextField(
                onChanged: (value) => setState(() => search = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit ou une référence...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: _background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              );

              final categoryDropdown = DropdownButtonFormField<String>(
                value: categoryFilter,
                isExpanded: true,
                decoration: _filterDecoration('Catégorie'),
                items: ['Toutes', ...categories].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => categoryFilter = value);
                  }
                },
              );

              final statusDropdown = DropdownButtonFormField<String>(
                value: statusFilter,
                isExpanded: true,
                decoration: _filterDecoration('État du stock'),
                items: ['Tous', 'Disponible', 'Stock faible', 'Rupture'].map((
                  value,
                ) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => statusFilter = value);
                  }
                },
              );

              if (compact) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    categoryDropdown,
                    const SizedBox(height: 12),
                    statusDropdown,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: searchField),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: categoryDropdown),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: statusDropdown),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // En-tête du tableau
        Row(
          children: [
            const Expanded(
              child: Text(
                'Liste des produits',
                style: TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${visible.length} résultat(s)',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => openProductForm(),
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tableau adaptatif : défilement horizontal sur petit écran.
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: visible.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child: Text(
                      'Aucun produit ne correspond à votre recherche.',
                      style: TextStyle(color: _muted),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(_background),
                    columnSpacing: 28,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(label: Text('PRODUIT')),
                      DataColumn(label: Text('RÉFÉRENCE')),
                      DataColumn(label: Text('CATÉGORIE')),
                      DataColumn(label: Text('PRIX')),
                      DataColumn(label: Text('QUANTITÉ')),
                      DataColumn(label: Text('ÉTAT')),
                      DataColumn(label: Text('ACTIONS')),
                    ],
                    rows: visible.map((product) {
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 155,
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(product.reference)),
                          DataCell(Text(product.category)),
                          DataCell(
                            Text('${product.price.toStringAsFixed(2)} DT'),
                          ),
                          DataCell(Text('${product.quantity} unités')),
                          DataCell(_StatusBadge(status: product.stockStatus)),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Modifier',
                                  onPressed: () =>
                                      openProductForm(product: product),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 19,
                                    color: Color(0xFF4778F5),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Supprimer',
                                  onPressed: () => deleteProduct(product),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 19,
                                    color: _red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}

InputDecoration _filterDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'Disponible'
        ? const Color(0xFF14A579)
        : status == 'Stock faible'
        ? const Color(0xFFE9A23B)
        : _red;

    final background = status == 'Disponible'
        ? const Color(0xFFE4F8F0)
        : status == 'Stock faible'
        ? const Color(0xFFFFF3DF)
        : const Color(0xFFFFE8EC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  final StockProduct? product;
  final List<String> categories;

  const _ProductFormDialog({this.product, required this.categories});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController referenceController;
  late final TextEditingController priceController;
  late final TextEditingController quantityController;
  late final TextEditingController minimumController;

  late String category;

  @override
  void initState() {
    super.initState();

    final product = widget.product;
    nameController = TextEditingController(text: product?.name ?? '');
    referenceController = TextEditingController(text: product?.reference ?? '');
    priceController = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    quantityController = TextEditingController(
      text: product == null ? '0' : '${product.quantity}',
    );
    minimumController = TextEditingController(
      text: product == null ? '5' : '${product.minimumQuantity}',
    );
    category = product?.category ?? widget.categories.first;
  }

  @override
  void dispose() {
    nameController.dispose();
    referenceController.dispose();
    priceController.dispose();
    quantityController.dispose();
    minimumController.dispose();
    super.dispose();
  }

  String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire';
    }
    return null;
  }

  String? validateNumber(String? value, {bool integer = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire';
    }

    final parsed = integer ? int.tryParse(value) : double.tryParse(value);
    if (parsed == null || parsed < 0) {
      return 'Entrez une valeur valide';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.product == null ? 'Ajouter un produit' : 'Modifier le produit',
        style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  nameController,
                  'Nom du produit',
                  validator: requiredText,
                ),
                const SizedBox(height: 12),
                _field(
                  referenceController,
                  'Référence',
                  validator: requiredText,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  isExpanded: true,
                  decoration: _filterDecoration('Catégorie'),
                  items: widget.categories.map((value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => category = value);
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  priceController,
                  'Prix de vente (DT)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => validateNumber(value),
                ),
                const SizedBox(height: 12),
                _field(
                  quantityController,
                  'Quantité en stock',
                  keyboardType: TextInputType.number,
                  validator: (value) => validateNumber(value, integer: true),
                ),
                const SizedBox(height: 12),
                _field(
                  minimumController,
                  'Seuil minimum de stock',
                  keyboardType: TextInputType.number,
                  validator: (value) => validateNumber(value, integer: true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _red),
          onPressed: () {
            if (!formKey.currentState!.validate()) return;

            final old = widget.product;
            final product = StockProduct(
              id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
              name: nameController.text.trim(),
              reference: referenceController.text.trim(),
              category: category,
              price: double.parse(priceController.text.trim()),
              quantity: int.parse(quantityController.text.trim()),
              minimumQuantity: int.parse(minimumController.text.trim()),
            );

            Navigator.pop(context, product);
          },
          child: Text(widget.product == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _filterDecoration(label),
    );
  }
}
