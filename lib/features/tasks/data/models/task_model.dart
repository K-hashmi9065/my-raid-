import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TaskStatus { todo, inProgress, done }

extension TaskStatusExtension on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  String get value {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in-progress';
      case TaskStatus.done:
        return 'done';
    }
  }

  static TaskStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'in-progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isLocal;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.dueDate,
    required this.createdAt,
    this.updatedAt,
    this.isLocal = false,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now()) && status != TaskStatus.done;
  }

  bool get isDone => status == TaskStatus.done;

  factory TaskModel.create({
    required String title,
    required String description,
    TaskStatus status = TaskStatus.todo,
    DateTime? dueDate,
  }) {
    return TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      status: status,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      isLocal: true,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? _uuid.v4(),
      title: json['title'] ?? '',
      description: json['description'] ?? json['todo'] ?? '',
      status: TaskStatusExtension.fromString(json['status'] ?? 'todo'),
      dueDate:
          json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      isLocal: json['isLocal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.value,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isLocal': isLocal,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocal,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TaskModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
