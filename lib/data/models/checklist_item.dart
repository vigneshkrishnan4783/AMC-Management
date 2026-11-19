class ChecklistItem {
  final String id;
  final String visitId;
  final String taskDescription;
  final bool isDone;
  final String? notes;

  ChecklistItem({
    required this.id,
    required this.visitId,
    required this.taskDescription,
    this.isDone = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visit_id': visitId,
      'task_description': taskDescription,
      'is_done': isDone ? 1 : 0,
      'notes': notes,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      visitId: map['visit_id'] as String? ?? '',
      taskDescription: map['task_description'] as String? ?? '',
      isDone: (map['is_done'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
    );
  }

  ChecklistItem copyWith({
    String? id,
    String? visitId,
    String? taskDescription,
    bool? isDone,
    String? notes,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      taskDescription: taskDescription ?? this.taskDescription,
      isDone: isDone ?? this.isDone,
      notes: notes ?? this.notes,
    );
  }
}
