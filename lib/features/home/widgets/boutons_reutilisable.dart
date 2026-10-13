import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constant/app_color.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (icon != null) ...[const SizedBox(width: 9), Icon(icon, size: 17)],
        ],
      ),
    );
  }
}

void showMessage(BuildContext context, String destination) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$destination : cette page sera connectée prochainement.'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
    ),
  );
}
