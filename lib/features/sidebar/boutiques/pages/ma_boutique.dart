import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

import '../../product/data/mock_product.dart';

class MaBoutiquePage extends StatefulWidget {
  const MaBoutiquePage({super.key});

  @override
  State<MaBoutiquePage> createState() => _MaBoutiquePageState();
}

class _MaBoutiquePageState extends State<MaBoutiquePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Ma boutique');
  final _descriptionController = TextEditingController(
    text: 'Découvrez nos produits et passez vos commandes en ligne.',
  );
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _editing = true;

  String _slugify(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return slug.isEmpty ? 'ma-boutique' : slug;
  }

  String get _publicUrl {
    final slug = _slugify(_nameController.text);

    // Chemin de base de l'application Flutter Web
    final basePath = Uri.base.path.startsWith('/stock_mind')
        ? '/stock_mind/'
        : '/';

    return '${Uri.base.origin}$basePath#/boutique/$slug';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _editing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Informations conservées pour cette session. '
          'La sauvegarde permanente sera ajoutée avec Supabase.',
        ),
      ),
    );
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _publicUrl));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Lien copié. La page publique doit encore être configurée.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = mockProducts;
    final available = products.where((p) => p.quantity > 0).length;
    final totalQuantity = products.fold<int>(0, (sum, p) => sum + p.quantity);

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
                    _buildStats(products.length, available, totalQuantity),
                    const SizedBox(height: 24),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildSettings()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildCatalog(products)),
                        ],
                      )
                    else ...[
                      _buildSettings(),
                      const SizedBox(height: 20),
                      _buildCatalog(products),
                    ],
                    const SizedBox(height: 20),
                    _buildPublicLink(),
                    const SizedBox(height: 12),
                    const Text(
                      'Mode démonstration : les informations ne sont pas '
                      'encore sauvegardées dans une base de données. '
                      'Le lien public et les commandes seront activés '
                      'dans les prochaines étapes.',
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
        onPressed: () => setState(() => _editing = !_editing),
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
              enabled: _editing,
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
              enabled: _editing,
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
              enabled: _editing,
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
              enabled: _editing,
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
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Enregistrer les informations'),
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
                  'Lien indicatif : la route publique doit être créée '
                  'avant de le partager aux clients.',
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

  void _openPublicStore() {
    Navigator.of(
      context,
    ).pushNamed('/boutique/${_slugify(_nameController.text)}');
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.muted,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.category} • ${product.reference}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      product.price.toStringAsFixed(2),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: available
                            ? const Color(0xFFE8F7EF)
                            : const Color(0xFFF1F2F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        available ? 'En stock : ${product.quantity}' : 'Épuisé',
                        style: TextStyle(
                          color: available
                              ? const Color(0xFF168653)
                              : AppColors.muted,
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
