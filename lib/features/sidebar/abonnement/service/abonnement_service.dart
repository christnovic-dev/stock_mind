import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/abonnement_model.dart';

class AbonnementService {
  AbonnementService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<List<AbonnementPlan>> getPlans() async {
    final rows = await _client
        .from('subscription_plans')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((e) => AbonnementPlan.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<BusinessSubscription?> getCurrentSubscription(
    String businessId,
  ) async {
    final rows = await _client
        .from('business_subscriptions')
        .select('*, subscription_plans(name)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return BusinessSubscription.fromMap(Map<String, dynamic>.from(rows.first));
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(
    String businessId,
  ) async {
    final rows = await _client
        .from('subscription_payments')
        .select(
          'id, amount, currency, status, paid_at, created_at, provider, invoice_url',
        )
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(10);
    return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<String> startCheckout({
    required String businessId,
    required String planId,
  }) async {
    final response = await _client.functions.invoke(
      'create-paypal-subscription',
      body: {'business_id': businessId, 'plan_id': planId},
    );
    if (response.status < 200 || response.status >= 300) {
      throw Exception(
        'Impossible de démarrer le paiement. Réessaie plus tard.',
      );
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    final url = data['approval_url']?.toString();
    if (url == null || url.isEmpty)
      throw Exception('PayPal n’a pas retourné de lien de paiement.');
    return url;
  }
}
