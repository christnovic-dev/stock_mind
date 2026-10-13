import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constant/app_color.dart';
import 'boutons_reutilisable.dart';

class PromotionSection extends StatelessWidget {
  const PromotionSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 65),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Container(
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [AppColors.navy, Color(0xFF263C69), AppColors.primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 700;

                return Flex(
                  direction: mobile ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: mobile ? 0 : 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UNE SEULE SOLUTION',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFFCDD5),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Optimisez votre activité avec StockMind',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 26,
                              height: 1.35,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Centralisez vos produits et préparez votre '
                            'entreprise à prendre de meilleures décisions '
                            'grâce à une gestion plus claire de votre stock.',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.9,
                            ),
                          ),
                          const SizedBox(height: 25),
                          PrimaryButton(
                            label: 'Découvrir StockMind',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () =>
                                showMessage(context, 'Inscription'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: mobile ? 0 : 35, height: mobile ? 30 : 0),
                    Expanded(
                      flex: mobile ? 0 : 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.insights_rounded,
                              color: AppColors.primary,
                              size: 43,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Une vision plus claire de votre activité',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: AppColors.navy,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _BenefitRow(
                              label: 'Suivi centralisé des produits',
                            ),
                            const _BenefitRow(
                              label: 'Repérage des stocks faibles',
                            ),
                            const _BenefitRow(
                              label: 'Statistiques de votre activité',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String label;

  const _BenefitRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
