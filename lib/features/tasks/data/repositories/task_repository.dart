import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/task_model.dart';

const _uuid = Uuid();

abstract class TaskRepository {
  Future<List<TaskModel>> getTasks({int? userId, int page = 1, int limit = 10});
  Future<TaskModel> getTask(String id);
  Future<TaskModel> createTask(TaskModel task);
  Future<TaskModel> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<void> cacheTask(List<TaskModel> tasks);
  Future<List<TaskModel>> getCachedTasks();
}

class TaskRepositoryImpl implements TaskRepository {
  final Dio _dio;
  final LocalStorage _localStorage;

  TaskRepositoryImpl(this._dio, this._localStorage);

  @override
  @override
  Future<List<TaskModel>> getTasks(
      {int? userId, int page = 1, int limit = 10}) async {
    // If no user is logged in or it's a new registration (mock ID 999),
    // don't fetch dummy tasks from the global API. Return only local/cached tasks.
    if (userId == null || userId == 999) {
      return await getCachedTasks();
    }

    try {
      final skip = (page - 1) * limit;
      final endpoint = '/todos/user/$userId';

      final response = await _dio.get(
        endpoint,
        queryParameters: {'limit': limit, 'skip': skip},
      );

      final todos = response.data['todos'] as List;
      final tasks = todos.map((t) {
        final bool completed = t['completed'] ?? false;
        return TaskModel.fromJson({
          'id': t['id'].toString(),
          'title': t['todo'] ?? '',
          'description': 'Task from API: ${t['todo'] ?? ''}',
          'status': completed ? 'done' : 'todo',
          'createdAt': DateTime.now()
              .subtract(Duration(days: limit - todos.indexOf(t)))
              .toIso8601String(),
        });
      }).toList();

      final localTasks = await getCachedTasks();
      final localOnly = localTasks.where((t) => t.isLocal).toList();

      final merged = [...localOnly, ...tasks];
      await cacheTask(merged);
      return merged;
    } on DioException catch (e) {
      // If user ID is not found in dummyjson (mock user), just return cached tasks
      if (e.response?.statusCode == 404) {
        return await getCachedTasks();
      }

      final cached = await getCachedTasks();
      if (cached.isNotEmpty) return cached;
      return _handleDioError(e);
    }
  }

  @override
  Future<TaskModel> getTask(String id) async {
    final cached = await getCachedTasks();
    final local = cached.where((t) => t.id == id).firstOrNull;
    if (local != null) return local;

    try {
      final response = await _dio.get('/todos/$id');
      final t = response.data;
      final bool completed = t['completed'] ?? false;
      return TaskModel.fromJson({
        'id': t['id'].toString(),
        'title': t['todo'] ?? '',
        'description': 'Task from API: ${t['todo'] ?? ''}',
        'status': completed ? 'done' : 'todo',
        'createdAt': DateTime.now().toIso8601String(),
      });
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await _dio.post(
        '/todos/add',
        data: {'todo': task.title, 'completed': false, 'userId': 1},
      );

      final newTask = task.copyWith(
        id: response.data['id']?.toString() ?? _uuid.v4(),
        isLocal: true,
      );

      final cachedTasks = await getCachedTasks();
      await cacheTask([newTask, ...cachedTasks]);
      return newTask;
    } on DioException {
      final cachedTasks = await getCachedTasks();
      await cacheTask([task, ...cachedTasks]);
      return task;
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    final cachedTasks = await getCachedTasks();
    final updated = cachedTasks.map((t) => t.id == task.id ? task : t).toList();
    await cacheTask(updated);

    if (!task.isLocal) {
      try {
        await _dio.put(
          '/todos/${task.id}',
          data: {
            'todo': task.title,
            'completed': task.status == TaskStatus.done,
          },
        );
      } catch (_) {
        // Ignore API errors for update
      }
    }

    return task.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<void> deleteTask(String id) async {
    final cachedTasks = await getCachedTasks();
    final updated = cachedTasks.where((t) => t.id != id).toList();
    await cacheTask(updated);

    try {
      await _dio.delete('/todos/$id');
    } catch (_) {
      // Ignore API errors for delete
    }
  }

  @override
  Future<void> cacheTask(List<TaskModel> tasks) async {
    final json = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _localStorage.saveCachedTasks(json);
  }

  @override
  Future<List<TaskModel>> getCachedTasks() async {
    final data = await _localStorage.getCachedTasks();
    if (data == null) return [];
    try {
      final list = jsonDecode(data) as List;
      return list.map((j) => TaskModel.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Never _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const NetworkFailure();
    }
    final message = e.response?.data?['message'] ?? e.message ?? 'Server error';
    throw ServerFailure(message: message, statusCode: e.response?.statusCode);
  }
}
