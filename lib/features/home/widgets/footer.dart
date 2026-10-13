import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constant/app_color.dart';
import 'Navigation.dart';

class Footer extends StatelessWidget {
  const Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 15,
            spacing: 20,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const BrandLogo(),
              Text(
                '© ${DateTime.now().year} StockMind. Tous droits réservés.',
                style: GoogleFonts.poppins(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
              Text(
                'Gestion de stock • Statistiques • Intelligence artificielle',
                style: GoogleFonts.poppins(
                  color: AppColors.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
