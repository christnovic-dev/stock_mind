import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommandesRecuesSection extends StatefulWidget {
  final String businessId;

  const CommandesRecuesSection({super.key, required this.businessId});

  @override
  State<CommandesRecuesSection> createState() => _CommandesRecuesSectionState();
}

class _CommandesRecuesSectionState extends State<CommandesRecuesSection> {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _orders = [];
  String? _error;

  bool _loading = true;
  String? _processingOrderId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final businessId = widget.businessId.trim();

      debugPrint('========== STOCKMIND COMMANDES ==========');
      debugPrint('Business ID reçu : $businessId');

      if (businessId.isEmpty) {
        throw Exception('Aucune entreprise sélectionnée.');
      }

      final result = await _client
          .from('orders')
          .select('''
          id,
          business_id,
          order_number,
          customer_name,
          customer_phone,
          customer_address,
          customer_city,
          total_amount,
          status,
          created_at,
          updated_at,
          order_items(
            id,
            product_id,
            product_name,
            quantity,
            unit_price,
            subtotal
          )
        ''')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      debugPrint('Nombre de commandes reçues : ${result.length}');
      debugPrint('Données reçues : $result');

      if (!mounted) return;

      setState(() {
        _orders = result
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('ERREUR COMMANDES : $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus(
    Map<String, dynamic> order,
    String newStatus,
  ) async {
    final id = order['id']?.toString();
    final businessId = widget.businessId.trim();

    if (id == null || id.isEmpty || businessId.isEmpty) return;

    final isConfirming = newStatus == 'confirmee';

    if (!isConfirming && newStatus != 'annulee') {
      return;
    }

    final action = isConfirming ? 'confirmer' : 'annuler';

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isConfirming ? 'Confirmer la commande ?' : 'Annuler la commande ?',
        ),
        content: Text(
          isConfirming
              ? 'Le stock sera mis à jour et les mouvements de sortie '
                    'seront enregistrés.'
              : 'Cette commande sera marquée comme annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isConfirming
                  ? AppColors.primary
                  : const Color(0xFFD92D20),
              foregroundColor: Colors.white,
            ),
            child: Text(isConfirming ? 'Confirmer' : 'Annuler la commande'),
          ),
        ],
      ),
    );

    if (accepted != true || !mounted) return;

    setState(() => _processingOrderId = id);

    try {
      if (isConfirming) {
        // Une seule transaction Supabase :
        // statut + stock + mouvements.
        await _client.rpc(
          'confirm_stock_order',
          params: {'p_order_id': id, 'p_business_id': businessId},
        );
      } else {
        // L'annulation d'une commande encore en attente
        // ne modifie pas le stock.
        final updated = await _client
            .from('orders')
            .update({
              'status': 'annulee',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', id)
            .eq('business_id', businessId)
            .eq('status', 'en_attente')
            .select('id');

        if ((updated as List).isEmpty) {
          throw Exception(
            'Cette commande a déjà été traitée ou vous '
            'ne pouvez pas la modifier.',
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConfirming
                ? 'Commande confirmée, stock mis à jour et mouvements enregistrés.'
                : 'Commande annulée.',
          ),
        ),
      );

      await _loadOrders();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de $action la commande : '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );

      // Recharger pour refléter l'état réel de Supabase.
      await _loadOrders();
    } finally {
      if (mounted) {
        setState(() => _processingOrderId = null);
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'confirmee':
      case 'confirmée':
        return 'Livrée';
      case 'annulee':
      case 'annulée':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'en_attente':
        return const Color(0xFFB7791F);
      case 'en_cours':
        return const Color(0xFF1457FF);
      case 'confirmee':
      case 'confirmée':
        return const Color(0xFF168653);
      case 'annulee':
      case 'annulée':
        return const Color(0xFFD92D20);
      default:
        return AppColors.muted;
    }
  }

  String _dateLabel(dynamic value) {
    if (value == null) return 'Date inconnue';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return 'Date inconnue';

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        'à ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  String _money(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
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
                  color: const Color(0xFFFCE7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commandes reçues',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_orders.length} commande(s) au total',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualiser les commandes',
                onPressed: _loading ? null : _loadOrders,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null)
            _buildMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Impossible de charger les commandes.\n$_error',
              action: TextButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            )
          else if (_orders.isEmpty)
            _buildMessage(
              icon: Icons.inbox_outlined,
              message: 'Aucune commande reçue pour le moment.',
            )
          else
            Column(
              children: [
                for (final order in _orders) ...[
                  _buildOrderCard(order),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted, size: 35),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = order['id']?.toString() ?? '';
    final status = (order['status'] ?? 'en_attente').toString();
    final isPending = status == 'en_attente';
    final isProcessing = _processingOrderId == id;
    final items = (order['order_items'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final orderNumber = order['order_number']?.toString();
    final displayNumber = orderNumber != null && orderNumber.isNotEmpty
        ? orderNumber
        : (id.length >= 8 ? id.substring(0, 8).toUpperCase() : id);

    final customerName = (order['customer_name'] ?? 'Client').toString();

    final location = [order['customer_city'], order['customer_address']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFE),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                'Commande #$displayNumber',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _dateLabel(order['created_at']),
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const Divider(height: 24, color: AppColors.border),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: AppColors.muted,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if ((order['customer_phone'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tél. : ${order['customer_phone']}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text(
            'Articles commandés',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          if (items.isEmpty)
            const Text(
              'Les détails des articles ne sont pas disponibles.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['product_name'] ?? 'Produit'} × '
                        '${item['quantity'] ?? 0}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _money(
                        item['subtotal'] ??
                            ((item['unit_price'] ?? 0) *
                                ((item['quantity'] ?? 0) as num)),
                      ),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

          const Divider(height: 24, color: AppColors.border),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Montant total',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _money(order['total_amount']),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          if (isPending) ...[
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 390;

                final confirmButton = ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _changeStatus(order, 'confirmee'),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Confirmer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF168653),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );

                final cancelButton = OutlinedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _changeStatus(order, 'annulee'),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD92D20),
                    side: const BorderSide(color: Color(0xFFF1C5C2)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      confirmButton,
                      const SizedBox(height: 8),
                      cancelButton,
                      if (isProcessing)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    confirmButton,
                    cancelButton,
                    if (isProcessing)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
