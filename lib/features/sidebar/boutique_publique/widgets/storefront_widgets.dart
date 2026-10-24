import 'package:flutter/material.dart';

const Color storeRed = Color(0xFFF21D3D);
const Color storeNavy = Color(0xFF14264B);
const Color storeBackground = Color(0xFFF7F8FC);
const Color storeMuted = Color(0xFF7B8498);
const Color storeBorder = Color(0xFFE9ECF3);

Color storefrontColor(String? value) {
  if (value == null || value.trim().isEmpty) return storeRed;

  var hex = value.trim().replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';

  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? storeRed : Color(parsed);
}

class StorefrontHero extends StatelessWidget {
  final String storeName;
  final String description;
  final String logoUrl;
  final String city;
  final String phone;
  final Color accentColor;
  final VoidCallback onBrowse;

  const StorefrontHero({
    super.key,
    required this.storeName,
    required this.description,
    required this.logoUrl,
    required this.city,
    required this.phone,
    required this.accentColor,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07162F), Color(0xFF14264B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -110,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.16),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 36 : 20,
                  vertical: wide ? 42 : 28,
                ),
                child: wide
                    ? Row(
                        children: [
                          Expanded(flex: 6, child: _heroContent(context, wide)),
                          const SizedBox(width: 32),
                          Expanded(flex: 4, child: _heroArtwork()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroContent(context, wide),
                          const SizedBox(height: 28),
                          _heroArtwork(),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroContent(BuildContext context, bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: logoUrl.trim().isEmpty
                    ? Icon(
                        Icons.storefront_rounded,
                        color: accentColor,
                        size: 27,
                      )
                    : Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.storefront_rounded, color: accentColor),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: accentColor.withValues(alpha: 0.45)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
              SizedBox(width: 7),
              Text(
                'BOUTIQUE EN LIGNE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          storeName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 43 : 32,
            height: 1.08,
            letterSpacing: -1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Découvrez nos produits et trouvez votre bonheur.',
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 19 : 16,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD5DEEE),
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.shopping_bag_outlined, size: 19),
            label: const Text('Découvrir les produits'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            if (city.trim().isNotEmpty)
              _detail(Icons.location_on_outlined, city),
            if (phone.trim().isNotEmpty) _detail(Icons.phone_outlined, phone),
            _detail(Icons.verified_outlined, 'Commande en ligne'),
          ],
        ),
      ],
    );
  }

  Widget _detail(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _heroArtwork() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 210),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF203D68), Color(0xFF10203C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              color: accentColor,
              size: 54,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Votre prochain coup de cœur vous attend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Parcourez le catalogue et ajoutez vos articles au panier.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD5DEEE),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class StorefrontSearchSort extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final String sortBy;
  final ValueChanged<String> onSort;

  const StorefrontSearchSort({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.sortBy,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;

    final search = TextField(
      controller: controller,
      onChanged: onSearch,
      decoration: InputDecoration(
        hintText: 'Rechercher un produit, une référence...',
        prefixIcon: const Icon(Icons.search_rounded, color: storeMuted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer',
                onPressed: () {
                  controller.clear();
                  onSearch('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: storeBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: storeBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: storeRed, width: 1.4),
        ),
      ),
    );

    final sort = DropdownButtonFormField<String>(
      value: sortBy,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Trier par',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: storeBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: storeBorder),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'name', child: Text('Nom du produit')),
        DropdownMenuItem(value: 'price_asc', child: Text('Prix croissant')),
        DropdownMenuItem(value: 'price_desc', child: Text('Prix décroissant')),
        DropdownMenuItem(value: 'stock', child: Text('Disponibilité')),
      ],
      onChanged: (value) {
        if (value != null) onSort(value);
      },
    );

    if (wide) {
      return Row(
        children: [
          Expanded(flex: 3, child: search),
          const SizedBox(width: 14),
          SizedBox(width: 220, child: sort),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [search, const SizedBox(height: 12), sort],
    );
  }
}

class StorefrontCategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final Color accentColor;

  const StorefrontCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    this.accentColor = storeRed,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            showCheckmark: false,
            selectedColor: accentColor,
            backgroundColor: Colors.white,
            side: BorderSide(color: selected ? accentColor : storeBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : storeNavy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}

class StorefrontFooter extends StatelessWidget {
  final String storeName;
  final String address;
  final Color accentColor;

  const StorefrontFooter({
    super.key,
    required this.storeName,
    required this.address,
    this.accentColor = storeRed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: storeBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_rounded, color: accentColor, size: 30),
          const SizedBox(height: 10),
          Text(
            storeName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: storeNavy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (address.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              address,
              textAlign: TextAlign.center,
              style: const TextStyle(color: storeMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          const Divider(color: storeBorder),
          const SizedBox(height: 10),
          const Text(
            'Une boutique propulsée par StockMind',
            style: TextStyle(
              color: storeMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
