import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsGrid extends StatefulWidget {
  final bool isMobile;
  final String businessId;

  const StatsGrid({
    super.key,
    required this.isMobile,
    required this.businessId,
  });

  @override
  State<StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<StatsGrid> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  int _totalProducts = 0;
  int _lowStock = 0;
  int _outOfStock = 0;
  double _stockValue = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(covariant StatsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.businessId != widget.businessId) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
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
      final response = await _supabase
          .from('products')
          .select('id, price, quantity, minimum_quantity')
          .eq('business_id', widget.businessId);

      int total = 0;
      int lowStock = 0;
      int outOfStock = 0;
      double stockValue = 0;

      for (final item in response) {
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final minimumQuantity =
            (item['minimum_quantity'] as num?)?.toInt() ?? 0;
        final price = (item['price'] as num?)?.toDouble() ?? 0;

        total++;
        stockValue += price * quantity;

        if (quantity == 0) {
          outOfStock++;
        } else if (quantity <= minimumQuantity) {
          lowStock++;
        }
      }

      if (!mounted) return;

      setState(() {
        _totalProducts = total;
        _lowStock = lowStock;
        _outOfStock = outOfStock;
        _stockValue = stockValue;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les statistiques.';
      });

      debugPrint('Erreur StatsGrid Supabase : $e');
    }
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ' ',
    );
  }

  String _formatMoney(double value) {
    return '${_formatNumber(value.round())} DT';
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        title: 'Total des produits',
        value: _formatNumber(_totalProducts),
        detail: 'Produits enregistrés',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF4778F5),
        bg: const Color(0xFFEAF0FF),
      ),
      _StatData(
        title: 'Valeur du stock',
        value: _formatMoney(_stockValue),
        detail: 'Valeur estimée',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF14A579),
        bg: const Color(0xFFE4F8F0),
      ),
      _StatData(
        title: 'Stock faible',
        value: _formatNumber(_lowStock),
        detail: 'À réapprovisionner',
        icon: Icons.trending_down_rounded,
        color: const Color(0xFFE9A23B),
        bg: const Color(0xFFFFF3DF),
      ),
      _StatData(
        title: 'En rupture',
        value: _formatNumber(_outOfStock),
        detail: 'Action nécessaire',
        icon: Icons.warning_amber_rounded,
        color: AppColors.primary,
        bg: const Color(0xFFFFE8EC),
      ),
    ];

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
                const Expanded(
                  child: Text(
                    'Erreur de chargement des statistiques.',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: _loadStats,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 560
                ? 1
                : constraints.maxWidth < 1000
                ? 2
                : 4;

            final cardWidth =
                (constraints.maxWidth - (columns - 1) * 16) / columns;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: stats.map((stat) {
                return SizedBox(
                  width: cardWidth,
                  child: _StatCard(data: stat, isLoading: _isLoading),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  final bool isLoading;

  const _StatCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
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
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 21),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 33,
            child: Align(
              alignment: Alignment.centerLeft,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        data.value,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            data.detail,
            style: TextStyle(
              color: data.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
