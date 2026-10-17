import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../product/data/mock_product.dart';
import '../../product/services/product_services.dart';
import '../services/vente_service.dart';

class VentePage extends StatefulWidget {
  const VentePage({
    super.key,
    required this.businessId,
    this.businessName = 'StockMind',
  });

  final String businessId;
  final String businessName;

  @override
  State<VentePage> createState() => _VentePageState();
}

class _VentePageState extends State<VentePage> {
  late final ProductService _productService;
  late final VenteService _venteService;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerCityController = TextEditingController();

  List<StockProduct> _products = [];
  final Map<String, int> _cart = {};

  bool _loading = true;
  bool _processing = false;
  String _paymentMethod = 'especes';
  String _search = '';

  static const Color _red = Color(0xFFF21D3D);
  static const Color _navy = Color(0xFF14264B);
  static const Color _muted = Color(0xFF7B8498);
  static const Color _background = Color(0xFFF7F8FC);
  static const Color _border = Color(0xFFE9ECF3);

  @override
  void initState() {
    super.initState();
    _productService = ProductService(businessId: widget.businessId);
    _venteService = VenteService(businessId: widget.businessId);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerCityController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final products = await _productService.getProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message('Impossible de charger les produits : $e', error: true);
    }
  }

  List<StockProduct> get _filteredProducts {
    final query = _search.trim().toLowerCase();

    return _products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.reference.toLowerCase().contains(query);
    }).toList();
  }

  int get _cartCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);

  double get _total {
    double total = 0;

    for (final product in _products) {
      total += product.price * (_cart[product.id] ?? 0);
    }

    return total;
  }

  String _money(num value) => '${value.toStringAsFixed(2)} DT';

  void _message(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : _navy,
        ),
      );
  }

  void _addProduct(StockProduct product) {
    final current = _cart[product.id] ?? 0;

    if (product.quantity <= current) {
      _message('Stock insuffisant pour ${product.name}.', error: true);
      return;
    }

    setState(() => _cart[product.id] = current + 1);
  }

  void _changeQuantity(StockProduct product, int quantity) {
    if (quantity <= 0) {
      setState(() => _cart.remove(product.id));
      return;
    }

    if (quantity > product.quantity) {
      _message('Stock disponible : ${product.quantity}.', error: true);
      return;
    }

    setState(() => _cart[product.id] = quantity);
  }

  bool _validateCustomer() {
    final customerName = _customerNameController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();

    if (customerName.isEmpty) {
      _message('Le nom du client est obligatoire.', error: true);
      return false;
    }

    if (customerPhone.isEmpty) {
      _message('Le téléphone du client est obligatoire.', error: true);
      return false;
    }

    if (!RegExp(r'[0-9]').hasMatch(customerPhone)) {
      _message('Saisis un numéro de téléphone valide.', error: true);
      return false;
    }

    return true;
  }

  Future<void> _confirmSale() async {
    if (_processing) return;

    if (_cart.isEmpty) {
      _message('Ajoute au moins un produit au panier.', error: true);
      return;
    }

    if (!_validateCustomer()) return;

    if (widget.businessId.trim().isEmpty) {
      _message('Impossible d’identifier l’entreprise active.', error: true);
      return;
    }

    for (final entry in _cart.entries) {
      final matchingProducts = _products.where(
        (product) => product.id == entry.key,
      );

      final product = matchingProducts.isEmpty ? null : matchingProducts.first;

      if (product == null || entry.value > product.quantity) {
        _message(
          'Stock insuffisant ou produit indisponible. Recharge les produits.',
          error: true,
        );
        await _loadProducts();
        return;
      }
    }

    final customerName = _customerNameController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();
    final customerCity = _customerCityController.text.trim();

    final cartLines = _cart.entries.map((entry) {
      return <String, dynamic>{
        'product_id': entry.key,
        'quantity': entry.value,
      };
    }).toList();

    setState(() => _processing = true);

    try {
      final result = await _venteService.checkout(
        customerName: customerName,
        customerPhone: customerPhone,
        customerCity: customerCity,
        paymentMethod: _paymentMethod,
        items: cartLines,
      );

      final saleId = result['sale_id'].toString();
      final saleNumber = result['sale_number'].toString();
      final total = (result['total_amount'] as num).toDouble();

      final savedItems = await _venteService.getSaleItems(saleId);

      final invoiceLines = savedItems.map((item) {
        return <String, dynamic>{
          'name': item['product_name'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'subtotal': item['subtotal'],
        };
      }).toList();

      final invoiceData = <String, dynamic>{
        'sale_id': saleId,
        'sale_number': saleNumber,
        'total_amount': total,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_city': customerCity,
        'payment_method': _paymentMethod,
        'created_at': DateTime.now(),
        'items': invoiceLines,
      };

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _customerNameController.clear();
        _customerPhoneController.clear();
        _customerCityController.clear();
      });

      await _loadProducts();

      if (!mounted) return;

      _message('Vente n° $saleNumber enregistrée avec succès.');

      try {
        await _printInvoice(invoiceData);
      } catch (e) {
        _message(
          'Vente enregistrée, mais la facture PDF n’a pas pu être ouverte : $e',
          error: true,
        );
      }
    } catch (e) {
      _message(
        'Vente non enregistrée : '
        '${e.toString().replaceFirst('Exception: ', '')}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _printInvoice(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final items = List<Map<String, dynamic>>.from(data['items'] as List);
    final date = data['created_at'] as DateTime;

    final paymentLabels = {
      'especes': 'Espèces',
      'carte': 'Carte bancaire',
      'virement': 'Virement',
      'cheque': 'Chèque',
      'mobile_money': 'Mobile Money',
      'autre': 'Autre',
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            widget.businessName,
            style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('FACTURE DE VENTE'),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text('Facture n° ${data['sale_number']}'),
          pw.Text(
            'Date : ${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/${date.year} '
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}',
          ),
          pw.SizedBox(height: 12),
          pw.Text('Client : ${data['customer_name']}'),
          pw.Text('Téléphone : ${data['customer_phone']}'),
          if ((data['customer_city'] as String).isNotEmpty)
            pw.Text('Ville : ${data['customer_city']}'),
          pw.Text(
            'Paiement : '
            '${paymentLabels[data['payment_method']] ?? data['payment_method']}',
          ),
          pw.SizedBox(height: 22),
          pw.TableHelper.fromTextArray(
            headers: ['Produit', 'Qté', 'Prix unitaire', 'Sous-total'],
            data: items.map((item) {
              return [
                item['name'].toString(),
                item['quantity'].toString(),
                '${(item['unit_price'] as num).toStringAsFixed(2)} DT',
                '${(item['subtotal'] as num).toStringAsFixed(2)} DT',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellPadding: const pw.EdgeInsets.all(8),
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL : '
              '${(data['total_amount'] as num).toStringAsFixed(2)} DT',
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 35),
          pw.Center(child: pw.Text('Merci pour votre confiance !')),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'facture_${data['sale_number']}.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 950;

                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildCatalog()),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 370,
                          child: SingleChildScrollView(child: _buildCheckout()),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(height: 500, child: _buildCatalog()),
                    const SizedBox(height: 16),
                    _buildCheckout(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCatalog() {
    final products = _filteredProducts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Catalogue des produits',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
              ),
              Text(
                '${products.length} produit(s)',
                style: const TextStyle(color: _muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: 'Rechercher un produit ou une référence...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: _background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun produit trouvé.',
                      style: TextStyle(color: _muted),
                    ),
                  )
                : GridView.builder(
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisExtent: 230,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final quantity = _cart[product.id] ?? 0;
                      final unavailable =
                          product.quantity <= quantity || product.quantity <= 0;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: unavailable ? null : () => _addProduct(product),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: quantity > 0 ? _red : _border,
                              width: quantity > 0 ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Affichage de l'image enregistrée sur Supabase.
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child:
                                        product.imageUrl != null &&
                                            product.imageUrl!.trim().isNotEmpty
                                        ? Image.network(
                                            product.imageUrl!,
                                            fit: BoxFit.fill,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const _ProductImagePlaceholder();
                                                },
                                          )
                                        : const _ProductImagePlaceholder(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _money(product.price),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _red,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (quantity > 0)
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: _red,
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                product.quantity > 0
                                    ? 'Stock : ${product.quantity}'
                                    : 'Rupture de stock',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: product.quantity > 0
                                      ? _muted
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckout() {
    final cartProducts = _products
        .where((product) => (_cart[product.id] ?? 0) > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Panier',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$_cartCount article(s)',
                style: const TextStyle(color: _muted),
              ),
              IconButton(
                tooltip: 'Vider le panier',
                onPressed: _processing || _cart.isEmpty
                    ? null
                    : () => setState(() => _cart.clear()),
                icon: const Icon(Icons.delete_outline, color: _muted),
              ),
            ],
          ),
          const Divider(height: 20),
          if (cartProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'Ton panier est vide.',
                  style: TextStyle(color: _muted),
                ),
              ),
            )
          else
            ...cartProducts.map((product) {
              final quantity = _cart[product.id]!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Petite miniature également dans le panier.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child:
                            product.imageUrl != null &&
                                product.imageUrl!.trim().isNotEmpty
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const _ProductImagePlaceholder();
                                },
                              )
                            : const _ProductImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_money(product.price)} × $quantity',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _processing
                          ? null
                          : () => _changeQuantity(product, quantity - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _processing
                          ? null
                          : () => _changeQuantity(product, quantity + 1),
                      icon: const Icon(Icons.add_circle_outline, color: _red),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 24),
          const Text(
            'Informations du client',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            '* Champs obligatoires',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _field(
            _customerNameController,
            'Nom du client *',
            icon: Icons.person_outline,
            enabled: !_processing,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 9),
          _field(
            _customerPhoneController,
            'Téléphone du client *',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: !_processing,
          ),
          const SizedBox(height: 9),
          _field(
            _customerCityController,
            'Ville (facultatif)',
            icon: Icons.location_city_outlined,
            enabled: !_processing,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          const Text(
            'Mode de paiement',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: _background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'especes', child: Text('Espèces')),
              DropdownMenuItem(value: 'carte', child: Text('Carte bancaire')),
              DropdownMenuItem(value: 'virement', child: Text('Virement')),
              DropdownMenuItem(value: 'cheque', child: Text('Chèque')),
              DropdownMenuItem(
                value: 'mobile_money',
                child: Text('Mobile Money'),
              ),
              DropdownMenuItem(value: 'autre', child: Text('Autre')),
            ],
            onChanged: _processing
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _paymentMethod = value);
                    }
                  },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL À PAYER',
                  style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                _money(_total),
                style: const TextStyle(
                  color: _red,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _processing || _cart.isEmpty ? null : _confirmSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.receipt_long),
              label: Text(
                _processing ? 'Validation...' : 'Encaisser et facturer',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: _background,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF7F8FC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 36,
        color: Color(0xFF7B8498),
      ),
    );
  }
}
