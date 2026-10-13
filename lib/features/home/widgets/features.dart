import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constant/app_color.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    const features = [
      _FeatureData(
        icon: Icons.inventory_2_outlined,
        title: 'Gestion de stock',
        description:
            'Suivez vos produits, gérez les quantités et repérez les stocks faibles.',
        color: Color(0xFFFFE3E8),
        iconColor: AppColors.primary,
      ),
      _FeatureData(
        icon: Icons.storefront_outlined,
        title: 'Boutique en ligne',
        description:
            'Préparez votre boutique numérique et présentez vos produits en ligne.',
        color: Color(0xFFE1EEFF),
        iconColor: Color(0xFF1769E8),
      ),
      _FeatureData(
        icon: Icons.query_stats_rounded,
        title: 'Statistiques',
        description:
            'Analysez vos ventes, vos mouvements de stock et vos performances.',
        color: Color(0xFFDDF8EF),
        iconColor: Color(0xFF079B70),
      ),
      _FeatureData(
        icon: Icons.smart_toy_outlined,
        title: 'Assistant IA',
        description:
            'Préparez des conseils intelligents pour anticiper vos besoins en stock.',
        color: Color(0xFFEDE5FF),
        iconColor: Color(0xFF7846DB),
      ),
      _FeatureData(
        icon: Icons.shield_outlined,
        title: 'Sécurité',
        description:
            'Organisez les données de votre entreprise dans un espace dédié.',
        color: Color(0xFFFFECDD),
        iconColor: Color(0xFFCF5C16),
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 65),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Column(
            children: [
              Text(
                'POURQUOI CHOISIR STOCKMIND ?',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tout ce dont vous avez besoin, au même endroit',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.navy,
                  fontSize: 25,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 35),
              LayoutBuilder(
                builder: (context, constraints) {
                  int columns;
                  if (constraints.maxWidth < 550) {
                    columns = 1;
                  } else if (constraints.maxWidth < 900) {
                    columns = 2;
                  } else {
                    columns = 5;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: features.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 220,
                    ),
                    itemBuilder: (context, index) {
                      return _FeatureCard(data: features[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color iconColor;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.iconColor,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;

  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEDF1F8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 25),
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            style: GoogleFonts.poppins(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            data.description,
            style: GoogleFonts.poppins(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}
