import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

class StatsGrid extends StatelessWidget {
  final bool isMobile;

  const StatsGrid({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    const stats = [
      _StatData(
        title: 'Total des produits',
        value: '248',
        detail: '+12 ce mois-ci',
        icon: Icons.inventory_2_outlined,
        color: Color(0xFF4778F5),
        bg: Color(0xFFEAF0FF),
      ),
      _StatData(
        title: 'Valeur du stock',
        value: '24 850 DT',
        detail: 'Valeur estimée',
        icon: Icons.account_balance_wallet_outlined,
        color: Color(0xFF14A579),
        bg: Color(0xFFE4F8F0),
      ),
      _StatData(
        title: 'Stock faible',
        value: '18',
        detail: 'À réapprovisionner',
        icon: Icons.trending_down_rounded,
        color: Color(0xFFE9A23B),
        bg: Color(0xFFFFF3DF),
      ),
      _StatData(
        title: 'En rupture',
        value: '5',
        detail: 'Action nécessaire',
        icon: Icons.warning_amber_rounded,
        color: AppColors.primary,
        bg: const Color(0xFFFFE8EC),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 560
            ? 1
            : constraints.maxWidth < 1000
            ? 2
            : 4;

        final cardWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stats.map((stat) {
            return SizedBox(
              width: cardWidth,
              child: _StatCard(data: stat),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
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
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 21),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            data.detail,
            style: TextStyle(
              color: data.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
