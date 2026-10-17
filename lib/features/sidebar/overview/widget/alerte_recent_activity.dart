import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BottomPanels extends StatelessWidget {
  final bool isMobile;
  final String businessId;
  final VoidCallback onViewProducts;

  const BottomPanels({
    super.key,
    required this.isMobile,
    required this.businessId,
    required this.onViewProducts,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 950;

        final alerts = _LowStockCard(
          businessId: businessId,
          onViewProducts: onViewProducts,
        );

        final activity = _RecentActivityCard(businessId: businessId);

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [alerts, const SizedBox(height: 18), activity],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: alerts),
            const SizedBox(width: 18),
            Expanded(flex: 5, child: activity),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// ALERTES DE STOCK
// -----------------------------------------------------------------------------

class _LowStockCard extends StatefulWidget {
  final String businessId;
  final VoidCallback onViewProducts;

  const _LowStockCard({required this.businessId, required this.onViewProducts});

  @override
  State<_LowStockCard> createState() => _LowStockCardState();
}

class _LowStockCardState extends State<_LowStockCard> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLowStockProducts();
  }

  @override
  void didUpdateWidget(covariant _LowStockCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.businessId != widget.businessId) {
      _loadLowStockProducts();
    }
  }

  Future<void> _loadLowStockProducts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await _supabase
          .from('products')
          .select('id, name, reference, quantity, minimum_quantity, image_url')
          .eq('business_id', widget.businessId);

      final products = List<Map<String, dynamic>>.from(response);

      // PostgREST ne permet pas directement de comparer deux colonnes
      // avec un filtre simple. On compare donc quantity et minimum_quantity
      // après avoir récupéré uniquement les produits de cette entreprise.
      final lowStockProducts = products.where((product) {
        final quantity = _toInt(product['quantity']);
        final minimum = _toInt(product['minimum_quantity']);

        return quantity <= minimum;
      }).toList();

      lowStockProducts.sort((a, b) {
        return _toInt(a['quantity']).compareTo(_toInt(b['quantity']));
      });

      if (!mounted) return;

      setState(() {
        _products = lowStockProducts;
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE88A20),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alertes de stock',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Produits à réapprovisionner',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!_loading && _error == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _products.isEmpty
                        ? const Color(0xFFE9F8EF)
                        : const Color(0xFFFFF0E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_products.length} alerte${_products.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: _products.isEmpty
                          ? const Color(0xFF219653)
                          : const Color(0xFFE88A20),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null)
            _PanelMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Impossible de charger les alertes.',
              actionLabel: 'Réessayer',
              onAction: _loadLowStockProducts,
            )
          else if (_products.isEmpty)
            const _PanelMessage(
              icon: Icons.check_circle_outline_rounded,
              message: 'Tous vos produits ont un stock suffisant.',
            )
          else
            ..._products.take(4).map(_buildProductRow),

          if (!_loading && _error == null && _products.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${_products.length - 4} autre(s) produit(s) à surveiller',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onViewProducts,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voir tous les produits',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 7),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(
    Map<String, dynamic> product,
    Color statusColor,
    bool isOutOfStock,
  ) {
    final imageUrl = product['image_url']?.toString().trim() ?? '';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildProductPlaceholder(statusColor, isOutOfStock);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                return Center(
                  child: SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  ),
                );
              },
            )
          : _buildProductPlaceholder(statusColor, isOutOfStock),
    );
  }

  Widget _buildProductPlaceholder(Color statusColor, bool isOutOfStock) {
    return Center(
      child: Icon(
        isOutOfStock
            ? Icons.remove_shopping_cart_outlined
            : Icons.inventory_2_outlined,
        color: statusColor,
        size: 20,
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Produit sans nom';
    final reference = product['reference']?.toString() ?? '';
    final quantity = _toInt(product['quantity']);
    final minimum = _toInt(product['minimum_quantity']);
    final isOutOfStock = quantity == 0;

    final statusColor = isOutOfStock
        ? AppColors.primary
        : const Color(0xFFE88A20);

    final statusText = isOutOfStock ? 'Rupture' : 'Stock faible';

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          _buildProductImage(product, statusColor, isOutOfStock),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reference.isEmpty ? statusText : '$reference • $statusText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$quantity',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Min. $minimum',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ACTIVITÉ RÉCENTE
// -----------------------------------------------------------------------------

class _RecentActivityCard extends StatefulWidget {
  final String businessId;

  const _RecentActivityCard({required this.businessId});

  @override
  State<_RecentActivityCard> createState() => _RecentActivityCardState();
}

class _RecentActivityCardState extends State<_RecentActivityCard> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _movements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentMovements();
  }

  @override
  void didUpdateWidget(covariant _RecentActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.businessId != widget.businessId) {
      _loadRecentMovements();
    }
  }

  Future<void> _loadRecentMovements() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await _supabase
          .from('stock_movements')
          .select(
            'id, product_name, movement_type, quantity, reason, '
            'counterparty_name, confirmed_by_name, confirmed_at, created_at',
          )
          .eq('business_id', widget.businessId)
          .order('confirmed_at', ascending: false)
          .limit(5);

      if (!mounted) return;

      setState(() {
        _movements = List<Map<String, dynamic>>.from(response);
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

  @override
  Widget build(BuildContext context) {
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
              _ActivityHeaderIcon(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activité récente',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Derniers mouvements enregistrés',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null)
            _PanelMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Impossible de charger les mouvements.',
              actionLabel: 'Réessayer',
              onAction: _loadRecentMovements,
            )
          else if (_movements.isEmpty)
            const _PanelMessage(
              icon: Icons.history_rounded,
              message: 'Aucun mouvement de stock enregistré pour le moment.',
            )
          else
            ..._movements.map(_buildMovementRow),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadRecentMovements,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Actualiser',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementRow(Map<String, dynamic> movement) {
    final type = movement['movement_type']?.toString() ?? '';
    final quantity = _toInt(movement['quantity']);
    final productName =
        movement['product_name']?.toString() ?? 'Produit supprimé';

    final Color color;
    final Color background;
    final IconData icon;
    final String label;
    final String sign;

    switch (type) {
      case 'entree':
        color = const Color(0xFF219653);
        background = const Color(0xFFE9F8EF);
        icon = Icons.south_west_rounded;
        label = 'Entrée de stock';
        sign = '+';
        break;
      case 'sortie':
        color = AppColors.primary;
        background = const Color(0xFFFFE9ED);
        icon = Icons.north_east_rounded;
        label = 'Sortie de stock';
        sign = '-';
        break;
      case 'ajustement':
        color = const Color(0xFFE88A20);
        background = const Color(0xFFFFF0E2);
        icon = Icons.tune_rounded;
        label = 'Ajustement de stock';
        sign = '';
        break;
      default:
        color = AppColors.muted;
        background = const Color(0xFFF0F2F7);
        icon = Icons.inventory_2_outlined;
        label = 'Mouvement de stock';
        sign = '';
    }

    final reason = movement['reason']?.toString() ?? '';
    final counterparty = movement['counterparty_name']?.toString() ?? '';
    final confirmedBy = movement['confirmed_by_name']?.toString() ?? '';
    final timestamp = movement['confirmed_at'] ?? movement['created_at'];

    final details = <String>[
      if (reason.isNotEmpty) reason,
      if (counterparty.isNotEmpty) counterparty,
      if (confirmedBy.isNotEmpty) 'Par $confirmedBy',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    details.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(timestamp),
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign$quantity',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date inconnue';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return 'Date inconnue';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60 && !difference.isNegative) {
      return 'À l’instant';
    }
    if (difference.inMinutes < 60 && !difference.isNegative) {
      return 'Il y a ${difference.inMinutes} min';
    }
    if (difference.inHours < 24 && !difference.isNegative) {
      return 'Il y a ${difference.inHours} h';
    }
    if (difference.inDays == 1) {
      return 'Hier à ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    }

    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year} '
        'à ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

// -----------------------------------------------------------------------------
// PETITS COMPOSANTS
// -----------------------------------------------------------------------------

class _ActivityHeaderIcon extends StatelessWidget {
  const _ActivityHeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.history_rounded,
        color: Color(0xFF4263C7),
        size: 22,
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PanelMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppColors.muted, size: 28),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
