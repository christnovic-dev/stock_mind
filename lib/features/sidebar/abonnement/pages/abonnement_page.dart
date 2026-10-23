import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../service/abonnement_service.dart';
import '../widgets/abonnement_model.dart';

const _red = Color(0xFFF21D3D);
const _navy = Color(0xFF14264B);
const _background = Color(0xFFF7F8FC);
const _muted = Color(0xFF7B8498);
const _border = Color(0xFFE9ECF3);

class AbonnementPage extends StatefulWidget {
  final String businessId;
  const AbonnementPage({super.key, required this.businessId});
  @override
  State<AbonnementPage> createState() => _AbonnementPageState();
}

class _AbonnementPageState extends State<AbonnementPage> {
  final _service = AbonnementService();
  bool _loading = true;
  bool _checkoutLoading = false;
  String? _error;
  List<AbonnementPlan> _plans = [];
  BusinessSubscription? _subscription;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getPlans(),
        _service.getCurrentSubscription(widget.businessId),
        _service.getPaymentHistory(widget.businessId),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<AbonnementPlan>;
        _subscription = results[1] as BusinessSubscription?;
        _payments = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _money(num? amount, String currency) {
    if (amount == null) return 'Tarif à définir';
    if (amount == 0) return 'Gratuit';
    try {
      return '${NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 2).format(amount).trim()} $currency / mois';
    } catch (_) {
      return '${amount.toStringAsFixed(2)} $currency / mois';
    }
  }

  String _status(String value) => switch (value) {
    'active' => 'Actif',
    'pending' => 'En attente de paiement',
    'approval_pending' => 'Validation PayPal requise',
    'suspended' => 'Suspendu',
    'cancelled' => 'Résilié',
    'expired' => 'Expiré',
    'past_due' => 'Paiement en retard',
    _ => value,
  };

  Color _statusColor(String value) => value == 'active'
      ? const Color(0xFF178653)
      : (value == 'pending' || value == 'approval_pending')
      ? const Color(0xFFB7791F)
      : _red;

  Future<void> _checkout(AbonnementPlan plan) async {
    if (plan.id == 'free') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le forfait Gratuit est attribué par défaut. Contacte le support pour y revenir.',
          ),
        ),
      );
      return;
    }
    if (plan.monthlyPrice == null ||
        plan.monthlyPrice! <= 0 ||
        (plan.paypalPlanId ?? '').isEmpty) {
      _message(
        'Ce forfait n’est pas encore configuré pour le paiement. Les tarifs et les identifiants PayPal doivent être renseignés.',
      );
      return;
    }
    setState(() => _checkoutLoading = true);
    try {
      final url = await _service.startCheckout(
        businessId: widget.businessId,
        planId: plan.id,
      );
      if (!mounted) return;
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened)
        _message(
          'Impossible d’ouvrir PayPal. Vérifie que ton navigateur autorise les fenêtres externes.',
        );
      else
        _message(
          'Termine le paiement sur PayPal. Le statut sera actualisé après confirmation du paiement.',
        );
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _checkoutLoading = false);
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _red))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _header(),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _errorBox(_error!),
                  ] else ...[
                    const SizedBox(height: 22),
                    _currentPlanCard(),
                    const SizedBox(height: 28),
                    const Text(
                      'Choisir un forfait',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Les paiements récurrents sont sécurisés par PayPal. Les données de carte ne transitent pas par StockMind.',
                      style: TextStyle(color: _muted, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1100
                            ? 3
                            : constraints.maxWidth >= 680
                            ? 2
                            : 1;
                        final width = columns == 1
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 16 * (columns - 1)) /
                                  columns;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _plans
                              .map(
                                (plan) => SizedBox(
                                  width: width,
                                  child: _planCard(plan),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    _paymentHistory(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _red.withOpacity(.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.workspace_premium_outlined, color: _red),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abonnement',
              style: TextStyle(
                color: _navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Gérez le forfait et la facturation de votre entreprise',
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Actualiser',
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded, color: _navy),
      ),
    ],
  );

  Widget _currentPlanCard() {
    final sub = _subscription;
    final plan = _plans
        .where((p) => p.id == (sub?.planId ?? 'free'))
        .firstOrNull;
    final status = sub?.status ?? 'active';
    final title = sub?.planName ?? plan?.name ?? 'Gratuit';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Votre abonnement actuel',
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              _statusChip(
                sub == null ? 'active' : status,
                sub == null ? 'Gratuit' : _status(status),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      plan == null
                          ? 'Forfait de base StockMind'
                          : plan.description,
                      style: const TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
              if (plan != null)
                Text(
                  _money(plan.monthlyPrice, plan.currency),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (sub?.currentPeriodEnd != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 18, color: _muted),
                const SizedBox(width: 7),
                Text(
                  'Prochaine échéance / fin de période : ${DateFormat('dd/MM/yyyy').format(sub!.currentPeriodEnd!.toLocal())}',
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ],
          if (sub != null &&
              (sub.status == 'pending' ||
                  sub.status == 'approval_pending')) ...[
            const SizedBox(height: 12),
            const Text(
              'Le paiement est en attente. Actualisez la page après avoir terminé sur PayPal.',
              style: TextStyle(color: Color(0xFFB7791F)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _planCard(AbonnementPlan plan) {
    final current =
        (_subscription?.planId ?? 'free') == plan.id &&
        (_subscription == null || _subscription!.status == 'active');
    final featured = plan.id == 'pro';
    final configured =
        plan.id == 'free' ||
        ((plan.monthlyPrice ?? 0) > 0 && (plan.paypalPlanId ?? '').isNotEmpty);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: featured ? _red : _border,
          width: featured ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: featured
            ? [
                BoxShadow(
                  color: _red.withOpacity(.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _navy,
                  ),
                ),
              ),
              if (featured)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'POPULAIRE',
                    style: TextStyle(
                      color: _red,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: Text(
              plan.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, height: 1.4),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _money(plan.monthlyPrice, plan.currency),
            style: const TextStyle(
              color: _navy,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: _border),
          const SizedBox(height: 8),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Color(0xFF178653),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(color: _navy, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: current || _checkoutLoading || !configured
                  ? null
                  : () => _checkout(plan),
              style: OutlinedButton.styleFrom(
                foregroundColor: featured ? Colors.white : _navy,
                backgroundColor: featured ? _red : Colors.white,
                side: BorderSide(color: featured ? _red : _border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                current
                    ? 'Forfait actuel'
                    : plan.id == 'free'
                    ? 'Forfait gratuit'
                    : configured
                    ? 'Choisir ce forfait'
                    : 'Configuration requise',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (!configured && plan.id != 'free')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Tarif ou plan PayPal non configuré.',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentHistory() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des paiements',
          style: TextStyle(
            color: _navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        if (_payments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Aucun paiement enregistré pour le moment.',
              style: TextStyle(color: _muted),
            ),
          )
        else
          ..._payments.map((p) {
            final date = DateTime.tryParse(
              (p['paid_at'] ?? p['created_at'] ?? '').toString(),
            );
            final amount = (p['amount'] as num?)?.toDouble() ?? 0;
            final currency = p['currency']?.toString() ?? 'EUR';
            final status = p['status']?.toString() ?? 'pending';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: _muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date == null
                              ? 'Date non disponible'
                              : DateFormat('dd/MM/yyyy').format(date.toLocal()),
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _status(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(2)} $currency',
                    style: const TextStyle(
                      color: _navy,
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

  Widget _statusChip(String status, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _statusColor(status).withOpacity(.10),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: _statusColor(status),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  Widget _errorBox(String error) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impossible de charger les abonnements',
          style: const TextStyle(fontWeight: FontWeight.w800, color: _navy),
        ),
        const SizedBox(height: 8),
        Text(error, style: const TextStyle(color: _muted)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
      ],
    ),
  );
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
