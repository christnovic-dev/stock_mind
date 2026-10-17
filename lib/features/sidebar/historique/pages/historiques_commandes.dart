import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/invoice_pdf_service.dart';

class HistoriqueCommandesPage extends StatefulWidget {
  final String businessId;

  const HistoriqueCommandesPage({super.key, required this.businessId});

  @override
  State<HistoriqueCommandesPage> createState() =>
      _HistoriqueCommandesPageState();
}

class _HistoriqueCommandesPageState extends State<HistoriqueCommandesPage> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  String _filter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.businessId.trim().isEmpty) {
        throw Exception('Aucune entreprise sélectionnée.');
      }

      final result = await _client
          .from('orders')
          .select('''
            id,
            order_number,
            customer_name,
            customer_phone,
            customer_city,
            customer_address,
            total_amount,
            status,
            created_at,
            updated_at,
            order_items(
              id,
              product_name,
              quantity,
              unit_price,
              subtotal
            )
          ''')
          .eq('business_id', widget.businessId.trim())
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        // Les commandes en attente restent dans Ma boutique.
        _orders = result
            .map((item) => Map<String, dynamic>.from(item))
            .where(
              (order) => (order['status'] ?? '').toString() != 'en_attente',
            )
            .toList();
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

  Future<void> _openInvoice(Map<String, dynamic> order) async {
    final orderId = (order['id'] ?? '').toString();
    final businessId = widget.businessId.trim();
    final status = (order['status'] ?? '').toString();

    if (status != 'confirmee' && status != 'confirmée') {
      return;
    }

    if (orderId.isEmpty || businessId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande ou entreprise introuvable.')),
      );
      return;
    }

    try {
      // Retrouver la facture déjà créée par la fonction SQL.
      final invoice = await _client
          .from('invoices')
          .select('id, invoice_number')
          .eq('business_id', businessId)
          .eq('order_id', orderId)
          .maybeSingle();

      if (!mounted) return;

      if (invoice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aucune facture enregistrée pour cette commande. '
              'Les anciennes commandes confirmées doivent être traitées séparément.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      await InvoicePdfService.printInvoice(
        invoiceId: invoice['id'].toString(),
        businessId: businessId,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’ouvrir la facture : $e'),
          duration: const Duration(seconds: 5),
        ),
      );
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
        return 'Confirmée';
      case 'annulee':
      case 'annulée':
        return 'Annulée';
      case 'terminee':
      case 'terminée':
        return 'Terminée';
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
      case 'terminee':
      case 'terminée':
        return const Color(0xFF168653);
      case 'annulee':
      case 'annulée':
        return const Color(0xFFD92D20);
      default:
        return AppColors.muted;
    }
  }

  String _money(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return amount.toStringAsFixed(2);
  }

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Date inconnue';

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(date.day)}/${two(date.month)}/${date.year} '
        'à ${two(date.hour)}:${two(date.minute)}';
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();

    return _orders.where((order) {
      final status = (order['status'] ?? '').toString();
      final number = (order['order_number'] ?? order['id'] ?? '')
          .toString()
          .toLowerCase();
      final customer = (order['customer_name'] ?? '').toString().toLowerCase();
      final phone = (order['customer_phone'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          number.contains(query) ||
          customer.contains(query) ||
          phone.contains(query);

      final matchesFilter = switch (_filter) {
        'Confirmées' => status == 'confirmee' || status == 'confirmée',
        'Annulées' => status == 'annulee' || status == 'annulée',
        'En cours' => status == 'en_cours',
        'Terminées' => status == 'terminee' || status == 'terminée',
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Retrouve les commandes déjà traitées par ton entreprise.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un client ou une commande...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _filter,
                decoration: InputDecoration(
                  labelText: 'Filtrer par statut',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Toutes',
                    child: Text('Toutes les commandes traitées'),
                  ),
                  DropdownMenuItem(
                    value: 'Confirmées',
                    child: Text('Confirmées'),
                  ),
                  DropdownMenuItem(value: 'Annulées', child: Text('Annulées')),
                  DropdownMenuItem(value: 'En cours', child: Text('En cours')),
                  DropdownMenuItem(
                    value: 'Terminées',
                    child: Text('Terminées'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _filter = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              Text(
                '${orders.length} commande(s)',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_outlined,
                              size: 38,
                              color: AppColors.muted,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Impossible de charger l’historique.\n$_error',
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: _loadOrders,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: AppColors.muted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Aucune commande trouvée.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildOrderCard(orders[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = (order['id'] ?? '').toString();
    final number = (order['order_number'] ?? '').toString();
    final displayNumber = number.isNotEmpty
        ? number
        : (id.length >= 8 ? id.substring(0, 8).toUpperCase() : id);

    final status = (order['status'] ?? '').toString();
    final customer = (order['customer_name'] ?? 'Client').toString();
    final items = (order['order_items'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Commande #$displayNumber',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
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
          if (status == 'confirmee' || status == 'confirmée') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openInvoice(order),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Voir la facture PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _dateLabel(order['created_at']),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const Divider(height: 24),
          Text(
            customer,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((order['customer_phone'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tél. : ${order['customer_phone']}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
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
                  Text(
                    '${_money(item['subtotal'] ?? 0)} DT',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Montant total',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${_money(order['total_amount'])} DT',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
