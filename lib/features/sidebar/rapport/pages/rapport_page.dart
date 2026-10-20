import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/rapport_pdf_service.dart';

class RapportsPage extends StatefulWidget {
  final String businessId;

  const RapportsPage({super.key, required this.businessId});

  @override
  State<RapportsPage> createState() => _RapportsPageState();
}

class _RapportsPageState extends State<RapportsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _period = '7 jours';
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _movements = [];
  Map<String, String> _categoryNames = {};

  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.green,
    AppColors.orange,
    AppColors.navy,
    Color(0xFF8B70D6),
    Color(0xFF3D9EC9),
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void didUpdateWidget(covariant RapportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.businessId != widget.businessId) {
      _loadReport();
    }
  }

  bool _exportingPdf = false;

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final days = _period == '30 jours'
          ? 30
          : _period == '90 jours'
          ? 90
          : 7;

      final startDate = now.subtract(Duration(days: days - 1));
      final start = DateTime(startDate.year, startDate.month, startDate.day);

      // 1. Produits de l'entreprise active.
      final productResponse = await _supabase
          .from('products')
          .select(
            'id, name, reference, category_id, price, quantity, minimum_quantity',
          )
          .eq('business_id', widget.businessId);

      final products = List<Map<String, dynamic>>.from(productResponse);

      // 2. Mouvements de la période sélectionnée.
      final movementResponse = await _supabase
          .from('stock_movements')
          .select(
            'id, product_id, product_name, movement_type, quantity, '
            'reason, confirmed_at, created_at',
          )
          .eq('business_id', widget.businessId)
          .gte('confirmed_at', start.toIso8601String())
          .order('confirmed_at', ascending: true);

      final movements = List<Map<String, dynamic>>.from(movementResponse);

      // 3. Noms des catégories.
      // Si la requête échoue, le rapport reste utilisable :
      // les produits concernés seront classés "Sans catégorie".
      Map<String, String> categoryNames = {};

      try {
        final categoryResponse = await _supabase
            .from('categories')
            .select('id, name')
            .eq('business_id', widget.businessId);

        for (final category in List<Map<String, dynamic>>.from(
          categoryResponse,
        )) {
          final id = category['id']?.toString();
          final name = category['name']?.toString();

          if (id != null && name != null) {
            categoryNames[id] = name;
          }
        }
      } catch (_) {
        // La page peut toujours calculer les autres indicateurs.
      }

      if (!mounted) return;

      setState(() {
        _products = products;
        _movements = movements;
        _categoryNames = categoryNames;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatNumber(num value) {
    final rounded = value.round();
    final text = rounded.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  String _formatMoney(double value) {
    return '${_formatNumber(value)} DT';
  }

  int get _totalProducts => _products.length;

  double get _stockValue {
    return _products.fold<double>(
      0,
      (sum, product) =>
          sum + _doubleValue(product['price']) * _intValue(product['quantity']),
    );
  }

  int get _totalEntries {
    return _movements.fold<int>(
      0,
      (sum, movement) =>
          sum +
          (movement['movement_type'] == 'entree'
              ? _intValue(movement['quantity'])
              : 0),
    );
  }

  int get _totalExits {
    return _movements.fold<int>(
      0,
      (sum, movement) =>
          sum +
          (movement['movement_type'] == 'sortie'
              ? _intValue(movement['quantity'])
              : 0),
    );
  }

  List<_ChartPoint> get _chartData {
    final int bucketCount;
    final List<String> labels;

    if (_period == '30 jours') {
      bucketCount = 5;
      labels = const ['S1', 'S2', 'S3', 'S4', 'S5'];
    } else if (_period == '90 jours') {
      bucketCount = 3;
      labels = const ['Début', 'Milieu', 'Fin'];
    } else {
      bucketCount = 7;
      final today = DateTime.now();

      labels = List.generate(7, (index) {
        final day = today.subtract(Duration(days: 6 - index));
        const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return names[day.weekday - 1];
      });
    }

    final entries = List<double>.filled(bucketCount, 0);
    final exits = List<double>.filled(bucketCount, 0);

    final days = _period == '7 jours'
        ? 7
        : _period == '30 jours'
        ? 30
        : 90;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final start = todayStart.subtract(Duration(days: days - 1));

    for (final movement in _movements) {
      final timestamp = DateTime.tryParse(
        (movement['confirmed_at'] ?? movement['created_at'] ?? '').toString(),
      );

      if (timestamp == null) continue;

      final date = timestamp.toLocal();
      final dateStart = DateTime(date.year, date.month, date.day);
      final elapsedDays = dateStart.difference(start).inDays;

      if (elapsedDays < 0 || elapsedDays >= days) continue;

      final int bucket;

      if (_period == '7 jours') {
        bucket = elapsedDays;
      } else if (_period == '30 jours') {
        bucket = (elapsedDays ~/ 7).clamp(0, 4);
      } else {
        bucket = (elapsedDays ~/ 30).clamp(0, 2);
      }

      final type = movement['movement_type'];
      final quantity = _intValue(movement['quantity']).toDouble();

      if (type == 'entree') {
        entries[bucket] += quantity;
      } else if (type == 'sortie') {
        exits[bucket] += quantity;
      }
    }

    return List.generate(
      bucketCount,
      (index) => _ChartPoint(labels[index], entries[index], exits[index]),
    );
  }

  Map<String, int> get _stockByCategory {
    final result = <String, int>{};

    for (final product in _products) {
      final categoryId = product['category_id']?.toString();

      final category = categoryId == null
          ? 'Sans catégorie'
          : _categoryNames[categoryId] ?? 'Sans catégorie';

      result[category] =
          (result[category] ?? 0) + _intValue(product['quantity']);
    }

    return result;
  }

  List<_TopProduct> get _topProducts {
    final counts = <String, int>{};

    for (final movement in _movements) {
      final name = movement['product_name']?.toString() ?? 'Produit inconnu';

      counts[name] = (counts[name] ?? 0) + 1;
    }

    final result = counts.entries
        .map((entry) => _TopProduct(entry.key, entry.value))
        .toList();

    result.sort((a, b) => b.movements.compareTo(a.movements));

    return result.take(5).toList();
  }

  List<Map<String, dynamic>> get _lowStockProducts {
    final result = _products.where((product) {
      final quantity = _intValue(product['quantity']);
      final minimum = _intValue(product['minimum_quantity']);

      return quantity <= minimum;
    }).toList();

    result.sort((a, b) {
      return _intValue(a['quantity']).compareTo(_intValue(b['quantity']));
    });

    return result;
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
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 100),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_error != null)
                  _buildError()
                else ...[
                  _buildPeriodSelector(),
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
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'StockMind • Rapports calculés à partir de vos données.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_loading || _exportingPdf) return;

    setState(() => _exportingPdf = true);

    try {
      await RapportPdfService.telechargerPdf(
        businessId: widget.businessId,
        period: _period,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement du rapport PDF lancé.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de téléchargement : $e')));
    } finally {
      if (mounted) {
        setState(() => _exportingPdf = false);
      }
    }
  }

  Future<void> _printReport() async {
    if (_loading || _exportingPdf) return;

    setState(() => _exportingPdf = true);

    try {
      await RapportPdfService.exporter(
        businessId: widget.businessId,
        period: _period,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’impression : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _exportingPdf = false);
      }
    }
  }

  Widget _buildHeader(bool compact) {
    final titleSection = Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: AppColors.primary,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rapports',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Analyse et suivi des performances de ton stock.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _loading || _exportingPdf ? null : _loadReport,
          tooltip: 'Actualiser les rapports',
          icon: const Icon(Icons.refresh_rounded, color: AppColors.navy),
        ),
        const SizedBox(width: 4),
        OutlinedButton(
          onPressed: (_loading || _exportingPdf) ? null : _downloadPdf,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Icon(Icons.download_rounded, size: 20),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: (_loading || _exportingPdf) ? null : _printReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: const Size(44, 44),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Icon(Icons.print_rounded, size: 20),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 16),
        actions,
      ],
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.primary,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger les rapports',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
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
                if (value == null || value == _period) return;

                setState(() {
                  _period = value;
                });

                _loadReport();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(bool compact) {
    final stats = [
      _ReportStat(
        title: 'Références produits',
        value: _formatNumber(_totalProducts),
        subtitle: 'Produits enregistrés',
        icon: Icons.inventory_2_outlined,
        color: AppColors.navy,
      ),
      _ReportStat(
        title: 'Valeur du stock',
        value: _formatMoney(_stockValue),
        subtitle: 'Valeur estimée actuelle',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.green,
      ),
      _ReportStat(
        title: 'Entrées de stock',
        value: _formatNumber(_totalEntries),
        subtitle: 'Unités entrées · $_period',
        icon: Icons.south_west_rounded,
        color: AppColors.green,
      ),
      _ReportStat(
        title: 'Sorties de stock',
        value: _formatNumber(_totalExits),
        subtitle: 'Unités sorties · $_period',
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
                fontSize: 23,
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
    final chartData = _chartData;

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
            'Entrées et sorties réelles · $_period',
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
            child:
                chartData.every(
                  (point) => point.entries == 0 && point.exits == 0,
                )
                ? const Center(
                    child: Text(
                      'Aucun mouvement sur cette période.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  )
                : CustomPaint(painter: _MovementChartPainter(chartData)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Le graphique compte les quantités enregistrées dans les mouvements.',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStockDistribution() {
    final distribution = _stockByCategory;
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            'Quantités actuelles par catégorie',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 155,
              width: 155,
              child: CustomPaint(
                painter: _DonutPainter(
                  entries.map((e) => e.value).toList(),
                  _colors,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatNumber(total),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 25,
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
          if (entries.isEmpty)
            const Text(
              'Aucun produit enregistré.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            )
          else
            ...entries.take(6).toList().asMap().entries.map((item) {
              final index = item.key;
              final category = item.value.key;
              final quantity = item.value.value;
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
                        color: _colors[index % _colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
    final products = _topProducts;
    final maxValue = products.isEmpty ? 1 : products.first.movements;

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
          Text(
            'Classement selon le nombre de mouvements · $_period',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 22),
          if (products.isEmpty)
            const Text(
              'Aucun mouvement enregistré sur cette période.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            )
          else
            ...products.asMap().entries.map((item) {
              final index = item.key;
              final product = item.value;
              final progress = product.movements / maxValue;

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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _colors[index % _colors.length],
                        ),
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
    final products = _lowStockProducts;

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
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.orange,
                size: 21,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Produits à surveiller',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${products.length}',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Produits dont la quantité est inférieure ou égale au seuil minimum.',
            style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 15),
          if (products.isEmpty)
            const Text(
              'Aucun produit à surveiller.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            )
          else
            ...products.take(10).map((product) {
              final quantity = _intValue(product['quantity']);
              final minimum = _intValue(product['minimum_quantity']);
              final outOfStock = quantity == 0;

              return Container(
                margin: const EdgeInsets.only(top: 9),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: outOfStock
                      ? const Color(0xFFFFE9ED)
                      : const Color(0xFFFFF8E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      outOfStock
                          ? Icons.remove_shopping_cart_outlined
                          : Icons.inventory_2_outlined,
                      color: outOfStock ? AppColors.primary : AppColors.orange,
                      size: 19,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name']?.toString() ?? 'Produit inconnu',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            outOfStock ? 'Rupture de stock' : 'Stock faible',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$quantity / $minimum',
                      style: TextStyle(
                        color: outOfStock
                            ? AppColors.primary
                            : AppColors.orange,
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

// -----------------------------------------------------------------------------
// MODÈLES ET GRAPHIQUES
// -----------------------------------------------------------------------------

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

class _TopProduct {
  final String name;
  final int movements;

  const _TopProduct(this.name, this.movements);
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
    if (points.isEmpty) return;

    const left = 8.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 25.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final maximum = points.fold<double>(
      1,
      (maxValue, point) => [
        maxValue,
        point.entries,
        point.exits,
      ].reduce((a, b) => a > b ? a : b),
    );

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

    final entryPath = Path();
    final exitPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x =
          left +
          (points.length == 1
              ? chartWidth / 2
              : chartWidth * i / (points.length - 1));

      final entryY = top + chartHeight * (1 - points[i].entries / maximum);
      final exitY = top + chartHeight * (1 - points[i].exits / maximum);

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

      final entryY = top + chartHeight * (1 - points[i].entries / maximum);
      final exitY = top + chartHeight * (1 - points[i].exits / maximum);

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
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(position.dx - painter.width / 2, position.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MovementChartPainter oldDelegate) => true;
}

class _DonutPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;

  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19
      ..strokeCap = StrokeCap.butt;

    var startAngle = -1.57079632679;

    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;

      final sweep = values[i] / total * 6.28318530718;
      paint.color = colors[i % colors.length];

      canvas.drawArc(rect.deflate(12), startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
