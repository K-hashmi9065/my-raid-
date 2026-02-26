import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_chip.dart';
import '../widgets/stats_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/task_shimmer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();

  late AnimationController _fabAnimCtrl;

  @override
  void initState() {
    super.initState();
    _fabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimCtrl.forward();

    _scrollController.addListener(() {
      // Infinite scroll
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(tasksProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final filteredTasks = ref.watch(filteredTasksProvider);
    final stats = ref.watch(taskStatsProvider);
    final filter = ref.watch(taskFilterProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(tasksProvider.notifier).loadTasks(refresh: true),
        color: AppColors.primary,
        backgroundColor: Theme.of(context).cardColor,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(context, user?.firstName ?? 'User'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    StatsCard(stats: stats),
                    const SizedBox(height: 18),
                    _buildSearchField(),
                    _buildFilterRow(filter),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            filteredTasks.when(
              data: (tasks) => tasks.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: AnimationLimiter(
                        child: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= tasks.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }
                              final task = tasks[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 400),
                                child: SlideAnimation(
                                  verticalOffset: 50,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: TaskCard(
                                        task: task,
                                        onTap: () => context.push(
                                          '/task/${task.id}',
                                        ),
                                        onStatusChanged: (status) {
                                          ref
                                              .read(tasksProvider.notifier)
                                              .updateTaskStatus(
                                                  task.id, status);
                                        },
                                        onDelete: () => _confirmDelete(task.id),
                                        onEdit: () => context.push(
                                          '/task/edit/${task.id}',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: tasks.length +
                                (ref.read(tasksProvider.notifier).hasMore
                                    ? 1
                                    : 0),
                          ),
                        ),
                      ),
                    ),
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: TaskShimmer(),
                    ),
                    childCount: 6,
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateWidget(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(tasksProvider.notifier).loadTasks(refresh: true),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimCtrl,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.createTask),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, String firstName) {
    return SliverAppBar(
      expandedHeight: 125,
      floating: true,
      pinned: true,
      centerTitle: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.task_alt_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            'TaskFlow',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline_rounded),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 68, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'Let\'s get things done today.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _searchCtrl,
        // autofocus: true, // Removed autofocus to prevent keyboard from popping up immediately

        onChanged: (v) => ref.read(taskSearchProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(taskSearchProvider.notifier).state = '';
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterRow(TaskFilter currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TaskFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TaskFilterChip(
              label: _filterLabel(filter),
              isSelected: currentFilter == filter,
              onTap: () => ref.read(taskFilterProvider.notifier).state = filter,
              color: _filterColor(filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.todo:
        return 'To Do';
      case TaskFilter.inProgress:
        return 'In Progress';
      case TaskFilter.done:
        return 'Done';
    }
  }

  Color _filterColor(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return AppColors.primary;
      case TaskFilter.todo:
        return AppColors.statusTodo;
      case TaskFilter.inProgress:
        return AppColors.statusInProgress;
      case TaskFilter.done:
        return AppColors.statusDone;
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
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
      ref.read(tasksProvider.notifier).deleteTask(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
