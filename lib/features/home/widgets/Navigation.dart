import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../authentifications/pages/auth_page.dart';
import '../../core/constant/app_color.dart';
import '../pages/homepage.dart';
import 'boutons_reutilisable.dart';

class NavigationBar extends StatelessWidget {
  const NavigationBar();

  void _scrollToSection(BuildContext context, GlobalKey key) {
    final targetContext = key.currentContext;

    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 800;

        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 20 : 48,
            vertical: 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Row(
                children: [
                  const BrandLogo(),
                  const Spacer(),
                  if (!mobile) ...[
                    NavLink(
                      label: 'Accueil',
                      onTap: () => _scrollTo(context, 0),
                      active: true,
                    ),
                    NavLink(
                      label: 'Fonctionnalités',
                      onTap: () =>
                          _scrollToSection(context, featuresSectionKey),
                    ),
                    NavLink(
                      label: 'Tarifs',
                      onTap: () => _scrollToSection(context, pricingSectionKey),
                    ),
                    NavLink(
                      label: 'Ressources',
                      onTap: () =>
                          _scrollToSection(context, resourcesSectionKey),
                    ),
                    const SizedBox(width: 22),
                    OutlinedButton(
                      onPressed: () => openAuthPage(context, AuthMode.login),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: Color(0xFFE0E5EF)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Se connecter'),
                    ),
                    const SizedBox(width: 10),
                    PrimaryButton(
                      label: 'Commencer gratuitement',
                      onPressed: () => openAuthPage(context, AuthMode.signUp),
                    ),
                  ] else ...[
                    IconButton(
                      tooltip: 'Menu',
                      onPressed: () => _showMobileMenu(context),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: AppColors.navy,
                        size: 28,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _scrollTo(BuildContext context, int section) {
    if (section == 0) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
      );
    } else {
      showMessage(context, 'Fonctionnalités');
    }
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MenuItem(label: 'Accueil', onTap: () => Navigator.pop(context)),
              MenuItem(
                label: 'Fonctionnalités',
                onTap: () {
                  Navigator.pop(context);
                  showMessage(context, 'Fonctionnalités');
                },
              ),
              MenuItem(
                label: 'Tarifs',
                onTap: () {
                  Navigator.pop(context);
                  showMessage(context, 'Tarifs');
                },
              ),
              MenuItem(
                label: 'Se connecter',
                onTap: () => openAuthPage(context, AuthMode.login),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Commencer gratuitement',
                  onPressed: () => openAuthPage(context, AuthMode.signUp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: AppColors.navy,
                ),
                children: const [
                  TextSpan(text: 'Stock'),
                  TextSpan(
                    text: 'Mind',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Text(
              'Votre stock, notre intelligence',
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;

  const NavLink({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: active ? AppColors.primary : AppColors.navy,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (active)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const MenuItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
      onTap: onTap,
    );
  }
}
