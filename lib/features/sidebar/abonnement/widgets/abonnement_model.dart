class AbonnementPlan {
  final String id;
  final String name;
  final String description;
  final double? monthlyPrice;
  final String currency;
  final List<String> features;
  final Map<String, dynamic> limits;
  final String? paypalPlanId;
  final bool isActive;

  const AbonnementPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.currency,
    required this.features,
    required this.limits,
    required this.paypalPlanId,
    required this.isActive,
  });

  factory AbonnementPlan.fromMap(Map<String, dynamic> map) => AbonnementPlan(
    id: map['id'] as String,
    name: map['name'] as String? ?? map['id'] as String,
    description: map['description'] as String? ?? '',
    monthlyPrice: map['monthly_price'] == null
        ? null
        : (map['monthly_price'] as num).toDouble(),
    currency: map['currency'] as String? ?? 'EUR',
    features: (map['features'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
    limits: Map<String, dynamic>.from(map['limits'] as Map? ?? const {}),
    paypalPlanId: map['paypal_plan_id'] as String?,
    isActive: map['is_active'] as bool? ?? true,
  );
}

class BusinessSubscription {
  final String id;
  final String businessId;
  final String planId;
  final String status;
  final String provider;
  final String? providerSubscriptionId;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime createdAt;
  final String? planName;

  const BusinessSubscription({
    required this.id,
    required this.businessId,
    required this.planId,
    required this.status,
    required this.provider,
    required this.providerSubscriptionId,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.createdAt,
    required this.planName,
  });

  factory BusinessSubscription.fromMap(Map<String, dynamic> map) {
    DateTime? date(String key) =>
        map[key] == null ? null : DateTime.tryParse(map[key].toString());
    final plan = map['subscription_plans'];
    return BusinessSubscription(
      id: map['id'].toString(),
      businessId: map['business_id'].toString(),
      planId: map['plan_id'].toString(),
      status: map['status']?.toString() ?? 'pending',
      provider: map['provider']?.toString() ?? 'paypal',
      providerSubscriptionId: map['provider_subscription_id']?.toString(),
      currentPeriodStart: date('current_period_start'),
      currentPeriodEnd: date('current_period_end'),
      createdAt: date('created_at') ?? DateTime.now(),
      planName: plan is Map ? plan['name']?.toString() : null,
    );
  }

  bool get isActive => status == 'active';
}
