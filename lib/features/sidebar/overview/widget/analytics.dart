import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

class MainAnalytics extends StatelessWidget {
  final bool isMobile;

  const MainAnalytics({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;

        final chart = _StockChartCard(height: stacked ? 300 : 360);

        final summary = const _SummaryCard();

        if (stacked) {
          return Column(children: [chart, const SizedBox(height: 18), summary]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: chart),
            const SizedBox(width: 18),
            Expanded(flex: 4, child: summary),
          ],
        );
      },
    );
  }
}

class _StockChartCard extends StatelessWidget {
  final double height;

  const _StockChartCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Évolution du stock',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Valeur estimée sur les 6 derniers mois',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Text(
                '24 850 DT',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 10),
              Text(
                '+8,4 %',
                style: TextStyle(
                  color: Color(0xFF14A579),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: _ChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const values = [0.38, 0.56, 0.47, 0.68, 0.61, 0.82];

    final chartHeight = size.height - 25;
    const left = 6.0;
    const right = 8.0;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = left + (size.width - left - right) * i / (values.length - 1);
      final y = chartHeight * (1 - values[i]);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final middleX = (previous.dx + current.dx) / 2;

      path.cubicTo(
        middleX,
        previous.dy,
        middleX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartHeight)
      ..lineTo(points.first.dx, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x44F21D3D), Color(0x00F21D3D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, dotPaint);
    }

    const months = ['Mai', 'Juin', 'Juil.', 'Août', 'Sept.', 'Oct.'];

    for (var i = 0; i < months.length; i++) {
      final x = points[i].dx;
      final textPainter = TextPainter(
        text: TextSpan(
          text: months[i],
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      var dx = x - textPainter.width / 2;
      dx = dx.clamp(0.0, size.width - textPainter.width);

      textPainter.paint(canvas, Offset(dx, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Entrées de stock',
        '124',
        Icons.south_west_rounded,
        Color(0xFF14A579),
        Color(0xFFE4F8F0),
      ),
      (
        'Sorties de stock',
        '86',
        Icons.north_east_rounded,
        AppColors.primary,
        Color(0xFFFFE8EC),
      ),
      (
        'Commandes en attente',
        '12',
        Icons.pending_actions_rounded,
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
            'Résumé de l’activité',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Indicateurs de ce mois',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: item.$5,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.$3, color: item.$4, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF4778F5),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Conseil : vérifiez vos produits en stock faible avant votre prochain réapprovisionnement.',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      height: 1.6,
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
