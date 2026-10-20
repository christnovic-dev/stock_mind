import 'package:supabase_flutter/supabase_flutter.dart';

import '../widget/presence_model.dart';

class PresenceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<String> statuses = [
    'present',
    'late',
    'absent',
    'half_day',
    'remote',
  ];

  /// Récupère les employés actifs d'une entreprise.
  Future<List<Map<String, dynamic>>> getEmployees(String businessId) async {
    final response = await _supabase
        .from('employees')
        .select(
          'id, business_id, first_name, last_name, '
          'employee_number, employment_status',
        )
        .eq('business_id', businessId)
        .eq('employment_status', 'active')
        .order('first_name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Récupère les pointages d'une entreprise pour une date.
  Future<List<PresenceModel>> getPresences({
    required String businessId,
    required DateTime date,
  }) async {
    final dateString = _dateToString(date);

    final employees = await getEmployees(businessId);

    final records = await _supabase
        .from('attendance_records')
        .select()
        .eq('business_id', businessId)
        .eq('record_date', dateString);

    final recordsByEmployee = <String, Map<String, dynamic>>{};

    for (final record in records) {
      final map = Map<String, dynamic>.from(record);
      recordsByEmployee[map['employee_id'].toString()] = map;
    }

    final result = <PresenceModel>[];

    for (final employee in employees) {
      final employeeId = employee['id'].toString();
      final record = recordsByEmployee[employeeId];

      // Un employé sans pointage est tout de même affiché.
      if (record == null) {
        result.add(
          PresenceModel(
            id: '',
            businessId: businessId,
            employeeId: employeeId,
            recordDate: DateTime(date.year, date.month, date.day),
            status: 'present',
            employeeFirstName: employee['first_name']?.toString() ?? '',
            employeeLastName: employee['last_name']?.toString() ?? '',
            employeeNumber: employee['employee_number']?.toString(),
          ),
        );
      } else {
        result.add(
          PresenceModel.fromMap(
            record,
            firstName: employee['first_name']?.toString() ?? '',
            lastName: employee['last_name']?.toString() ?? '',
            employeeNumber: employee['employee_number']?.toString(),
          ),
        );
      }
    }

    return result;
  }

  /// Crée ou modifie le pointage d'un employé pour une journée.
  Future<void> savePresence({
    required String businessId,
    required String employeeId,
    required DateTime date,
    required String status,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? notes,
  }) async {
    if (!statuses.contains(status)) {
      throw ArgumentError('Statut de présence invalide.');
    }

    if (checkInAt != null &&
        checkOutAt != null &&
        checkOutAt.isBefore(checkInAt)) {
      throw ArgumentError(
        'L’heure de départ doit être postérieure à l’arrivée.',
      );
    }

    // Vérifie que l'employé appartient bien à l'entreprise.
    final employee = await _supabase
        .from('employees')
        .select('id')
        .eq('id', employeeId)
        .eq('business_id', businessId)
        .eq('employment_status', 'active')
        .maybeSingle();

    if (employee == null) {
      throw Exception('Employé introuvable ou inactif dans cette entreprise.');
    }

    final dateString = _dateToString(date);

    final existing = await _supabase
        .from('attendance_records')
        .select('id')
        .eq('business_id', businessId)
        .eq('employee_id', employeeId)
        .eq('record_date', dateString)
        .maybeSingle();

    final userId = _supabase.auth.currentUser?.id;

    final data = <String, dynamic>{
      'business_id': businessId,
      'employee_id': employeeId,
      'record_date': dateString,
      'check_in_at': checkInAt?.toUtc().toIso8601String(),
      'check_out_at': checkOutAt?.toUtc().toIso8601String(),
      'status': status,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      if (userId != null) 'recorded_by': userId,
    };

    if (existing != null) {
      await _supabase
          .from('attendance_records')
          .update(data)
          .eq('id', existing['id'])
          .eq('business_id', businessId);
    } else {
      await _supabase.from('attendance_records').insert(data);
    }
  }

  static String _dateToString(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
