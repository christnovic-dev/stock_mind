import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constant/app_color.dart';

class DashboardPreview extends StatelessWidget {
  const DashboardPreview();

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
            color: AppColors.navy.withValues(alpha: 0.10),
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
              const Icon(
                Icons.inventory_2_rounded,
                color: AppColors.primary,
                size: 21,
              ),
              const SizedBox(width: 8),
              Text(
                'StockMind',
                style: GoogleFonts.poppins(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.muted,
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFFFFE2E7),
                child: Icon(Icons.person, color: AppColors.primary, size: 17),
              ),
            ],
          ),
          const Divider(height: 25, color: Color(0xFFEDF0F5)),
          Text(
            'Tableau de bord',
            style: GoogleFonts.poppins(
              color: AppColors.navy,
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
                    color: AppColors.primary,
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
                    color: AppColors.navy,
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
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Assistant StockMind : surveillez vos stocks faibles.',
                    style: GoogleFonts.poppins(
                      color: AppColors.navy,
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
              color: AppColors.navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 9),
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
    return Text(
      label,
      style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 9),
    );
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
        ..color = AppColors.primary
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
