class HoraireModel {
  final String id;
  final String businessId;
  final String employeeId;
  final DateTime scheduleDate;
  final String? startTime;
  final String? endTime;
  final String scheduleType;
  final int breakMinutes;
  final String? notes;
  final String? employeeFirstName;
  final String? employeeLastName;
  final String? employeeNumber;

  const HoraireModel({
    required this.id,
    required this.businessId,
    required this.employeeId,
    required this.scheduleDate,
    this.startTime,
    this.endTime,
    required this.scheduleType,
    this.breakMinutes = 0,
    this.notes,
    this.employeeFirstName,
    this.employeeLastName,
    this.employeeNumber,
  });

  String get employeeFullName =>
      '${employeeFirstName ?? ''} ${employeeLastName ?? ''}'.trim();

  String get scheduleTypeLabel {
    switch (scheduleType) {
      case 'work':
        return 'Travail';
      case 'rest':
        return 'Repos';
      case 'leave':
        return 'Congé';
      case 'public_holiday':
        return 'Jour férié';
      default:
        return 'Non défini';
    }
  }

  factory HoraireModel.fromMap(
    Map<String, dynamic> map, {
    String? firstName,
    String? lastName,
    String? employeeNumber,
  }) {
    return HoraireModel(
      id: map['id'].toString(),
      businessId: map['business_id'].toString(),
      employeeId: map['employee_id'].toString(),
      scheduleDate: DateTime.parse(map['schedule_date'].toString()),
      startTime: map['start_time']?.toString(),
      endTime: map['end_time']?.toString(),
      scheduleType: map['schedule_type']?.toString() ?? 'work',
      breakMinutes: (map['break_minutes'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString(),
      employeeFirstName: firstName,
      employeeLastName: lastName,
      employeeNumber: employeeNumber,
    );
  }
}
