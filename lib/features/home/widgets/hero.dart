import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../authentifications/pages/auth_page.dart';
import '../../core/constant/app_color.dart';
import 'boutons_reutilisable.dart';
import 'dashboard_illustration.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 850;

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF3F7FF)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: mobile ? 22 : 48,
                  vertical: mobile ? 48 : 65,
                ),
                child: Flex(
                  direction: mobile ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: mobile ? 0 : 5,
                      child: HeroText(mobile: mobile),
                    ),
                    SizedBox(width: mobile ? 0 : 35, height: mobile ? 45 : 0),
                    Expanded(
                      flex: mobile ? 0 : 6,
                      child: const DashboardPreview(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HeroText extends StatelessWidget {
  final bool mobile;

  const HeroText({required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDF0),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: AppColors.primary,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                'GESTION DE STOCK INTELLIGENTE',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text.rich(
          TextSpan(
            style: GoogleFonts.poppins(
              fontSize: mobile ? 34 : 43,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: AppColors.navy,
            ),
            children: const [
              TextSpan(text: 'Gérez votre stock,\n'),
              TextSpan(
                text: 'vendez en ligne',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: '\net développez votre activité'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'StockMind vous aide à suivre vos produits, '
          'anticiper les ruptures et comprendre vos ventes. '
          'Bientôt, votre assistant IA vous aidera à prendre '
          'de meilleures décisions.',
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontSize: 14,
            height: 1.9,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            PrimaryButton(
              label: 'Commencer gratuitement',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => openAuthPage(context, AuthMode.signUp),
            ),
            OutlinedButton.icon(
              onPressed: () => showMessage(context, 'Démonstration'),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
              label: const Text('Voir la démo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: const [
            _TrustItem(label: 'Configuration simple'),
            _TrustItem(label: 'Stock centralisé'),
            _TrustItem(label: 'Pensé pour les entreprises'),
          ],
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  final String label;

  const _TrustItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.primary,
          size: 17,
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
