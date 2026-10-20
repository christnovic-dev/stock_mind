import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stockmind/features/core/constant/app_color.dart';
import 'package:stockmind/features/sidebar/boutiques/pages/recu.dart';

import '../../../core/services/currency_scope.dart';
import '../../../core/services/currency_service.dart';
import '../../product/data/mock_product.dart';
import '../../product/services/product_services.dart';
import '../service/service_boutique.dart';

class MaBoutiquePage extends StatefulWidget {
  final String businessId;

  const MaBoutiquePage({super.key, required this.businessId});

  @override
  State<MaBoutiquePage> createState() => _MaBoutiquePageState();
}

class _MaBoutiquePageState extends State<MaBoutiquePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  late final ProductService _productService;
  late final BoutiqueService _boutiqueService;

  List<StockProduct> _products = [];

  bool _editing = true;
  bool _loading = true;
  bool _saving = false;

  String? _loadError;
  String? _savedSlug;

  @override
  void initState() {
    super.initState();

    _productService = ProductService(businessId: widget.businessId);

    _boutiqueService = BoutiqueService(businessId: widget.businessId);

    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return slug.isEmpty ? 'ma-boutique' : slug;
  }

  String get _publicUrl {
    final slug = (_savedSlug != null && _savedSlug!.isNotEmpty)
        ? _savedSlug!
        : _slugify(_nameController.text);

    final basePath = Uri.base.path.startsWith('/stock_mind')
        ? '/stock_mind/'
        : '/';

    return '${Uri.base.origin}$basePath#/boutique/$slug';
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _boutiqueService.getBoutique(),
        _productService.getProducts(),
      ]);

      final boutique = Map<String, dynamic>.from(results[0] as Map);
      final products = List<StockProduct>.from(results[1] as List);

      if (!mounted) return;

      setState(() {
        _nameController.text = (boutique['shop_name'] ?? boutique['name'] ?? '')
            .toString();

        _descriptionController.text = (boutique['description'] ?? '')
            .toString();

        _phoneController.text = (boutique['phone'] ?? '').toString();
        _addressController.text = (boutique['address'] ?? '').toString();

        _savedSlug = boutique['slug']?.toString();

        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('business_members') ||
        message.contains('Aucune entreprise associée')) {
      return 'Aucune entreprise n’est associée à votre compte. '
          'Vérifiez votre adhésion dans business_members.';
    }

    if (message.contains('JWT') ||
        message.contains('not authenticated') ||
        message.contains('Vous devez être connecté')) {
      return 'Votre session ne permet pas de charger la boutique. '
          'Veuillez vous reconnecter.';
    }

    return message.replaceFirst('Exception: ', '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _boutiqueService.saveBoutique(
        shopName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _editing = false;
        _saving = false;
        _savedSlug = _slugify(_nameController.text);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les informations de votre boutique ont été enregistrées.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde : ${_friendlyError(e)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _publicUrl));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien de la boutique copié.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPublicStore() {
    final slug = (_savedSlug != null && _savedSlug!.isNotEmpty)
        ? _savedSlug!
        : _slugify(_nameController.text);

    Navigator.of(context).pushNamed('/boutique/$slug');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadError != null) {
      return Container(
        color: AppColors.background,
        width: double.infinity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Impossible de charger votre boutique',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final available = _products.where((p) => p.quantity > 0).length;
    final totalQuantity = _products.fold<int>(0, (sum, p) => sum + p.quantity);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1050;

          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 28 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildHero(),
                    const SizedBox(height: 18),

                    // Statistiques du catalogue.
                    _buildStats(_products.length, available, totalQuantity),
                    const SizedBox(height: 24),

                    // NOUVEAU : gestion des commandes reçues.
                    CommandesRecuesSection(businessId: widget.businessId),
                    const SizedBox(height: 24),

                    // Paramètres et catalogue d'origine.
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildSettings()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildCatalog(_products)),
                        ],
                      )
                    else ...[
                      _buildSettings(),
                      const SizedBox(height: 20),
                      _buildCatalog(_products),
                    ],

                    const SizedBox(height: 20),
                    _buildPublicLink(),
                    const SizedBox(height: 12),

                    const Text(
                      'Les informations et le catalogue sont chargés depuis '
                      'Supabase. Les commandes nécessitent également une '
                      'configuration correcte des tables et des politiques '
                      'de sécurité Supabase.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Ma boutique',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Gérez votre présence en ligne et vos produits.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: _openPublicStore,
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('Aperçu client'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF263F70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'VOTRE ESPACE E-COMMERCE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .7,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _nameController.text.trim().isEmpty
                    ? 'Votre boutique'
                    : _nameController.text.trim(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Présentez vos produits et préparez votre boutique en ligne.',
                style: TextStyle(color: Color(0xFFDCE5F5), height: 1.5),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openPublicStore,
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('Voir l’aperçu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.navy,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Copier le lien'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(.45)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Color(0x55FFFFFF),
                    size: 48,
                  ),
                ),
                content,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 24),
              const Icon(
                Icons.storefront_rounded,
                color: Color(0x55FFFFFF),
                size: 100,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStats(int productCount, int available, int quantity) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 1;

        final items = [
          _StatData(
            label: 'Produits au catalogue',
            value: '$productCount',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF1457FF),
          ),
          _StatData(
            label: 'Produits disponibles',
            value: '$available',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF168653),
          ),
          _StatData(
            label: 'Unités en stock',
            value: '$quantity',
            icon: Icons.stacked_bar_chart_rounded,
            color: AppColors.primary,
          ),
        ];

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 92,
          ),
          itemBuilder: (_, index) => _StatCard(data: items[index]),
        );
      },
    );
  }

  Widget _buildSettings() {
    return _SectionCard(
      title: 'Informations de la boutique',
      subtitle: 'Personnalisez la présentation de votre commerce.',
      icon: Icons.tune_rounded,
      trailing: TextButton.icon(
        onPressed: _saving
            ? null
            : () {
                setState(() {
                  if (_editing) {
                    _loadData();
                  } else {
                    _editing = true;
                  }
                });
              },
        icon: Icon(_editing ? Icons.close : Icons.edit_outlined, size: 17),
        label: Text(_editing ? 'Annuler' : 'Modifier'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Nom de la boutique *'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _nameController,
              enabled: _editing && !_saving,
              onChanged: (_) => setState(() {}),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Le nom est obligatoire.'
                  : null,
              decoration: _inputDecoration(
                'Ex. : Boutique Duo',
                Icons.storefront_outlined,
              ),
            ),
            const SizedBox(height: 16),
            _label('Description'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _descriptionController,
              enabled: _editing && !_saving,
              maxLines: 3,
              decoration: _inputDecoration(
                'Présentez votre boutique.',
                Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 16),
            _label('Téléphone de contact'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _phoneController,
              enabled: _editing && !_saving,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                'Votre numéro de téléphone',
                Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 16),
            _label('Adresse'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _addressController,
              enabled: _editing && !_saving,
              decoration: _inputDecoration(
                'Ville, quartier, adresse...',
                Icons.location_on_outlined,
              ),
            ),
            if (_editing) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _saving
                        ? 'Enregistrement...'
                        : 'Enregistrer les informations',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCatalog(List<StockProduct> products) {
    return _SectionCard(
      title: 'Catalogue de produits',
      subtitle: 'Produits issus de votre liste StockMind.',
      icon: Icons.inventory_2_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE7EB),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          '${products.length} produits',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: products.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'Aucun produit pour le moment.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  _ProductTile(product: products[i]),
                  if (i < products.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
    );
  }

  Widget _buildPublicLink() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.public_rounded, color: Color(0xFF1457FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lien public de votre boutique',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                SelectableText(
                  _publicUrl,
                  style: const TextStyle(
                    color: Color(0xFF1457FF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Partagez ce lien pour permettre aux clients de découvrir '
                  'votre boutique.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copier le lien',
            onPressed: _copyLink,
            icon: const Icon(Icons.copy_rounded, color: AppColors.navy),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA5ADBC), fontSize: 12),
      prefixIcon: Icon(icon, size: 19, color: AppColors.muted),
      filled: true,
      fillColor: _editing ? const Color(0xFFFAFBFD) : const Color(0xFFF1F3F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7EB),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final StockProduct product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final available = product.quantity > 0;
    final imageUrl = product.imageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Photo du produit provenant de Supabase Storage.
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl != null && imageUrl.trim().isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const _ProductImagePlaceholder();
                      },
                    )
                  : const _ProductImagePlaceholder(),
            ),
          ),

          const SizedBox(width: 14),

          // Informations du produit.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),

                Text(
                  '${product.category} • ${product.reference}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      CurrencyService.format(
                        product.price,
                        currencyCode: CurrencyScope.of(context).currencyCode,
                      ),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: available
                            ? const Color(0xFFE8F7EF)
                            : const Color(0xFFFCE7EB),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        available ? 'En stock : ${product.quantity}' : 'Épuisé',
                        style: TextStyle(
                          color: available
                              ? const Color(0xFF168653)
                              : AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 30,
        color: AppColors.muted,
      ),
    );
  }
}
