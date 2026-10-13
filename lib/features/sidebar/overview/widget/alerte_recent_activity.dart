import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

class BottomPanels extends StatelessWidget {
  final bool isMobile;

  const BottomPanels({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 950;
        final alerts = const _LowStockCard();
        final activity = const _RecentActivityCard();

        if (stacked) {
          return Column(
            children: [alerts, const SizedBox(height: 18), activity],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: alerts),
            const SizedBox(width: 18),
            const Expanded(flex: 5, child: _RecentActivityCard()),
          ],
        );
      },
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard();

  @override
  Widget build(BuildContext context) {
    const products = [
      ('Casque Bluetooth', 'ACC-024', 3, 10),
      ('Chargeur USB-C', 'ACC-018', 5, 15),
      ('Souris sans fil', 'INF-009', 2, 8),
      ('Clavier mécanique', 'INF-014', 0, 5),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Alertes de stock',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '4 alertes',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Produits à surveiller ou à réapprovisionner.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 18),
          ...products.map((product) {
            final outOfStock = product.$3 == 0;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 37,
                    height: 37,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.navy,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.$1,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.$2,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product.$3} unités',
                        style: TextStyle(
                          color: outOfStock
                              ? AppColors.primary
                              : const Color(0xFFE9A23B),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seuil : ${product.$4}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La page des produits sera ajoutée ensuite.'),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text(
                'Voir tous les produits',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    const activities = [
      (
        'Réception de marchandises',
        'Casques Bluetooth · 20 unités',
        'Aujourd’hui, 10:42',
        Icons.south_west_rounded,
        Color(0xFF14A579),
        Color(0xFFE4F8F0),
      ),
      (
        'Sortie de stock',
        'Chargeurs USB-C · 5 unités',
        'Aujourd’hui, 09:18',
        Icons.north_east_rounded,
        AppColors.primary,
        Color(0xFFFFE8EC),
      ),
      (
        'Nouveau produit',
        'Support pour ordinateur',
        'Hier, 16:35',
        Icons.add_box_outlined,
        Color(0xFF4778F5),
        Color(0xFFEAF0FF),
      ),
      (
        'Ajustement de stock',
        'Souris sans fil · 12 unités',
        'Hier, 14:10',
        Icons.tune_rounded,
        Color(0xFFE9A23B),
        Color(0xFFFFF3DF),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activité récente',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Les dernières opérations enregistrées.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 17),
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: activity.$6,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(activity.$4, color: activity.$5, size: 19),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.$1,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          activity.$2,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          activity.$3,
                          style: const TextStyle(
                            color: Color(0xFFA0A7B6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Historique complet bientôt disponible',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
