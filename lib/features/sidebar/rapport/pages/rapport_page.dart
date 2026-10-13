import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

class RapportsPage extends StatefulWidget {
  const RapportsPage({super.key});

  @override
  State<RapportsPage> createState() => _RapportsPageState();
}

class _RapportsPageState extends State<RapportsPage> {
  String _period = '7 jours';

  final List<_ReportProduct> _products = const [
    _ReportProduct(
      name: 'Casque Bluetooth',
      category: 'Audio',
      quantity: 42,
      movements: 68,
      color: AppColors.primary,
    ),
    _ReportProduct(
      name: 'Chargeur USB-C',
      category: 'Accessoires',
      quantity: 28,
      movements: 54,
      color: AppColors.green,
    ),
    _ReportProduct(
      name: 'Souris sans fil',
      category: 'Informatique',
      quantity: 35,
      movements: 41,
      color: AppColors.orange,
    ),
    _ReportProduct(
      name: 'Clavier mécanique',
      category: 'Informatique',
      quantity: 16,
      movements: 29,
      color: AppColors.navy,
    ),
    _ReportProduct(
      name: 'Écouteurs filaires',
      category: 'Audio',
      quantity: 7,
      movements: 18,
      color: Color(0xFF8B70D6),
    ),
  ];

  List<_ChartPoint> get _chartData {
    switch (_period) {
      case '30 jours':
        return [
          _ChartPoint('S1', 42, 24),
          _ChartPoint('S2', 58, 31),
          _ChartPoint('S3', 46, 38),
          _ChartPoint('S4', 72, 45),
        ];
      case '90 jours':
        return [
          _ChartPoint('Jan', 45, 28),
          _ChartPoint('Fév', 61, 35),
          _ChartPoint('Mar', 53, 42),
          _ChartPoint('Avr', 75, 51),
        ];
      default:
        return [
          _ChartPoint('Lun', 28, 16),
          _ChartPoint('Mar', 42, 24),
          _ChartPoint('Mer', 35, 19),
          _ChartPoint('Jeu', 58, 32),
          _ChartPoint('Ven', 46, 26),
          _ChartPoint('Sam', 72, 43),
          _ChartPoint('Dim', 51, 30),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 750;

          return SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 16 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(compact),
                const SizedBox(height: 18),
                _buildDemoNotice(),
                const SizedBox(height: 23),
                _buildPeriodSelector(compact),
                const SizedBox(height: 20),
                _buildKpiGrid(compact),
                const SizedBox(height: 22),
                if (compact) ...[
                  _buildMovementChart(),
                  const SizedBox(height: 18),
                  _buildStockDistribution(),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _buildMovementChart()),
                      const SizedBox(width: 18),
                      Expanded(flex: 4, child: _buildStockDistribution()),
                    ],
                  ),
                const SizedBox(height: 22),
                _buildTopProducts(),
                const SizedBox(height: 22),
                _buildStockAlerts(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: AppColors.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rapports',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Analyse et suivi des performances de ton stock.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (!compact)
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'L’export PDF sera disponible après la connexion des données.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Exporter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDemoNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5E5BD)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode démonstration : les chiffres et graphiques sont fictifs. '
              'Ils seront calculés à partir de tes données réelles après '
              'la connexion à Supabase.',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool compact) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Vue d’ensemble',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _period,
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              items: const [
                DropdownMenuItem(value: '7 jours', child: Text('7 jours')),
                DropdownMenuItem(value: '30 jours', child: Text('30 jours')),
                DropdownMenuItem(value: '90 jours', child: Text('90 jours')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _period = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(bool compact) {
    final stats = [
      const _ReportStat(
        title: 'Produits en stock',
        value: '128',
        subtitle: 'Références enregistrées',
        icon: Icons.inventory_2_outlined,
        color: AppColors.navy,
      ),
      const _ReportStat(
        title: 'Valeur du stock',
        value: '8 450 DT',
        subtitle: 'Valeur estimée',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.green,
      ),
      const _ReportStat(
        title: 'Entrées de stock',
        value: '245',
        subtitle: 'Unités reçues',
        icon: Icons.south_west_rounded,
        color: AppColors.green,
      ),
      const _ReportStat(
        title: 'Sorties de stock',
        value: '182',
        subtitle: 'Unités sorties',
        icon: Icons.north_east_rounded,
        color: AppColors.primary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 13,
        mainAxisSpacing: 13,
        mainAxisExtent: 145,
      ),
      itemBuilder: (context, index) => _buildKpiCard(stats[index]),
    );
  }

  Widget _buildKpiCard(_ReportStat stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              Icon(stat.icon, color: stat.color, size: 20),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            stat.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution des mouvements',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Comparaison des entrées et sorties · $_period',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 19),
          const Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendDot(color: AppColors.green, label: 'Entrées'),
              _LegendDot(color: AppColors.primary, label: 'Sorties'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 205,
            width: double.infinity,
            child: CustomPaint(painter: _MovementChartPainter(_chartData)),
          ),
          const SizedBox(height: 14),
          const Text(
            'Quantités illustratives, non issues de ventes réelles.',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStockDistribution() {
    final total = _products.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );

    final distribution = <String, int>{};
    for (final product in _products) {
      distribution[product.category] =
          (distribution[product.category] ?? 0) + product.quantity;
    }

    final colors = [
      AppColors.primary,
      AppColors.green,
      AppColors.orange,
      AppColors.navy,
      const Color(0xFF8B70D6),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition du stock',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quantités par catégorie',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 155,
              width: 155,
              child: CustomPaint(
                painter: _DonutPainter(distribution.values.toList(), colors),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Unités',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          ...distribution.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value.key;
            final quantity = entry.value.value;
            final percentage = total == 0
                ? 0
                : (quantity / total * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final sorted = [..._products]
      ..sort((a, b) => b.movements.compareTo(a.movements));

    final maxValue = sorted.first.movements.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produits les plus mouvementés',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Classement illustratif selon le nombre de mouvements.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 22),
          ...sorted.map((product) {
            final progress = maxValue == 0 ? 0.0 : product.movements / maxValue;

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${product.movements} mouvements',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(product.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStockAlerts() {
    final lowStock = _products.where((p) => p.quantity <= 10).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.orange,
                size: 21,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Produits à surveiller',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Produits dont le stock de démonstration est inférieur ou égal '
            'à 10 unités.',
            style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 15),
          if (lowStock.isEmpty)
            const Text(
              'Aucun produit à surveiller.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            )
          else
            ...lowStock.map((product) {
              return Container(
                margin: const EdgeInsets.only(top: 9),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.orange,
                      size: 19,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${product.quantity} unités',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ReportStat {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ReportStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _ReportProduct {
  final String name;
  final String category;
  final int quantity;
  final int movements;
  final Color color;

  const _ReportProduct({
    required this.name,
    required this.category,
    required this.quantity,
    required this.movements,
    required this.color,
  });
}

class _ChartPoint {
  final String label;
  final double entries;
  final double exits;

  const _ChartPoint(this.label, this.entries, this.exits);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _MovementChartPainter extends CustomPainter {
  final List<_ChartPoint> points;

  _MovementChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 25.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    const maxValue = 80.0;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    final entryPaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final exitPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 5; i++) {
      final y = top + chartHeight * i / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    if (points.isEmpty) return;

    final entryPath = Path();
    final exitPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x =
          left +
          (points.length == 1
              ? chartWidth / 2
              : chartWidth * i / (points.length - 1));

      final entryY = top + chartHeight * (1 - points[i].entries / maxValue);
      final exitY = top + chartHeight * (1 - points[i].exits / maxValue);

      if (i == 0) {
        entryPath.moveTo(x, entryY);
        exitPath.moveTo(x, exitY);
      } else {
        entryPath.lineTo(x, entryY);
        exitPath.lineTo(x, exitY);
      }

      _drawLabel(
        canvas,
        points[i].label,
        Offset(x, size.height - 14),
        const TextStyle(color: AppColors.muted, fontSize: 9),
        alignCenter: true,
      );
    }

    canvas.drawPath(entryPath, entryPaint);
    canvas.drawPath(exitPath, exitPaint);

    for (var i = 0; i < points.length; i++) {
      final x =
          left +
          (points.length == 1
              ? chartWidth / 2
              : chartWidth * i / (points.length - 1));
      final entryY = top + chartHeight * (1 - points[i].entries / maxValue);
      final exitY = top + chartHeight * (1 - points[i].exits / maxValue);

      canvas.drawCircle(Offset(x, entryY), 4, Paint()..color = AppColors.green);
      canvas.drawCircle(
        Offset(x, exitY),
        4,
        Paint()..color = AppColors.primary,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    bool alignCenter = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        position.dx - (alignCenter ? painter.width / 2 : 0),
        position.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MovementChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _DonutPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;

  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19
      ..strokeCap = StrokeCap.butt;

    var startAngle = -1.57079632679;

    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 6.28318530718;
      paint.color = colors[i % colors.length];

      canvas.drawArc(rect.deflate(12), startAngle, sweep, false, paint);

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
