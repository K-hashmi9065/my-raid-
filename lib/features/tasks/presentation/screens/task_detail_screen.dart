import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';
import '../../providers/tasks_provider.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return tasksAsync.when(
      loading: () => const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (tasks) {
        final task = tasks.where((t) => t.id == taskId).firstOrNull;
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task Not Found')),
            body: const Center(child: Text('Task not found')),
          );
        }
        return _TaskDetailContent(task: task);
      },
    );
  }
}

class _TaskDetailContent extends ConsumerWidget {
  final TaskModel task;

  const _TaskDetailContent({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = AppColors.statusColor(task.status.value);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.8),
                      statusColor.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _StatusBadge(status: task.status),
                        const SizedBox(height: 8),
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline, color: Colors.white),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created',
                        value: DateFormat('MMM dd, yyyy · HH:mm')
                            .format(task.createdAt),
                        color: AppColors.info,
                      ),
                      if (task.dueDate != null) ...[
                        const Divider(),
                        _InfoRow(
                          icon: Icons.event_available_outlined,
                          label: 'Due Date',
                          value:
                              DateFormat('MMM dd, yyyy').format(task.dueDate!),
                          color: task.isOverdue
                              ? AppColors.error
                              : AppColors.success,
                          isOverdue: task.isOverdue,
                        ),
                      ],
                      if (task.updatedAt != null) ...[
                        const Divider(),
                        _InfoRow(
                          icon: Icons.update_outlined,
                          label: 'Last Updated',
                          value: DateFormat('MMM dd, yyyy · HH:mm')
                              .format(task.updatedAt!),
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      Text(
                        task.description.isEmpty
                            ? 'No description provided.'
                            : task.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: task.description.isEmpty
                                  ? Theme.of(context).textTheme.bodySmall?.color
                                  : null,
                              fontStyle: task.description.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: TaskStatus.values.map((s) {
                      final isSelected = task.status == s;
                      final color = AppColors.statusColor(s.value);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: OutlinedButton(
                              onPressed: isSelected
                                  ? null
                                  : () {
                                      ref
                                          .read(tasksProvider.notifier)
                                          .updateTaskStatus(task.id, s);
                                      context.pop();
                                    },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? color.withValues(alpha: 0.15)
                                    : null,
                                side: BorderSide(
                                  color:
                                      isSelected ? color : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? color : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/task/edit/${task.id}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit_rounded, size: 28),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(tasksProvider.notifier).deleteTask(task.id);
      if (context.mounted) context.pop();
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isOverdue;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Row(
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isOverdue ? AppColors.error : null,
                        ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
