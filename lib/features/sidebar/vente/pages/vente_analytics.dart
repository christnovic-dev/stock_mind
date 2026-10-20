import 'package:flutter/material.dart';
import 'package:stockmind/features/core/services/currency_scope.dart';
import 'package:stockmind/features/core/services/currency_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);

class VentesAnalyticsPage extends StatefulWidget {
  final String businessId;

  const VentesAnalyticsPage({super.key, required this.businessId});

  @override
  State<VentesAnalyticsPage> createState() => _VentesAnalyticsPageState();
}

class _VentesAnalyticsPageState extends State<VentesAnalyticsPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  String _period = 'month';

  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _topProducts = [];

  double _revenue = 0;
  int _saleCount = 0;
  int _itemsSold = 0;
  int _cancelledCount = 0;

  String _money(num value) {
    return CurrencyService.format(
      value,
      currencyCode: CurrencyScope.of(context).currencyCode,
    );
  }

  num _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isCancelled(dynamic status) {
    final value = (status?.toString() ?? '').trim().toLowerCase();

    return {
      'cancelled',
      'canceled',
      'annule',
      'annulée',
      'annulee',
      'annulé',
      'refunded',
      'rembourse',
      'remboursé',
      'remboursee',
      'remboursée',
    }.contains(value);
  }

  DateTime _startOfPeriod() {
    final now = DateTime.now();

    switch (_period) {
      case 'day':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        final today = DateTime(now.year, now.month, now.day);
        return today.subtract(Duration(days: today.weekday - 1));
      case 'month':
        return DateTime(now.year, now.month, 1);
      case 'year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(2000, 1, 1);
    }
  }

  DateTime _endOfPeriod() {
    final now = DateTime.now();

    switch (_period) {
      case 'day':
        return DateTime(now.year, now.month, now.day + 1);
      case 'week':
        final today = DateTime(now.year, now.month, now.day);
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return monday.add(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month + 1, 1);
      case 'year':
        return DateTime(now.year + 1, 1, 1);
      default:
        return now.add(const Duration(days: 1));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // 1. Ventes directes enregistrées dans StockMind.
      var salesQuery = _supabase
          .from('sales')
          .select(
            'id, sale_number, customer_name, payment_method, '
            'total_amount, status, created_at',
          )
          .eq('business_id', widget.businessId);

      if (_period != 'all') {
        salesQuery = salesQuery
            .gte('created_at', _startOfPeriod().toUtc().toIso8601String())
            .lt('created_at', _endOfPeriod().toUtc().toIso8601String());
      }

      final rawSales = await salesQuery.order('created_at', ascending: false);

      final directSales = List<Map<String, dynamic>>.from(
        (rawSales as List).map((row) => Map<String, dynamic>.from(row as Map)),
      );

      final validSales = directSales
          .where((sale) => !_isCancelled(sale['status']))
          .toList();

      // 2. Commandes de la boutique confirmées.
      var ordersQuery = _supabase
          .from('orders')
          .select(
            'id, order_number, customer_name, total_amount, '
            'status, confirmed_at',
          )
          .eq('business_id', widget.businessId)
          .eq('status', 'confirmee')
          .not('confirmed_at', 'is', null);

      if (_period != 'all') {
        ordersQuery = ordersQuery
            .gte('confirmed_at', _startOfPeriod().toUtc().toIso8601String())
            .lt('confirmed_at', _endOfPeriod().toUtc().toIso8601String());
      }

      final rawOrders = await ordersQuery.order(
        'confirmed_at',
        ascending: false,
      );

      final confirmedOrders = List<Map<String, dynamic>>.from(
        (rawOrders as List).map((row) => Map<String, dynamic>.from(row as Map)),
      );

      // 3. Combiner les ventes et les commandes confirmées.
      final combinedHistory = <Map<String, dynamic>>[
        ...directSales,
        ...confirmedOrders.map(
          (order) => <String, dynamic>{
            'id': order['id'],
            'sale_number': 'CMD-${order['order_number']}',
            'customer_name': order['customer_name'],
            'payment_method': 'Commande boutique',
            'total_amount': order['total_amount'],
            'status': 'confirmee',
            'created_at': order['confirmed_at'],
            'source': 'boutique',
          },
        ),
      ];

      combinedHistory.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(2000);

        final dateB =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(2000);

        return dateB.compareTo(dateA);
      });

      final directRevenue = validSales.fold<double>(
        0,
        (total, sale) => total + _number(sale['total_amount']).toDouble(),
      );

      final orderRevenue = confirmedOrders.fold<double>(
        0,
        (total, order) => total + _number(order['total_amount']).toDouble(),
      );

      final cancelledCount = directSales
          .where((sale) => _isCancelled(sale['status']))
          .length;

      // 4. Agréger les articles des ventes directes.
      int itemsSold = 0;
      final products = <String, Map<String, dynamic>>{};

      void addProduct({
        required dynamic productId,
        required dynamic productName,
        required int quantity,
        required double revenue,
      }) {
        itemsSold += quantity;

        final key =
            productId?.toString() ?? productName?.toString() ?? 'inconnu';

        final product = products.putIfAbsent(
          key,
          () => {
            'name': productName?.toString() ?? 'Produit inconnu',
            'quantity': 0,
            'revenue': 0.0,
          },
        );

        product['quantity'] = (product['quantity'] as int) + quantity;
        product['revenue'] = (product['revenue'] as double) + revenue;
      }

      final saleIds = validSales.map((sale) => sale['id'].toString()).toList();

      if (saleIds.isNotEmpty) {
        final rawItems = await _supabase
            .from('sale_items')
            .select('sale_id, product_id, product_name, quantity, subtotal')
            .inFilter('sale_id', saleIds);

        for (final row in rawItems as List) {
          final item = Map<String, dynamic>.from(row as Map);

          addProduct(
            productId: item['product_id'],
            productName: item['product_name'],
            quantity: _number(item['quantity']).toInt(),
            revenue: _number(item['subtotal']).toDouble(),
          );
        }
      }

      // 5. Agréger les articles des commandes confirmées.
      final orderIds = confirmedOrders
          .map((order) => order['id'].toString())
          .toList();

      if (orderIds.isNotEmpty) {
        final rawOrderItems = await _supabase
            .from('order_items')
            .select(
              'order_id, product_id, product_name, quantity, '
              'unit_price, subtotal',
            )
            .inFilter('order_id', orderIds);

        for (final row in rawOrderItems as List) {
          final item = Map<String, dynamic>.from(row as Map);
          final quantity = _number(item['quantity']).toInt();

          // subtotal peut être NULL dans order_items.
          // On le recalcule alors à partir du prix unitaire historique.
          final subtotal = item['subtotal'] == null
              ? _number(item['unit_price']).toDouble() * quantity
              : _number(item['subtotal']).toDouble();

          addProduct(
            productId: item['product_id'],
            productName: item['product_name'],
            quantity: quantity,
            revenue: subtotal,
          );
        }
      }

      final topProducts = products.values.toList()
        ..sort(
          (a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int),
        );

      if (!mounted) return;

      setState(() {
        _sales = combinedHistory;
        _revenue = directRevenue + orderRevenue;
        _saleCount = validSales.length + confirmedOrders.length;
        _itemsSold = itemsSold;
        _cancelledCount = cancelledCount;
        _topProducts = topProducts.take(10).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return '—';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _paymentLabel(dynamic value) {
    switch (value?.toString()) {
      case 'especes':
        return 'Espèces';
      case 'carte':
        return 'Carte';
      case 'virement':
        return 'Virement';
      case 'cheque':
        return 'Chèque';
      case 'mobile_money':
        return 'Mobile Money';
      case 'autre':
        return 'Autre';
      default:
        return value?.toString() ?? 'Non renseigné';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: _loading
            ? ListView(
                children: [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.error_outline, size: 42, color: _red),
                  const SizedBox(height: 12),
                  const Text(
                    'Impossible de charger les ventes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton(
                      onPressed: _loadAnalytics,
                      child: const Text('Réessayer'),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildTitle(),
                  const SizedBox(height: 22),
                  _buildPeriodFilter(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 28),
                  _buildProducts(),
                  const SizedBox(height: 28),
                  _buildHistory(),
                  const SizedBox(height: 20),
                  Text(
                    'Les ventes annulées sont exclues des '
                    'indicateurs financiers.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyse des ventes',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: _navy,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Suivez votre chiffre d’affaires et vos produits vendus.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        const Text(
          'Période :',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _period,
              items: const [
                DropdownMenuItem(value: 'day', child: Text('Aujourd’hui')),
                DropdownMenuItem(value: 'week', child: Text('Cette semaine')),
                DropdownMenuItem(value: 'month', child: Text('Ce mois')),
                DropdownMenuItem(value: 'year', child: Text('Cette année')),
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Tout l’historique'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _period = value);
                _loadAnalytics();
              },
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _loadAnalytics,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Actualiser'),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;

        final cards = [
          _StatCard(
            title: 'Chiffre d’affaires',
            value: _money(_revenue),
            subtitle: 'Hors ventes annulées',
            icon: Icons.payments_outlined,
            color: _red,
          ),
          _StatCard(
            title: 'Ventes validées',
            value: '$_saleCount',
            subtitle: 'Transactions enregistrées',
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF287D55),
          ),
          _StatCard(
            title: 'Articles vendus',
            value: '$_itemsSold',
            subtitle: 'Quantité totale',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF4965C7),
          ),
          _StatCard(
            title: 'Ventes annulées',
            value: '$_cancelledCount',
            subtitle: 'Selon le statut enregistré',
            icon: Icons.remove_shopping_cart_outlined,
            color: const Color(0xFFCA8530),
          ),
        ];

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 3.0 : 1.7,
          children: cards,
        );
      },
    );
  }

  Widget _buildProducts() {
    return _Panel(
      title: 'Produits les plus vendus',
      subtitle: 'Classement selon les quantités vendues',
      child: _topProducts.isEmpty
          ? const _EmptyMessage(
              message: 'Aucun article vendu sur cette période.',
            )
          : Column(
              children: [
                for (var i = 0; i < _topProducts.length; i++)
                  _ProductRow(
                    rank: i + 1,
                    name: _topProducts[i]['name'].toString(),
                    quantity: _topProducts[i]['quantity'] as int,
                    revenue: _money(_number(_topProducts[i]['revenue'])),
                  ),
              ],
            ),
    );
  }

  Widget _buildHistory() {
    return _Panel(
      title: 'Historique des ventes',
      subtitle: '${_sales.length} transaction(s) dans la période',
      child: _sales.isEmpty
          ? const _EmptyMessage(message: 'Aucune vente pour cette période.')
          : Column(
              children: [
                for (final sale in _sales)
                  _SaleRow(
                    number:
                        sale['sale_number']?.toString() ??
                        sale['id'].toString(),
                    customer:
                        sale['customer_name']?.toString().trim().isNotEmpty ==
                            true
                        ? sale['customer_name'].toString()
                        : 'Client de passage',
                    date: _formatDate(sale['created_at']),
                    payment: _paymentLabel(sale['payment_method']),
                    amount: _money(_number(sale['total_amount'])),
                    cancelled: _isCancelled(sale['status']),
                  ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final int rank;
  final String name;
  final int quantity;
  final String revenue;

  const _ProductRow({
    required this.rank,
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8EC),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(color: _red, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$quantity vendu(s)',
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                revenue,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final String number;
  final String customer;
  final String date;
  final String payment;
  final String amount;
  final bool cancelled;

  const _SaleRow({
    required this.number,
    required this.customer,
    required this.date,
    required this.payment,
    required this.amount,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vente #$number',
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: cancelled ? _muted : _navy,
                  fontWeight: FontWeight.w800,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _Detail(icon: Icons.person_outline, text: customer),
              _Detail(icon: Icons.schedule, text: date),
              _Detail(icon: Icons.payments_outlined, text: payment),
              if (cancelled)
                const Text(
                  'Annulée',
                  style: TextStyle(
                    color: _red,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Detail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _muted),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted),
        ),
      ),
    );
  }
}
