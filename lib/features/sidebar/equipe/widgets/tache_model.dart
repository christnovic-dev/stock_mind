class TacheModel {
  final String id;
  final String businessId;
  final String createdBy;
  final String title;
  final String description;
  final DateTime dueDate;
  final String? dueTime;
  final String priority;
  final DateTime createdAt;
  final List<Map<String, dynamic>> assignments;

  const TacheModel({
    required this.id,
    required this.businessId,
    required this.createdBy,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.dueTime,
    required this.priority,
    required this.createdAt,
    required this.assignments,
  });

  factory TacheModel.fromMap(
    Map<String, dynamic> map, {
    List<Map<String, dynamic>> assignments = const [],
  }) {
    return TacheModel(
      id: map['id'].toString(),
      businessId: map['business_id'].toString(),
      createdBy: map['created_by'].toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      dueDate: DateTime.parse(map['due_date'].toString()),
      dueTime: map['due_time']?.toString(),
      priority: (map['priority'] ?? 'normal').toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      assignments: assignments,
    );
  }

  bool get isCompleted =>
      assignments.isNotEmpty &&
      assignments.every((item) => item['status'] == 'completed');

  bool get isOverdue {
    final today = DateTime.now();
    final date = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final currentDay = DateTime(today.year, today.month, today.day);
    return date.isBefore(currentDay) && !isCompleted;
  }
}
