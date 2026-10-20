import 'package:supabase_flutter/supabase_flutter.dart';

import '../widget/horaire_model.dart';

class HoraireService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<String> scheduleTypes = [
    'work',
    'rest',
    'leave',
    'public_holiday',
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

  /// Récupère les horaires compris entre deux dates.
  Future<List<HoraireModel>> getSchedules({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final employees = await getEmployees(businessId);

    final response = await _supabase
        .from('employee_schedules')
        .select()
        .eq('business_id', businessId)
        .gte('schedule_date', _dateToString(startDate))
        .lte('schedule_date', _dateToString(endDate))
        .order('schedule_date');

    final employeesById = <String, Map<String, dynamic>>{
      for (final employee in employees) employee['id'].toString(): employee,
    };

    final result = <HoraireModel>[];

    for (final item in response) {
      final map = Map<String, dynamic>.from(item);
      final employee = employeesById[map['employee_id'].toString()];

      result.add(
        HoraireModel.fromMap(
          map,
          firstName: employee?['first_name']?.toString(),
          lastName: employee?['last_name']?.toString(),
          employeeNumber: employee?['employee_number']?.toString(),
        ),
      );
    }

    return result;
  }

  /// Crée ou modifie l'horaire d'un employé pour une journée.
  Future<void> saveSchedule({
    String? id,
    required String businessId,
    required String employeeId,
    required DateTime date,
    required String scheduleType,
    String? startTime,
    String? endTime,
    int breakMinutes = 0,
    String? notes,
  }) async {
    if (!scheduleTypes.contains(scheduleType)) {
      throw ArgumentError('Type d’horaire invalide.');
    }

    if (breakMinutes < 0 || breakMinutes > 480) {
      throw ArgumentError(
        'La pause doit être comprise entre 0 et 480 minutes.',
      );
    }

    final isWork = scheduleType == 'work';

    if (isWork) {
      if (startTime == null || endTime == null) {
        throw ArgumentError(
          'L’heure de début et l’heure de fin sont obligatoires.',
        );
      }

      if (startTime == endTime) {
        throw ArgumentError(
          'Les heures de début et de fin doivent être différentes.',
        );
      }

      if (!_isValidTime(startTime) || !_isValidTime(endTime)) {
        throw ArgumentError('Format horaire invalide. Utilise HH:mm.');
      }
    }

    final userId = _supabase.auth.currentUser?.id;

    final data = <String, dynamic>{
      'business_id': businessId,
      'employee_id': employeeId,
      'schedule_date': _dateToString(date),
      'schedule_type': scheduleType,
      'start_time': isWork ? startTime : null,
      'end_time': isWork ? endTime : null,
      'break_minutes': breakMinutes,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      if (id == null && userId != null) 'created_by': userId,
    };

    if (id != null) {
      await _supabase
          .from('employee_schedules')
          .update(data)
          .eq('id', id)
          .eq('business_id', businessId);
    } else {
      await _supabase
          .from('employee_schedules')
          .upsert(data, onConflict: 'business_id,employee_id,schedule_date');
    }
  }

  /// Supprime un horaire.
  Future<void> deleteSchedule({
    required String id,
    required String businessId,
  }) async {
    await _supabase
        .from('employee_schedules')
        .delete()
        .eq('id', id)
        .eq('business_id', businessId);
  }

  static bool _isValidTime(String value) {
    return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
  }

  static String _dateToString(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
