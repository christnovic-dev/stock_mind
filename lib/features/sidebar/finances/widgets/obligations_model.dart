
class FinancialObligationModel {
  final String id;
  final String businessId;
  final String type;
  final String thirdPartyName;
  final String? thirdPartyPhone;
  final String description;
  final String? reference;
  final double initialAmount;
  final DateTime obligationDate;
  final DateTime? dueDate;
  final String? notes;
  final double paidAmount;

  FinancialObligationModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.thirdPartyName,
    this.thirdPartyPhone,
    required this.description,
    this.reference,
    required this.initialAmount,
    required this.obligationDate,
    this.dueDate,
    this.notes,
    this.paidAmount = 0,
  });

  double get remainingAmount =>
      (initialAmount - paidAmount).clamp(0.0, double.infinity);

  bool get isSettled => remainingAmount < 0.001;

  bool get isOverdue =>
      !isSettled &&
          dueDate != null &&
          dueDate!.isBefore(DateTime.now()) &&
          !_isToday(dueDate!);

  String get status {
    if (isSettled) return 'Réglée';
    if (isOverdue) return 'En retard';
    if (paidAmount > 0) return 'Partiellement réglée';
    return 'En attente';
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  factory FinancialObligationModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return FinancialObligationModel(
      id: map['id'].toString(),
      businessId: map['business_id'].toString(),
      type: map['type'] as String,
      thirdPartyName: map['third_party_name'] as String,
      thirdPartyPhone: map['third_party_phone'] as String?,
      description: map['description'] as String,
      reference: map['reference'] as String?,
      initialAmount: double.parse(
        map['initial_amount'].toString(),
      ),
      obligationDate: DateTime.parse(
        map['obligation_date'].toString(),
      ),
      dueDate: map['due_date'] == null
          ? null
          : DateTime.parse(map['due_date'].toString()),
      notes: map['notes'] as String?,
      paidAmount: double.parse(
        (map['paid_amount'] ?? 0).toString(),
      ),
    );
  }
}
