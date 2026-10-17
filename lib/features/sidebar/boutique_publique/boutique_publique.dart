import 'package:flutter/material.dart';
import 'package:stockmind/features/sidebar/boutique_publique/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);
const Color _green = Color(0xFF159B72);
const Color _orange = Color(0xFFE99A28);

class StorefrontPage extends StatefulWidget {
  final String storeSlug;
  final String storeName;
  final String description;

  const StorefrontPage({
    super.key,
    required this.storeSlug,
    this.storeName = 'Ma boutique',
    this.description =
        'Découvrez nos produits et trouvez ce dont vous avez besoin.',
  });

  @override
  State<StorefrontPage> createState() => _StorefrontPageState();
}

class _StorefrontPageState extends State<StorefrontPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _store;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];

  final Map<String, int> _cart = {};

  bool _loading = true;
  bool _loadFailed = false;
  String _errorMessage = '';

  String _search = '';
  String _selectedCategory = 'Tous';
  String _sortBy = 'name';

  final GlobalKey _productsSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _displayName {
    final name = _store?['shop_name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final fallback = _store?['name']?.toString().trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;

    return widget.storeName;
  }

  String get _description {
    final value = _store?['description']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;

    return widget.description;
  }

  String _money(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    return amount.toStringAsFixed(2);
  }

  int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadStore() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
        _errorMessage = '';
      });
    }

    try {
      final storeResult = await _supabase
          .from('businesses')
          .select(
            'id, name, shop_name, description, slug, phone, '
            'city, address, logo_url, brand_color',
          )
          .eq('slug', widget.storeSlug)
          .maybeSingle();

      if (storeResult == null) {
        throw Exception('Cette boutique est introuvable.');
      }

      final store = Map<String, dynamic>.from(storeResult);
      final businessId = store['id']?.toString();

      if (businessId == null || businessId.isEmpty) {
        throw Exception('Identifiant de boutique invalide.');
      }

      final productResult = await _supabase
          .from('products')
          .select(
            'id, business_id, category_id, name, reference, '
            'price, quantity, minimum_quantity, image_url',
          )
          .eq('business_id', businessId)
          .order('name');

      final products = List<Map<String, dynamic>>.from(productResult);

      final categoryResult = await _supabase
          .from('categories')
          .select('id, name')
          .eq('business_id', businessId)
          .order('name');

      final categories = List<Map<String, dynamic>>.from(categoryResult);

      if (!mounted) return;

      setState(() {
        _store = store;
        _products = products;
        _categories = categories;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadFailed = true;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('introuvable')) {
      return 'Cette boutique n’existe pas ou son lien est incorrect.';
    }

    if (message.contains('SocketException') ||
        message.contains('Failed host lookup')) {
      return 'Connexion impossible. Vérifiez votre connexion Internet.';
    }

    return 'Impossible de charger cette boutique. Vérifiez les '
        'autorisations Supabase et réessayez.';
  }

  Map<String, dynamic>? _findProduct(String id) {
    for (final product in _products) {
      if (product['id']?.toString() == id) return product;
    }
    return null;
  }

  String _categoryName(dynamic categoryId) {
    if (categoryId == null) return 'Sans catégorie';

    for (final category in _categories) {
      if (category['id']?.toString() == categoryId.toString()) {
        return category['name']?.toString() ?? 'Sans catégorie';
      }
    }

    return 'Sans catégorie';
  }

  List<String> get _categoryNames {
    final names = _categories
        .map((category) => category['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    names.sort();
    return ['Tous', ...names];
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final query = _search.trim().toLowerCase();

    final result = _products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final reference = product['reference']?.toString().toLowerCase() ?? '';
      final category = _categoryName(product['category_id']);

      final matchesSearch =
          query.isEmpty ||
          name.contains(query) ||
          reference.contains(query) ||
          category.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'Tous' || category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortBy) {
      case 'price_asc':
        result.sort(
          (a, b) =>
              _doubleValue(a['price']).compareTo(_doubleValue(b['price'])),
        );
        break;
      case 'price_desc':
        result.sort(
          (a, b) =>
              _doubleValue(b['price']).compareTo(_doubleValue(a['price'])),
        );
        break;
      case 'stock':
        result.sort(
          (a, b) =>
              _intValue(a['quantity']).compareTo(_intValue(b['quantity'])),
        );
        break;
      default:
        result.sort(
          (a, b) => (a['name']?.toString() ?? '').compareTo(
            b['name']?.toString() ?? '',
          ),
        );
    }

    return result;
  }

  int get _cartCount =>
      _cart.values.fold(0, (total, quantity) => total + quantity);

  double get _cartTotal {
    double total = 0;

    for (final entry in _cart.entries) {
      final product = _findProduct(entry.key);
      if (product == null) continue;

      total += _doubleValue(product['price']) * entry.value;
    }

    return total;
  }

  void _addToCart(Map<String, dynamic> product) {
    final id = product['id']?.toString();
    if (id == null) return;

    final stock = _intValue(product['quantity']);
    final currentQuantity = _cart[id] ?? 0;

    if (stock <= currentQuantity) {
      _showMessage(
        stock <= 0
            ? 'Ce produit est en rupture de stock.'
            : 'La quantité disponible est limitée au stock actuel.',
      );
      return;
    }

    setState(() {
      _cart[id] = currentQuantity + 1;
    });

    _showMessage('Produit ajouté au panier.');
  }

  void _changeCartQuantity(String id, int change) {
    final currentQuantity = _cart[id] ?? 0;
    final nextQuantity = currentQuantity + change;
    final product = _findProduct(id);

    if (nextQuantity <= 0) {
      setState(() => _cart.remove(id));
      return;
    }

    if (product == null) {
      setState(() => _cart.remove(id));
      return;
    }

    if (nextQuantity > _intValue(product['quantity'])) {
      _showMessage('Stock disponible insuffisant.');
      return;
    }

    setState(() {
      _cart[id] = nextQuantity;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _openCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, refreshSheet) {
            final entries = _cart.entries.toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mon panier',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 21,
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
                  const SizedBox(height: 12),
                  Flexible(
                    child: entries.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 50,
                                  color: _muted,
                                ),
                                SizedBox(height: 12),
                                Text('Votre panier est vide.'),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              final product = _findProduct(entry.key);

                              if (product == null) {
                                return const SizedBox.shrink();
                              }

                              final quantity = entry.value;
                              final price = _doubleValue(product['price']);

                              return Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      (product['image_url']
                                                  ?.toString()
                                                  .trim()
                                                  .isNotEmpty ??
                                              false)
                                          ? product['image_url']
                                                .toString()
                                                .trim()
                                          : '',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: _background,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: _red,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name']?.toString() ??
                                              'Produit',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: _navy,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_money(price * quantity)}',
                                          style: const TextStyle(
                                            color: _red,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _changeCartQuantity(entry.key, -1);
                                      refreshSheet(() {});
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _changeCartQuantity(entry.key, 1);
                                      refreshSheet(() {});
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total estimé',
                          style: TextStyle(fontSize: 15, color: _muted),
                        ),
                      ),
                      Text(
                        _money(_cartTotal),
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _cart.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
                              _showCheckout();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _border,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Passer la commande',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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

  Future<void> _showCheckout() async {
    if (_cart.isEmpty) {
      _showMessage('Votre panier est vide.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();

    bool sending = false;
    String? submitError;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, refreshDialog) {
              return AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                title: const Text(
                  'Finaliser la commande',
                  style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
                ),
                content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Renseignez vos coordonnées pour que '
                              'la boutique puisse vous contacter.',
                              style: TextStyle(color: _muted, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _checkoutField(
                            controller: nameController,
                            label: 'Nom complet',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _checkoutField(
                            controller: phoneController,
                            label: 'Téléphone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _checkoutField(
                            controller: addressController,
                            label: 'Adresse de livraison',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 12),
                          _checkoutField(
                            controller: cityController,
                            label: 'Ville',
                            icon: Icons.location_city_outlined,
                          ),
                          if (submitError != null) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                submitError!,
                                style: const TextStyle(
                                  color: _red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _background,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Total de la commande',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  _money(_cartTotal),
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: sending
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: sending
                        ? null
                        : () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }

                            refreshDialog(() {
                              sending = true;
                              submitError = null;
                            });

                            try {
                              final items = _cart.entries
                                  .map(
                                    (entry) => {
                                      'product_id': entry.key,
                                      'quantity': entry.value,
                                    },
                                  )
                                  .toList();

                              final orderId = await _supabase.rpc(
                                'create_public_store_order',
                                params: {
                                  'p_store_slug': widget.storeSlug,
                                  'p_customer_name': nameController.text.trim(),
                                  'p_customer_phone': phoneController.text
                                      .trim(),
                                  'p_customer_address': addressController.text
                                      .trim(),
                                  'p_customer_city': cityController.text.trim(),
                                  'p_items': items,
                                },
                              );

                              if (!mounted) return;

                              setState(() {
                                _cart.clear();
                              });

                              Navigator.pop(dialogContext);

                              await _showOrderSuccess(
                                orderId?.toString() ?? '',
                              );

                              await _loadStore();
                            } catch (error) {
                              refreshDialog(() {
                                sending = false;
                                submitError = _friendlyOrderError(error);
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirmer'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      addressController.dispose();
      cityController.dispose();
    }
  }

  String _friendlyOrderError(Object error) {
    final message = error.toString();

    if (message.contains('Stock insuffisant')) {
      return 'Le stock a changé. Actualisez la boutique et vérifiez '
          'les quantités de votre panier.';
    }

    if (message.contains('create_public_store_order') ||
        message.contains('PGRST202') ||
        message.contains('42883')) {
      return 'La fonction SQL de création de commande est absente '
          'ou ses paramètres ne correspondent pas.';
    }

    return 'La commande n’a pas pu être enregistrée. '
        'Vérifiez les données et réessayez.';
  }

  Widget _checkoutField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: _background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ce champ est obligatoire.';
        }

        if (label == 'Téléphone' &&
            value.trim().replaceAll(RegExp(r'\s'), '').length < 6) {
          return 'Numéro de téléphone invalide.';
        }

        return null;
      },
    );
  }

  Future<void> _showOrderSuccess(String orderId) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          icon: const Icon(Icons.check_circle_outline, color: _green, size: 58),
          title: const Text(
            'Commande enregistrée !',
            textAlign: TextAlign.center,
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Votre commande a été transmise à la boutique. '
                'Le commerçant pourra la consulter et la confirmer.',
                textAlign: TextAlign.center,
              ),
              if (orderId.isNotEmpty) ...[
                const SizedBox(height: 14),
                SelectableText(
                  'Référence : $orderId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuer'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.storefront_rounded, color: _red),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadStore,
            icon: const Icon(Icons.refresh_rounded, color: _navy),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Mon panier',
                  onPressed: _openCart,
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: _navy,
                    size: 25,
                  ),
                ),
                if (_cartCount > 0)
                  Positioned(
                    right: 2,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 19,
                        minHeight: 19,
                      ),
                      decoration: const BoxDecoration(
                        color: _red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_cartCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _red))
          : _loadFailed
          ? _buildError()
          : _buildStorefront(),
      floatingActionButton: !_loading && !_loadFailed && _cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: _openCart,
              backgroundColor: _red,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('Panier ($_cartCount)'),
            )
          : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.store_mall_directory_outlined,
                size: 62,
                color: _muted,
              ),
              const SizedBox(height: 18),
              const Text(
                'Boutique indisponible',
                style: TextStyle(
                  color: _navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _loadStore,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorefront() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        return RefreshIndicator(
          color: _red,
          onRefresh: _loadStore,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHero(wide),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 30 : 16,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KeyedSubtree(
                          key: _productsSectionKey,
                          child: _buildSearchAndSort(wide),
                        ),
                        const SizedBox(height: 20),
                        _buildCategories(),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Nos produits',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${_filteredProducts.length} produit(s)',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_filteredProducts.isEmpty)
                          _buildEmptyProducts()
                        else
                          _buildProductGrid(wide),
                        const SizedBox(height: 36),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(bool wide) {
    final logo = _store?['logo_url']?.toString().trim() ?? '';
    final phone = _store?['phone']?.toString().trim() ?? '';
    final city = _store?['city']?.toString().trim() ?? '';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071A38), Color(0xFF102C57), Color(0xFF14264B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -100,
            top: -150,
            child: Container(
              width: wide ? 460 : 300,
              height: wide ? 460 : 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _red.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -90,
            bottom: -180,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 35,
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 38 : 22,
                  vertical: wide ? 46 : 30,
                ),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildHeroContent(
                              logo: logo,
                              phone: phone,
                              city: city,
                              wide: true,
                            ),
                          ),
                          const SizedBox(width: 28),
                          Expanded(flex: 5, child: _buildHeroVisual()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroContent(
                            logo: logo,
                            phone: phone,
                            city: city,
                            wide: false,
                          ),
                          const SizedBox(height: 30),
                          const _HeroVisualMobile(),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent({
    required String logo,
    required String phone,
    required String city,
    required bool wide,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: logo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.storefront_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _red.withValues(alpha: 0.40)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: _red, size: 16),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'VOTRE BOUTIQUE EN LIGNE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 43 : 32,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tout ce que vous cherchez, au même endroit.',
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 20 : 17,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFD4DEEF),
            fontSize: 13,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            final target = _productsSectionKey.currentContext;
            if (target != null) {
              Scrollable.ensureVisible(
                target,
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeInOut,
                alignment: 0.05,
              );
            }
          },
          icon: const Icon(Icons.shopping_bag_outlined, size: 19),
          label: const Text('Découvrir nos produits'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 18,
          runSpacing: 12,
          children: [
            if (city.isNotEmpty) _heroDetail(Icons.location_on_outlined, city),
            if (phone.isNotEmpty) _heroDetail(Icons.phone_outlined, phone),
            _heroDetail(Icons.verified_outlined, 'Boutique en ligne'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return SizedBox(
      height: 350,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 285,
            height: 285,
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Transform.rotate(
            angle: -0.055,
            child: Container(
              width: 300,
              height: 215,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1428),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 35,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF183966), Color(0xFF091A35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront_rounded, color: _red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Votre boutique',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Découvrez nos produits',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 5,
                      width: 105,
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    const Row(
                      children: [
                        _HeroMiniProduct(icon: Icons.headphones_rounded),
                        SizedBox(width: 10),
                        _HeroMiniProduct(icon: Icons.watch_rounded),
                        SizedBox(width: 10),
                        _HeroMiniProduct(icon: Icons.shopping_bag_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 24,
            child: _heroFloatingBadge(
              Icons.local_shipping_outlined,
              'Livraison rapide',
            ),
          ),
          Positioned(
            left: 0,
            bottom: 25,
            child: _heroFloatingBadge(
              Icons.shopping_cart_checkout_rounded,
              'Commande facile',
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFloatingBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3156),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _red, size: 19),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback(bool wide) {
    final size = wide ? 100.0 : 70.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(
        Icons.storefront_rounded,
        size: wide ? 48 : 34,
        color: Colors.white,
      ),
    );
  }

  Widget _heroDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildSearchAndSort(bool wide) {
    final searchField = TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _search = value);
      },
      decoration: InputDecoration(
        hintText: 'Rechercher un produit...',
        prefixIcon: const Icon(Icons.search_rounded, color: _muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
      ),
    );

    final sortField = DropdownButtonFormField<String>(
      value: _sortBy,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'name', child: Text('Nom du produit')),
        DropdownMenuItem(value: 'price_asc', child: Text('Prix croissant')),
        DropdownMenuItem(value: 'price_desc', child: Text('Prix décroissant')),
        DropdownMenuItem(value: 'stock', child: Text('Stock disponible')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _sortBy = value);
      },
    );

    if (wide) {
      return Row(
        children: [
          Expanded(flex: 3, child: searchField),
          const SizedBox(width: 14),
          SizedBox(width: 230, child: sortField),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [searchField, const SizedBox(height: 12), sortField],
    );
  }

  Widget _buildCategories() {
    final categories = _categoryNames;

    if (categories.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            showCheckmark: false,
            selectedColor: _red,
            backgroundColor: Colors.white,
            side: BorderSide(color: selected ? _red : _border),
            labelStyle: TextStyle(
              color: selected ? Colors.white : _navy,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            onSelected: (_) {
              setState(() => _selectedCategory = category);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(bool wide) {
    final width = MediaQuery.of(context).size.width;

    final columns = width >= 1150
        ? 4
        : width >= 780
        ? 3
        : width >= 520
        ? 2
        : 1;

    final horizontal = columns == 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredProducts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: horizontal ? 220 : 390,
      ),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final id = product['id']?.toString() ?? '';

        return StorefrontProductCard(
          product: product,
          category: _categoryName(product['category_id']),
          quantity: _intValue(product['quantity']),
          minimum: _intValue(product['minimum_quantity']),
          inCart: _cart[id] ?? 0,
          price: _doubleValue(product['price']),
          money: _money,
          horizontal: horizontal,
          onAdd: () => _addToCart(product),
        );
      },
    );
  }

  Widget _buildEmptyProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: _muted, size: 48),
          SizedBox(height: 12),
          Text(
            'Aucun produit trouvé',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Essayez une autre recherche ou catégorie.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final address = _store?['address']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined, color: _red, size: 26),
          const SizedBox(height: 8),
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              address,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Boutique propulsée par StockMind',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _HeroMiniProduct extends StatelessWidget {
  final IconData icon;

  const _HeroMiniProduct({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 27),
      ),
    );
  }
}

class _HeroVisualMobile extends StatelessWidget {
  const _HeroVisualMobile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3762), Color(0xFF0B1A33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Column(
        children: [
          Icon(Icons.shopping_bag_rounded, size: 65, color: _red),
          SizedBox(height: 12),
          Text(
            'Votre prochain coup de cœur vous attend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Explorez les produits de notre boutique.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFD4DEEF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
