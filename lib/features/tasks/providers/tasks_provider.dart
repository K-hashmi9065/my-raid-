import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/task_model.dart';
import '../data/repositories/task_repository.dart';
import '../../../core/network/dio_client.dart';
import '../../../di/providers.dart';
import '../../auth/providers/auth_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final localStorage = ref.watch(localStorageProvider);
  return TaskRepositoryImpl(dio, localStorage);
});

// Filter state
enum TaskFilter { all, todo, inProgress, done }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

final taskSearchProvider = StateProvider<String>((ref) => '');

// Main tasks provider
final tasksProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskModel>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  return TasksNotifier(ref.watch(taskRepositoryProvider), user?.id);
});

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository _repository;
  final int? _userId;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  TasksNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    try {
      final tasks = await _repository.getTasks(
        userId: _userId,
        page: _currentPage,
      );
      if (refresh || _currentPage == 1) {
        state = AsyncValue.data(tasks);
      } else {
        final current = state.value ?? [];
        state = AsyncValue.data([...current, ...tasks]);
      }
      _hasMore = tasks.length >= 10;
    } catch (e, st) {
      // Try to show cached data on error
      try {
        final cached = await _repository.getCachedTasks();
        if (cached.isNotEmpty) {
          state = AsyncValue.data(cached);
        } else {
          state = AsyncValue.error(e, st);
        }
      } catch (_) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _currentPage++;
    try {
      final moreTasks = await _repository.getTasks(
        userId: _userId,
        page: _currentPage,
      );
      final current = state.value ?? [];
      final existingIds = current.map((t) => t.id).toSet();
      final newTasks =
          moreTasks.where((t) => !existingIds.contains(t.id)).toList();
      state = AsyncValue.data([...current, ...newTasks]);
      _hasMore = moreTasks.length >= 10;
    } catch (_) {
      _currentPage--;
      _hasMore = false;
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> createTask(TaskModel task) async {
    try {
      final newTask = await _repository.createTask(task);
      final current = state.value ?? [];
      state = AsyncValue.data([newTask, ...current]);
    } catch (e) {
      // Still add locally for optimistic UI
      final current = state.value ?? [];
      state = AsyncValue.data([task, ...current]);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    final current = state.value ?? [];
    // Optimistic update
    state = AsyncValue.data(
      current.map((t) => t.id == task.id ? task : t).toList(),
    );
    try {
      await _repository.updateTask(task);
    } catch (_) {
      // Revert on error
      state = AsyncValue.data(current);
    }
  }

  Future<void> deleteTask(String id) async {
    final current = state.value ?? [];
    // Optimistic delete
    state = AsyncValue.data(current.where((t) => t.id != id).toList());
    try {
      await _repository.deleteTask(id);
    } catch (_) {
      // Revert on error
      state = AsyncValue.data(current);
    }
  }

  Future<void> updateTaskStatus(String id, TaskStatus newStatus) async {
    final current = state.value ?? [];
    final task = current.where((t) => t.id == id).firstOrNull;
    if (task == null) return;
    await updateTask(
        task.copyWith(status: newStatus, updatedAt: DateTime.now()));
  }

  bool get hasMore => _hasMore;
}

// Filtered tasks provider
final filteredTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final filter = ref.watch(taskFilterProvider);
  final search = ref.watch(taskSearchProvider).toLowerCase().trim();

  return tasksAsync.whenData((tasks) {
    var filtered = tasks;

    // Apply filter
    if (filter != TaskFilter.all) {
      filtered = filtered.where((t) {
        switch (filter) {
          case TaskFilter.todo:
            return t.status == TaskStatus.todo;
          case TaskFilter.inProgress:
            return t.status == TaskStatus.inProgress;
          case TaskFilter.done:
            return t.status == TaskStatus.done;
          default:
            return true;
        }
      }).toList();
    }

    // Apply search
    if (search.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(search) ||
            t.description.toLowerCase().contains(search);
      }).toList();
    }

    return filtered;
  });
});

// Statistics
final taskStatsProvider = Provider<Map<String, int>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? [];
  return {
    'total': tasks.length,
    'todo': tasks.where((t) => t.status == TaskStatus.todo).length,
    'inProgress': tasks.where((t) => t.status == TaskStatus.inProgress).length,
    'done': tasks.where((t) => t.status == TaskStatus.done).length,
    'overdue': tasks.where((t) => t.isOverdue).length,
  };
});
