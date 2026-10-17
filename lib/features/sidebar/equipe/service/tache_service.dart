import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/tache_model.dart';

class TacheService {
  TacheService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Vous devez être connecté.');
    return id;
  }

  Future<List<TacheModel>> getTasks({
    required String businessId,
    DateTime? date,
    bool onlyMyTasks = false,
  }) async {
    var query = _client
        .from('team_tasks')
        .select()
        .eq('business_id', businessId);

    if (date != null) {
      final day = _dateOnly(date);
      query = query.eq('due_date', day);
    }

    final rows = await query
        .order('due_date')
        .order('created_at', ascending: false);
    final taskMaps = (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (taskMaps.isEmpty) return [];

    final taskIds = taskMaps.map((e) => e['id'].toString()).toList();
    final assignmentRows = await _client
        .from('team_task_assignments')
        .select()
        .inFilter('task_id', taskIds);

    final assignmentMaps = (assignmentRows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final result = <TacheModel>[];
    for (final task in taskMaps) {
      var assignments = assignmentMaps
          .where((a) => a['task_id'].toString() == task['id'].toString())
          .toList();

      if (onlyMyTasks) {
        assignments = assignments
            .where((a) => a['user_id'].toString() == _userId)
            .toList();
        if (assignments.isEmpty) continue;
      }

      result.add(TacheModel.fromMap(task, assignments: assignments));
    }

    return result;
  }

  Future<void> createTask({
    required String businessId,
    required String title,
    required String description,
    required DateTime dueDate,
    String? dueTime,
    required String priority,
    required List<String> assigneeIds,
  }) async {
    if (assigneeIds.isEmpty) {
      throw Exception('Assignez la tâche à au moins un membre.');
    }

    final inserted = await _client
        .from('team_tasks')
        .insert({
          'business_id': businessId,
          'created_by': _userId,
          'title': title.trim(),
          'description': description.trim(),
          'due_date': _dateOnly(dueDate),
          'due_time': (dueTime == null || dueTime.isEmpty) ? null : dueTime,
          'priority': priority,
        })
        .select('id')
        .single();

    final taskId = inserted['id'].toString();
    final uniqueIds = assigneeIds.toSet().toList();

    await _client
        .from('team_task_assignments')
        .insert(
          uniqueIds
              .map((userId) => {'task_id': taskId, 'user_id': userId})
              .toList(),
        );
  }

  Future<void> markCompleted(String assignmentId) async {
    await _client
        .from('team_task_assignments')
        .update({
          'status': 'completed',
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', assignmentId)
        .eq('user_id', _userId);
  }

  Future<void> markPending(String assignmentId) async {
    await _client
        .from('team_task_assignments')
        .update({'status': 'pending', 'completed_at': null})
        .eq('id', assignmentId)
        .eq('user_id', _userId);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('team_tasks').delete().eq('id', taskId);
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
