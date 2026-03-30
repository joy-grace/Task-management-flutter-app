import 'package:flodo/constants/enums.dart';

class TaskModel {
  const TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedBy,
  });

  final int? id;
  final String title;
  final String description;
  /// ISO format: yyyy-MM-dd
  final String dueDate;
  /// Stored as label values: "To-Do", "In Progress", "Done"
  final String status;
  final int? blockedBy;

  TaskStatus get statusEnum => TaskStatus.fromLabel(status);

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? dueDate,
    String? status,
    int? blockedBy,
    bool blockedByToNull = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedBy: blockedByToNull ? null : (blockedBy ?? this.blockedBy),
    );
  }

  Map<String, Object?> toDb() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'status': status,
      'blocked_by': blockedBy,
    };
  }

  factory TaskModel.fromDb(Map<String, Object?> map) {
    return TaskModel(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      dueDate: (map['due_date'] as String?) ?? '',
      status: (map['status'] as String?) ?? TaskStatus.todo.label,
      blockedBy: map['blocked_by'] as int?,
    );
  }
}

