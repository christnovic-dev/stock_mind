import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/currency_scope.dart';
import '../../../core/services/currency_service.dart';

class MainAnalytics extends StatefulWidget {
  final bool isMobile;
  final String businessId;

  const MainAnalytics({
    super.key,
    required this.isMobile,
    required this.businessId,
  });

  @override
  State<MainAnalytics> createState() => _MainAnalyticsState();
}

class _MainAnalyticsState extends State<MainAnalytics> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  double _stockValue = 0;
  int _entries = 0;
  int _exits = 0;
  int _pendingOrders = 0;

  List<double> _monthlyNetMovements = List.filled(6, 0);
  List<String> _months = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  @override
  void didUpdateWidget(covariant MainAnalytics oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.businessId != widget.businessId) {
      _loadAnalytics();
    }
  }

  DateTime _monthStart(DateTime date) {
    return DateTime(date.year, date.month);
  }

  String _monthLabel(DateTime date) {
    const names = [
      'Jan.',
      'Fév.',
      'Mars',
      'Avr.',
      'Mai',
      'Juin',
      'Juil.',
      'Août',
      'Sept.',
      'Oct.',
      'Nov.',
      'Déc.',
    ];

    return names[date.month - 1];
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ' ',
    );
  }

  String _formatMoney(double value, String currencyCode) {
    return CurrencyService.format(value, currencyCode: currencyCode);
  }

  Future<void> _loadAnalytics() async {
    if (widget.businessId.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Aucune entreprise sélectionnée.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final currentMonth = _monthStart(now);
      final sixMonthsAgo = DateTime(now.year, now.month - 5);

      // 1. Valeur actuelle du stock de cette entreprise.
      final productsResponse = await _supabase
          .from('products')
          .select('price, quantity')
          .eq('business_id', widget.businessId);

      double stockValue = 0;

      for (final item in productsResponse) {
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

        stockValue += price * quantity;
      }

      // 2. Mouvements des six derniers mois.
      final movementsResponse = await _supabase
          .from('stock_movements')
          .select('movement_type, quantity, confirmed_at, created_at')
          .eq('business_id', widget.businessId)
          .gte('confirmed_at', sixMonthsAgo.toIso8601String())
          .order('confirmed_at', ascending: true);

      final monthlyNet = List<double>.filled(6, 0);
      int entries = 0;
      int exits = 0;

      for (final item in movementsResponse) {
        final dateString =
            item['confirmed_at']?.toString() ?? item['created_at']?.toString();

        if (dateString == null) continue;

        final date = DateTime.parse(dateString).toLocal();
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final type = item['movement_type']?.toString();

        final monthIndex =
            (date.year - sixMonthsAgo.year) * 12 +
            date.month -
            sixMonthsAgo.month;

        if (monthIndex < 0 || monthIndex >= 6) continue;

        if (type == 'entree') {
          monthlyNet[monthIndex] += quantity;

          if (!date.isBefore(currentMonth) &&
              date.year == now.year &&
              date.month == now.month) {
            entries += quantity;
          }
        } else if (type == 'sortie') {
          monthlyNet[monthIndex] -= quantity;

          if (!date.isBefore(currentMonth) &&
              date.year == now.year &&
              date.month == now.month) {
            exits += quantity;
          }
        }
      }

      // 3. Commandes en attente.
      // Si cette requête échoue, les statistiques de stock restent visibles.
      int pendingOrders = 0;

      try {
        final ordersResponse = await _supabase
            .from('orders')
            .select('id')
            .eq('business_id', widget.businessId)
            .eq('status', 'en_attente');

        pendingOrders = (ordersResponse as List).length;
      } catch (e) {
        debugPrint('Erreur chargement commandes en attente : $e');
      }

      final months = List.generate(
        6,
        (index) => _monthLabel(
          DateTime(sixMonthsAgo.year, sixMonthsAgo.month + index),
        ),
      );

      if (!mounted) return;

      setState(() {
        _stockValue = stockValue;
        _entries = entries;
        _exits = exits;
        _pendingOrders = pendingOrders;
        _monthlyNetMovements = monthlyNet;
        _months = months;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur MainAnalytics : $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les statistiques.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = CurrencyScope.of(context).currencyCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: _loadAnalytics,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;

            final chart = _StockChartCard(
              height: stacked ? 300 : 360,
              isLoading: _isLoading,
              stockValue: _stockValue,
              monthlyNetMovements: _monthlyNetMovements,
              months: _months,
              currencyCode: currencyCode,
            );

            final summary = _SummaryCard(
              isLoading: _isLoading,
              entries: _entries,
              exits: _exits,
              pendingOrders: _pendingOrders,
              onRefresh: _loadAnalytics,
            );

            if (stacked) {
              return Column(
                children: [chart, const SizedBox(height: 18), summary],
              );
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
        ),
      ],
    );
  }
}

class _StockChartCard extends StatelessWidget {
  final double height;
  final bool isLoading;
  final double stockValue;
  final List<double> monthlyNetMovements;
  final List<String> months;
  final String currencyCode;

  const _StockChartCard({
    required this.height,
    required this.isLoading,
    required this.stockValue,
    required this.monthlyNetMovements,
    required this.months,
    required this.currencyCode,
  });

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
                      'Activité du stock',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Évolution nette des entrées et sorties sur 6 mois',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isLoading
                        ? 'Chargement...'
                        : CurrencyService.format(
                            stockValue,
                            currencyCode: currencyCode,
                          ),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Valeur actuelle estimée du stock',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : CustomPaint(
                    painter: _ChartPainter(
                      values: monthlyNetMovements,
                      months: months,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> months;

  _ChartPainter({required this.values, required this.months});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || values.isEmpty) {
      return;
    }

    const left = 8.0;
    const right = 8.0;
    const bottom = 25.0;

    final chartHeight = size.height - bottom;
    if (chartHeight <= 0) return;

    final maxAbs = values
        .map((v) => v.abs())
        .fold<double>(1, (a, b) => a > b ? a : b);

    // La ligne centrale représente zéro mouvement net.
    final zeroY = chartHeight / 2;
    final halfHeight = chartHeight * 0.42;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(
        const Offset(left, 0) + Offset(0, 0) + Offset(0, 0),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    canvas.drawLine(
      Offset(left, zeroY),
      Offset(size.width - right, zeroY),
      gridPaint,
    );

    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : left + (size.width - left - right) * i / (values.length - 1);

      final normalized = values[i] / maxAbs;
      final y = zeroY - normalized * halfHeight;

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

    for (var i = 0; i < months.length && i < points.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: months[i],
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      var dx = points[i].dx - textPainter.width / 2;
      dx = dx.clamp(0.0, size.width - textPainter.width);

      textPainter.paint(canvas, Offset(dx, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.months != months;
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isLoading;
  final int entries;
  final int exits;
  final int pendingOrders;
  final VoidCallback onRefresh;

  const _SummaryCard({
    required this.isLoading,
    required this.entries,
    required this.exits,
    required this.pendingOrders,
    required this.onRefresh,
  });

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ' ',
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Entrées de stock',
        _formatNumber(entries),
        Icons.south_west_rounded,
        const Color(0xFF14A579),
        const Color(0xFFE4F8F0),
      ),
      (
        'Sorties de stock',
        _formatNumber(exits),
        Icons.north_east_rounded,
        AppColors.primary,
        const Color(0xFFFFE8EC),
      ),
      (
        'Commandes en attente',
        _formatNumber(pendingOrders),
        Icons.pending_actions_rounded,
        const Color(0xFFE9A23B),
        const Color(0xFFFFF3DF),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Résumé de l’activité',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'Actualiser',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.muted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Quantités et commandes du mois',
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
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
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
