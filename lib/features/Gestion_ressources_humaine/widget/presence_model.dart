
class PresenceModel {
  final String id;
  final String businessId;
  final String employeeId;
  final DateTime recordDate;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String status;
  final String? notes;
  final String? recordedBy;

  // Informations provenant de la table employees
  final String employeeFirstName;
  final String employeeLastName;
  final String? employeeNumber;

  const PresenceModel({
    required this.id,
    required this.businessId,
    required this.employeeId,
    required this.recordDate,
    this.checkInAt,
    this.checkOutAt,
    required this.status,
    this.notes,
    this.recordedBy,
    this.employeeFirstName = '',
    this.employeeLastName = '',
    this.employeeNumber,
  });

  String get employeeFullName =>
      '$employeeFirstName $employeeLastName'.trim();

  factory PresenceModel.fromMap(
      Map<String, dynamic> map, {
        String firstName = '',
        String lastName = '',
        String? employeeNumber,
      }) {
    return PresenceModel(
      id: map['id'].toString(),
      businessId: map['business_id'].toString(),
      employeeId: map['employee_id'].toString(),
      recordDate: DateTime.parse(map['record_date'].toString()),
      checkInAt: map['check_in_at'] == null
          ? null
          : DateTime.parse(map['check_in_at'].toString()).toLocal(),
      checkOutAt: map['check_out_at'] == null
          ? null
          : DateTime.parse(map['check_out_at'].toString()).toLocal(),
      status: map['status']?.toString() ?? 'present',
      notes: map['notes']?.toString(),
      recordedBy: map['recorded_by']?.toString(),
      employeeFirstName: firstName,
      employeeLastName: lastName,
      employeeNumber: employeeNumber,
    );
  }

  static const Map<String, String> statusLabels = {
    'present': 'Présent',
    'late': 'En retard',
    'absent': 'Absent',
    'half_day': 'Demi-journée',
    'remote': 'Télétravail',
  };
}
