import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/obligations_model.dart';

class FinancialService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<FinancialObligationModel>> getObligations({
    required String businessId,
    String? type,
  }) async {
    var query = _client
        .from('financial_obligations')
        .select('*, financial_payments(amount)')
        .eq('business_id', businessId);

    if (type != null) {
      query = query.eq('type', type);
    }

    final rows = await query.order('created_at', ascending: false);

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      final payments = (map['financial_payments'] as List?) ?? const [];
      final paid = payments.fold<double>(
        0,
        (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0),
      );
      map['paid_amount'] = paid;
      map.remove('financial_payments');
      return FinancialObligationModel.fromMap(map);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPayments({
    required String obligationId,
    required String businessId,
  }) async {
    final rows = await _client
        .from('financial_payments')
        .select()
        .eq('obligation_id', obligationId)
        .eq('business_id', businessId)
        .order('payment_date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> createObligation({
    required String businessId,
    required String type,
    required String thirdPartyName,
    String? thirdPartyPhone,
    required String description,
    String? reference,
    required double amount,
    required DateTime obligationDate,
    DateTime? dueDate,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Vous devez être connecté.');
    if (!amount.isFinite || amount <= 0) {
      throw Exception('Le montant doit être positif.');
    }
    if (type != 'receivable' && type != 'payable') {
      throw Exception('Type de dette ou créance invalide.');
    }
    if (thirdPartyName.trim().isEmpty || description.trim().isEmpty) {
      throw Exception('Le nom du tiers et le motif sont obligatoires.');
    }
    if (dueDate != null &&
        _date(dueDate).compareTo(_date(obligationDate)) < 0) {
      throw Exception('L’échéance ne peut pas précéder la date.');
    }

    await _client.from('financial_obligations').insert({
      'business_id': businessId,
      'type': type,
      'third_party_name': thirdPartyName.trim(),
      'third_party_phone': _nullable(thirdPartyPhone),
      'description': description.trim(),
      'reference': _nullable(reference),
      'initial_amount': amount,
      'obligation_date': _date(obligationDate),
      'due_date': dueDate == null ? null : _date(dueDate),
      'notes': _nullable(notes),
      'created_by': userId,
    });
  }

  Future<void> registerPayment({
    required String obligationId,
    required String businessId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw Exception('Le montant doit être positif.');
    }
    await _client.rpc(
      'register_financial_payment',
      params: {
        'p_obligation_id': obligationId,
        'p_business_id': businessId,
        'p_amount': amount,
        'p_payment_date': _date(paymentDate),
        'p_payment_method': paymentMethod,
        'p_reference': _nullable(reference),
        'p_notes': _nullable(notes),
      },
    );
  }

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String? _nullable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
