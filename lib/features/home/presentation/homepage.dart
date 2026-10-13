import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../authentification/auth_page.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _muted = Color(0xFF607399);
const Color _background = Color(0xFFF6F9FE);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _NavigationBar(),
            const _HeroSection(),
            const _FeaturesSection(),
            const _PromotionSection(),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NAVIGATION
// ============================================================

class _NavigationBar extends StatelessWidget {
  const _NavigationBar();

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
                  const _BrandLogo(),
                  const Spacer(),
                  if (!mobile) ...[
                    _NavLink(
                      label: 'Accueil',
                      onTap: () => _scrollTo(context, 0),
                      active: true,
                    ),
                    _NavLink(
                      label: 'Fonctionnalités',
                      onTap: () => _scrollTo(context, 1),
                    ),
                    _NavLink(
                      label: 'Tarifs',
                      onTap: () => _showMessage(context, 'Tarifs'),
                    ),
                    _NavLink(
                      label: 'Ressources',
                      onTap: () => _showMessage(context, 'Ressources'),
                    ),
                    const SizedBox(width: 22),
                    OutlinedButton(
                      onPressed: () => openAuthPage(context, AuthMode.login),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
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
                    _PrimaryButton(
                      label: 'Commencer gratuitement',
                      onPressed: () => openAuthPage(context, AuthMode.signUp),
                    ),
                  ] else ...[
                    IconButton(
                      tooltip: 'Menu',
                      onPressed: () => _showMobileMenu(context),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: _navy,
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
      _showMessage(context, 'Fonctionnalités');
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
              _MenuItem(label: 'Accueil', onTap: () => Navigator.pop(context)),
              _MenuItem(
                label: 'Fonctionnalités',
                onTap: () {
                  Navigator.pop(context);
                  _showMessage(context, 'Fonctionnalités');
                },
              ),
              _MenuItem(
                label: 'Tarifs',
                onTap: () {
                  Navigator.pop(context);
                  _showMessage(context, 'Tarifs');
                },
              ),
              _MenuItem(
                label: 'Se connecter',
                onTap: () => openAuthPage(context, AuthMode.login),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _PrimaryButton(
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

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: _red,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: _red.withValues(alpha: 0.18),
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
                  color: _navy,
                ),
                children: const [
                  TextSpan(text: 'Stock'),
                  TextSpan(
                    text: 'Mind',
                    style: TextStyle(color: _red),
                  ),
                ],
              ),
            ),
            Text(
              'Votre stock, notre intelligence',
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _NavLink({
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
        style: TextButton.styleFrom(foregroundColor: active ? _red : _navy),
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
                  color: _red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
      onTap: onTap,
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _HeroSection extends StatelessWidget {
  const _HeroSection();

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
                      child: _HeroText(mobile: mobile),
                    ),
                    SizedBox(width: mobile ? 0 : 35, height: mobile ? 45 : 0),
                    Expanded(
                      flex: mobile ? 0 : 6,
                      child: const _DashboardPreview(),
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

class _HeroText extends StatelessWidget {
  final bool mobile;

  const _HeroText({required this.mobile});

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
              const Icon(Icons.bolt_rounded, color: _red, size: 17),
              const SizedBox(width: 6),
              Text(
                'GESTION DE STOCK INTELLIGENTE',
                style: GoogleFonts.poppins(
                  color: _red,
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
              color: _navy,
            ),
            children: const [
              TextSpan(text: 'Gérez votre stock,\n'),
              TextSpan(
                text: 'vendez en ligne',
                style: TextStyle(color: _red),
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
          style: GoogleFonts.poppins(color: _muted, fontSize: 14, height: 1.9),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _PrimaryButton(
              label: 'Commencer gratuitement',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => openAuthPage(context, AuthMode.signUp),
            ),
            OutlinedButton.icon(
              onPressed: () => _showMessage(context, 'Démonstration'),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
              label: const Text('Voir la démo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy,
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
        const Icon(Icons.check_circle_rounded, color: _red, size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DASHBOARD ILLUSTRATION — NO IMAGE ASSET REQUIRED
// ============================================================

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF6)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.10),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: _red, size: 21),
              const SizedBox(width: 8),
              Text(
                'StockMind',
                style: GoogleFonts.poppins(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded, color: _muted),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFFFFE2E7),
                child: Icon(Icons.person, color: _red, size: 17),
              ),
            ],
          ),
          const Divider(height: 25, color: Color(0xFFEDF0F5)),
          Text(
            'Tableau de bord',
            style: GoogleFonts.poppins(
              color: _navy,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              return GridView.count(
                crossAxisCount: compact ? 2 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                childAspectRatio: compact ? 2.2 : 1.45,
                children: const [
                  _StatCard(
                    label: 'Produits en stock',
                    value: '248',
                    icon: Icons.inventory_2_outlined,
                    color: Color(0xFF2672F5),
                  ),
                  _StatCard(
                    label: 'Stock faible',
                    value: '12',
                    icon: Icons.warning_amber_rounded,
                    color: _red,
                  ),
                  _StatCard(
                    label: 'Commandes',
                    value: '32',
                    icon: Icons.shopping_bag_outlined,
                    color: Color(0xFF079B70),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFCFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDF0F5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Évolution des ventes',
                  style: GoogleFonts.poppins(
                    color: _navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: CustomPaint(painter: _SalesChartPainter()),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ChartLabel('Lun'),
                    _ChartLabel('Mar'),
                    _ChartLabel('Mer'),
                    _ChartLabel('Jeu'),
                    _ChartLabel('Ven'),
                    _ChartLabel('Sam'),
                    _ChartLabel('Dim'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: _red, size: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Assistant StockMind : surveillez vos stocks faibles.',
                    style: GoogleFonts.poppins(
                      color: _navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9EDF5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 19),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: _navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: _muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  final String label;

  const _ChartLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: GoogleFonts.poppins(color: _muted, fontSize: 9));
  }
}

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE9EDF5)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[
      Offset(0, size.height * .75),
      Offset(size.width * .15, size.height * .45),
      Offset(size.width * .30, size.height * .60),
      Offset(size.width * .45, size.height * .27),
      Offset(size.width * .60, size.height * .42),
      Offset(size.width * .75, size.height * .15),
      Offset(size.width * .88, size.height * .28),
      Offset(size.width, size.height * .07),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x44F21D3D), Color(0x00F21D3D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = _red
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = _red);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// FEATURES
// ============================================================

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    const features = [
      _FeatureData(
        icon: Icons.inventory_2_outlined,
        title: 'Gestion de stock',
        description:
            'Suivez vos produits, gérez les quantités et repérez les stocks faibles.',
        color: Color(0xFFFFE3E8),
        iconColor: _red,
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
      color: _background,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 65),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Column(
            children: [
              Text(
                'POURQUOI CHOISIR STOCKMIND ?',
                style: GoogleFonts.poppins(
                  color: _red,
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
                  color: _navy,
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
            color: _navy.withValues(alpha: 0.025),
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
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            data.description,
            style: GoogleFonts.poppins(
              color: _muted,
              fontSize: 11,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROMOTIONAL SECTION
// ============================================================

class _PromotionSection extends StatelessWidget {
  const _PromotionSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _background,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 65),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Container(
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [_navy, Color(0xFF263C69), _red],
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
                          _PrimaryButton(
                            label: 'Découvrir StockMind',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () =>
                                _showMessage(context, 'Inscription'),
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
                              color: _red,
                              size: 43,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Une vision plus claire de votre activité',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: _navy,
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
          const Icon(Icons.check_circle_rounded, color: _red, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(color: _muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FOOTER
// ============================================================

class _Footer extends StatelessWidget {
  const _Footer();

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
              const _BrandLogo(),
              Text(
                '© ${DateTime.now().year} StockMind. Tous droits réservés.',
                style: GoogleFonts.poppins(color: _muted, fontSize: 11),
              ),
              Text(
                'Gestion de stock • Statistiques • Intelligence artificielle',
                style: GoogleFonts.poppins(color: _muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REUSABLE BUTTON AND HELPERS
// ============================================================

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _red,
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

void _showMessage(BuildContext context, String destination) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$destination : cette page sera connectée prochainement.'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _navy,
    ),
  );
}
