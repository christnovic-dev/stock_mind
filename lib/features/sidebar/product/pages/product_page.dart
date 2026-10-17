import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

import '../data/mock_product.dart';
import '../services/product_services.dart';

class ProductsPage extends StatefulWidget {
  final String businessId;
  final String? initialCategory;

  const ProductsPage({
    super.key,
    required this.businessId,
    this.initialCategory,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final ProductService productService;

  String search = '';
  String categoryFilter = 'Toutes';
  String statusFilter = 'Tous';

  List<StockProduct> products = [];
  List<Map<String, dynamic>> categoryRows = [];

  bool isLoading = true;
  String? loadError;

  List<String> get categories => [
    'Sans catégorie',
    ...categoryRows.map((c) => c['name'] as String),
  ];

  @override
  void initState() {
    super.initState();

    productService = ProductService(businessId: widget.businessId);

    if (widget.initialCategory != null) {
      categoryFilter = widget.initialCategory!;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final loadedCategories = await productService.getCategories();

      final loadedProducts = await productService.getProducts();

      if (!mounted) return;

      setState(() {
        categoryRows = loadedCategories;
        products = loadedProducts;

        if (widget.initialCategory != null &&
            categories.contains(widget.initialCategory)) {
          categoryFilter = widget.initialCategory!;
        } else if (!categories.contains(categoryFilter)) {
          categoryFilter = 'Toutes';
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = e.toString();
      });
    }
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
    final result = await showDialog<_ProductFormResult>(
      context: context,
      builder: (_) =>
          _ProductFormDialog(product: product, categories: categories),
    );

    if (result == null || !mounted) return;

    try {
      await productService.saveProduct(
        result.product,
        categoryName: result.product.category,
        imageFile: result.imageFile,
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit enregistré avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’enregistrement : $e')),
      );
    }
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await productService.deleteProduct(product.id);

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: AppColors.muted,
              ),
              const SizedBox(height: 12),
              const Text(
                'Impossible de charger les produits.',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final visible = filteredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestion des produits',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Consultez, recherchez et gérez les produits de votre stock.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
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
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(stat.$3, color: AppColors.primary, size: 21),
                        const SizedBox(height: 12),
                        Text(
                          stat.$2,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat.$1,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
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
            border: Border.all(color: AppColors.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;

              final searchField = TextField(
                onChanged: (value) {
                  setState(() => search = value);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit ou une référence...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.background,
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
                items: ['Toutes', ...categories].toSet().map((value) {
                  return DropdownMenuItem<String>(
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
                  return DropdownMenuItem<String>(
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
                  color: AppColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${visible.length} résultat(s)',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => openProductForm(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
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

        // Tableau des produits
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: visible.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child: Text(
                      'Aucun produit ne correspond à votre recherche.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.background,
                    ),
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
                              width: 185,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      color: AppColors.background,
                                      child:
                                          product.imageUrl != null &&
                                              product.imageUrl!.isNotEmpty
                                          ? Image.network(
                                              product.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.inventory_2_outlined,
                                                    color: AppColors.muted,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.inventory_2_outlined,
                                              color: AppColors.muted,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
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
                                    color: AppColors.primary,
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
    fillColor: AppColors.background,
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
        : AppColors.primary;

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

class _ProductFormResult {
  final StockProduct product;
  final XFile? imageFile;

  const _ProductFormResult({required this.product, this.imageFile});
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

  final ImagePicker _imagePicker = ImagePicker();

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  bool isPickingImage = false;

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

    category = widget.categories.contains(product?.category)
        ? product!.category
        : 'Sans catégorie';
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

    final normalized = value.trim().replaceAll(',', '.');

    if (integer && normalized.contains('.')) {
      return 'Entrez un nombre entier';
    }

    final num? parsed = integer
        ? int.tryParse(normalized)
        : double.tryParse(normalized);

    if (parsed == null || parsed < 0) {
      return 'Entrez une valeur valide';
    }

    return null;
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage = image;
        selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de sélectionner l’image : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.product == null ? 'Ajouter un produit' : 'Modifier le produit',
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Photo du produit',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 130,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: selectedImageBytes != null
                            ? Image.memory(
                                selectedImageBytes!,
                                fit: BoxFit.contain,
                              )
                            : (widget.product?.imageUrl != null &&
                                  widget.product!.imageUrl!.isNotEmpty)
                            ? Image.network(
                                widget.product!.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 40,
                                  color: AppColors.muted,
                                ),
                              )
                            : const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 42,
                                color: AppColors.muted,
                              ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_file_rounded),
                        label: Text(
                          selectedImage == null
                              ? (widget.product?.imageUrl == null
                                    ? 'Choisir une image'
                                    : 'Remplacer l’image')
                              : 'Changer l’image',
                        ),
                      ),
                      if (selectedImage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          selectedImage!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                  items: widget.categories.toSet().map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => category = value);
                    }
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
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            if (!formKey.currentState!.validate()) return;

            final old = widget.product;

            final product = StockProduct(
              id: old?.id ?? '',
              name: nameController.text.trim(),
              reference: referenceController.text.trim(),
              category: category,
              price: double.parse(
                priceController.text.trim().replaceAll(',', '.'),
              ),
              quantity: int.parse(quantityController.text.trim()),
              minimumQuantity: int.parse(minimumController.text.trim()),
              imageUrl: old?.imageUrl,
            );

            Navigator.pop(
              context,
              _ProductFormResult(product: product, imageFile: selectedImage),
            );
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
