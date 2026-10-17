import 'package:flutter/material.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);
const Color _green = Color(0xFF159B72);
const Color _orange = Color(0xFFE99A28);

class StorefrontProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String category;
  final int quantity;
  final int minimum;
  final int inCart;
  final double price;
  final String Function(dynamic) money;
  final VoidCallback onAdd;
  final bool horizontal;

  const StorefrontProductCard({
    super.key,
    required this.product,
    required this.category,
    required this.quantity,
    required this.minimum,
    required this.inCart,
    required this.price,
    required this.money,
    required this.onAdd,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? 'Produit';
    final reference = product['reference']?.toString() ?? '';
    final outOfStock = quantity <= 0;
    final lowStock = !outOfStock && quantity <= minimum;

    final statusColor = outOfStock
        ? _red
        : lowStock
        ? _orange
        : _green;

    final statusText = outOfStock
        ? 'Rupture de stock'
        : lowStock
        ? 'Stock limité'
        : 'Disponible';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.045),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: horizontal
          ? Row(
              children: [
                SizedBox(
                  width: 135,
                  height: double.infinity,
                  child: _productImage(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: _details(
                      name: name,
                      reference: reference,
                      outOfStock: outOfStock,
                      statusColor: statusColor,
                      statusText: statusText,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 185, child: _productImage()),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                    child: _details(
                      name: name,
                      reference: reference,
                      outOfStock: outOfStock,
                      statusColor: statusColor,
                      statusText: statusText,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _productImage() {
    final url = product['image_url']?.toString().trim() ?? '';
    final validUrl = url.startsWith('https://') || url.startsWith('http://');

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: _background,
          alignment: Alignment.center,
          child: const Icon(Icons.inventory_2_outlined, size: 48, color: _red),
        ),
        if (validUrl)
          Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 42,
                color: _muted,
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;

              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _red),
                ),
              );
            },
          ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _navy,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _details({
    required String name,
    required String reference,
    required bool outOfStock,
    required Color statusColor,
    required String statusText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (reference.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Réf. $reference',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
        const Spacer(),
        Text(
          money(price),
          style: const TextStyle(
            color: _red,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            onPressed: outOfStock ? null : onAdd,
            icon: Icon(
              inCart > 0
                  ? Icons.add_shopping_cart_rounded
                  : Icons.shopping_bag_outlined,
              size: 17,
            ),
            label: Text(
              inCart > 0 ? 'Ajouter ($inCart)' : 'Ajouter au panier',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _border,
              disabledForegroundColor: _muted,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
