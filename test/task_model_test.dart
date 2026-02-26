import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';

void main() {
  group('TaskModel', () {
    test('creates a new task with correct defaults', () {
      final task = TaskModel.create(
        title: 'Test Task',
        description: 'Test description',
      );

      expect(task.title, 'Test Task');
      expect(task.description, 'Test description');
      expect(task.status, TaskStatus.todo);
      expect(task.isLocal, true);
      expect(task.id, isNotEmpty);
      expect(task.isDone, false);
      expect(task.isOverdue, false);
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': '123',
        'title': 'Task from API',
        'description': 'API description',
        'status': 'in-progress',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'dueDate': '2025-12-31T00:00:00.000Z',
      };

      final task = TaskModel.fromJson(json);

      expect(task.id, '123');
      expect(task.title, 'Task from API');
      expect(task.status, TaskStatus.inProgress);
      expect(task.dueDate, isNotNull);
    });

    test('toJson serializes and fromJson deserializes symmetrically', () {
      final original = TaskModel.create(
        title: 'Roundtrip Task',
        description: 'Test roundtrip',
        status: TaskStatus.done,
        dueDate: DateTime(2025, 6, 15),
      );

      final json = original.toJson();
      final restored = TaskModel.fromJson(json);

      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.status, original.status);
      expect(restored.isLocal, original.isLocal);
    });

    test('isOverdue returns true when past due and not done', () {
      final overdueTask = TaskModel(
        id: 'overdue-1',
        title: 'Overdue',
        description: '',
        status: TaskStatus.todo,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(overdueTask.isOverdue, true);
    });

    test('isOverdue returns false when task is done (even if past due)', () {
      final doneTask = TaskModel(
        id: 'done-1',
        title: 'Done',
        description: '',
        status: TaskStatus.done,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(doneTask.isOverdue, false);
    });

    test('copyWith creates modified copy with correct fields', () {
      final original = TaskModel.create(
        title: 'Original',
        description: 'Original desc',
      );

      final modified = original.copyWith(
        title: 'Modified',
        status: TaskStatus.inProgress,
      );

      expect(modified.id, original.id);
      expect(modified.title, 'Modified');
      expect(modified.description, original.description);
      expect(modified.status, TaskStatus.inProgress);
    });

    test('equality is based on id', () {
      final task1 = TaskModel(
        id: 'same-id',
        title: 'First',
        description: '',
        status: TaskStatus.todo,
        createdAt: DateTime.now(),
      );
      final task2 = TaskModel(
        id: 'same-id',
        title: 'Second',
        description: '',
        status: TaskStatus.done,
        createdAt: DateTime.now(),
      );

      expect(task1, equals(task2));
      expect(task1.hashCode, equals(task2.hashCode));
    });

    test('TaskStatusExtension fromString handles all statuses', () {
      expect(TaskStatusExtension.fromString('todo'), TaskStatus.todo);
      expect(
          TaskStatusExtension.fromString('in-progress'), TaskStatus.inProgress);
      expect(TaskStatusExtension.fromString('done'), TaskStatus.done);
      expect(TaskStatusExtension.fromString('unknown'), TaskStatus.todo);
    });
  });
}
