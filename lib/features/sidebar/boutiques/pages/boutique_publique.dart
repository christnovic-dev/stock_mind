import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

import '../../product/data/mock_product.dart';

class StorefrontPage extends StatefulWidget {
  final String storeName;
  final String description;

  const StorefrontPage({
    super.key,
    this.storeName = 'Ma boutique',
    this.description =
        'Découvrez nos produits et trouvez ce dont vous avez besoin.',
  });

  @override
  State<StorefrontPage> createState() => _StorefrontPageState();
}

class _StorefrontPageState extends State<StorefrontPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Tout';
  String _sort = 'recommended';
  final Map<String, int> _cart = {};

  List<String> get _categories {
    final categories =
        mockProducts.map((product) => product.category).toSet().toList()
          ..sort();

    return ['Tout', ...categories];
  }

  List<StockProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();

    final products = mockProducts.where((product) {
      final matchesCategory =
          _selectedCategory == 'Tout' || product.category == _selectedCategory;

      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.reference.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);

      // Les produits en rupture ne sont pas proposés à la vente.
      return matchesCategory && matchesSearch && product.quantity > 0;
    }).toList();

    if (_sort == 'price_asc') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sort == 'price_desc') {
      products.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sort == 'name') {
      products.sort((a, b) => a.name.compareTo(b.name));
    }

    return products;
  }

  int get _cartCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);

  double get _cartTotal {
    double total = 0;

    for (final entry in _cart.entries) {
      final product = mockProducts.firstWhere((p) => p.id == entry.key);
      total += product.price * entry.value;
    }

    return total;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(StockProduct product) {
    final currentQuantity = _cart[product.id] ?? 0;

    if (currentQuantity >= product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantité maximale disponible atteinte.')),
      );
      return;
    }

    setState(() {
      _cart[product.id] = currentQuantity + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ajouté au panier.'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _changeQuantity(StockProduct product, int delta) {
    final current = _cart[product.id] ?? 0;
    final next = current + delta;

    setState(() {
      if (next <= 0) {
        _cart.remove(product.id);
      } else if (next <= product.quantity) {
        _cart[product.id] = next;
      }
    });
  }

  void _showCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Le panier principal est géré par le parent.
            return Container(
              height: MediaQuery.of(context).size.height * .75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Mon panier',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 52,
                                  color: AppColors.muted,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Votre panier est vide.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              for (final entry in _cart.entries)
                                _buildCartItem(
                                  mockProducts.firstWhere(
                                    (p) => p.id == entry.key,
                                  ),
                                  entry.value,
                                  () {
                                    _changeQuantity(
                                      mockProducts.firstWhere(
                                        (p) => p.id == entry.key,
                                      ),
                                      -1,
                                    );
                                    setSheetState(() {});
                                  },
                                  () {
                                    _changeQuantity(
                                      mockProducts.firstWhere(
                                        (p) => p.id == entry.key,
                                      ),
                                      1,
                                    );
                                    setSheetState(() {});
                                  },
                                ),
                            ],
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total estimé',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_cartTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _cart.isEmpty
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    _showCheckout();
                                  },
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Continuer la commande'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE4E6EC),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartItem(
    StockProduct product,
    int quantity,
    VoidCallback onRemove,
    VoidCallback onAdd,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: AppColors.muted,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${product.price.toStringAsFixed(2)} × $quantity',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckout() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Finaliser la commande'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Renseignez vos coordonnées pour préparer '
                      'votre commande.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Entrez votre nom.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Entrez votre téléphone.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Adresse de livraison',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Entrez votre adresse.'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(dialogContext);

                showDialog<void>(
                  context: this.context,
                  builder: (context) => AlertDialog(
                    icon: const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 36,
                    ),
                    title: const Text('Démonstration uniquement'),
                    content: const Text(
                      'Vos coordonnées ont été saisies, mais aucune '
                      'commande n’a été enregistrée. La connexion '
                      'à une base de données sera nécessaire pour '
                      'transmettre la commande au commerçant.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Compris'),
                      ),
                    ],
                  ),
                );

                nameController.dispose();
                phoneController.dispose();
                addressController.dispose();
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTopBar()),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildSearchAndFilters()),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width >= 1100 ? 70 : 20,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCategory == 'Tout'
                          ? 'Nos produits'
                          : _selectedCategory,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${products.length} résultat${products.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (products.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 54,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aucun produit trouvé',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Essayez une autre recherche ou catégorie.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: width >= 1100 ? 70 : 20,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProductCard(products[index]),
                  childCount: products.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: width >= 1200
                      ? 4
                      : width >= 850
                      ? 3
                      : width >= 550
                      ? 2
                      : 1,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  mainAxisExtent: 335,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Center(
                child: Text(
                  '${widget.storeName} • Boutique propulsée par StockMind',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCart,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_cart_outlined),
        label: Text('Panier ($_cartCount)'),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Panier',
                onPressed: _showCart,
                icon: Badge(
                  isLabelVisible: _cartCount > 0,
                  label: Text('$_cartCount'),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: const Color(0xFFEFF2FA),
      padding: EdgeInsets.symmetric(
        horizontal: width >= 1100 ? 70 : 22,
        vertical: width < 550 ? 35 : 52,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'BIENVENUE DANS NOTRE BOUTIQUE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.storeName,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: width < 550 ? 30 : 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  widget.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF168653),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${mockProducts.where((p) => p.quantity > 0).length} produits disponibles',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit, une référence...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.muted,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in _categories)
                    ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                      selectedColor: const Color(0xFFFCE7EB),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: _selectedCategory == category
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: _selectedCategory == category
                            ? AppColors.primary
                            : AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sort,
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(
                        value: 'recommended',
                        child: Text('Tri : recommandé'),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text('Prix croissant'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Prix décroissant'),
                      ),
                      DropdownMenuItem(value: 'name', child: Text('Nom A–Z')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sort = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(StockProduct product) {
    final quantityInCart = _cart[product.id] ?? 0;
    final remaining = product.quantity - quantityInCart;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.background,
                  child: const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFFB6BECE),
                      size: 66,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: remaining > 0
                          ? const Color(0xFFE8F7EF)
                          : const Color(0xFFFCE7EB),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      remaining > 0 ? 'Disponible' : 'Indisponible',
                      style: TextStyle(
                        color: remaining > 0
                            ? const Color(0xFF168653)
                            : AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Réf. ${product.reference}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.price.toStringAsFixed(2),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: remaining > 0
                            ? () => _addToCart(product)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE4E6EC),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
