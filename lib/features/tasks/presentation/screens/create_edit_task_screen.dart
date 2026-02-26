import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';
import '../../providers/tasks_provider.dart';

class CreateEditTaskScreen extends ConsumerStatefulWidget {
  final String? taskId;

  const CreateEditTaskScreen({super.key, this.taskId});

  @override
  ConsumerState<CreateEditTaskScreen> createState() =>
      _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends ConsumerState<CreateEditTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  TaskStatus _selectedStatus = TaskStatus.todo;
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  bool _isEdit = false;
  TaskModel? _originalTask;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    if (widget.taskId != null) {
      _isEdit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTask());
    }
  }

  void _loadTask() {
    final tasks = ref.read(tasksProvider).value ?? [];
    final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (task != null) {
      _originalTask = task;
      _titleCtrl.text = task.title;
      _descriptionCtrl.text = task.description;
      _selectedStatus = task.status;
      _selectedDueDate = task.dueDate;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      if (_isEdit && _originalTask != null) {
        final updated = _originalTask!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          status: _selectedStatus,
          dueDate: _selectedDueDate,
          updatedAt: DateTime.now(),
        );
        await ref.read(tasksProvider.notifier).updateTask(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task updated successfully ✓'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        final newTask = TaskModel.create(
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          status: _selectedStatus,
          dueDate: _selectedDueDate,
        );
        await ref.read(tasksProvider.notifier).createTask(newTask);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task created successfully ✓'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(_isEdit ? 'Edit Task' : 'New Task'),
              actions: [
                if (!_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save'),
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Task Title *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleCtrl,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: 'Enter task title...',
                          prefixIcon: Icon(Icons.title_rounded, size: 20),
                          counterText: '',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (v.trim().length < 3) {
                            return 'Title must be at least 3 characters';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Description'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionCtrl,
                        maxLines: 5,
                        maxLength: 500,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Describe your task...',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 80),
                            child: Icon(Icons.notes_rounded, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Status'),
                      const SizedBox(height: 8),
                      _buildStatusSelector(),
                      const SizedBox(height: 20),
                      _buildLabel('Due Date'),
                      const SizedBox(height: 8),
                      _buildDueDatePicker(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: TaskStatus.values.map((s) {
        final isSelected = _selectedStatus == s;
        final color = AppColors.statusColor(s.value);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? color : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDueDatePicker() {
    final hasDueDate = _selectedDueDate != null;
    return GestureDetector(
      onTap: _pickDueDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                hasDueDate ? AppColors.primary : Theme.of(context).dividerColor,
            width: hasDueDate ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              color: hasDueDate ? AppColors.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasDueDate
                    ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDueDate!)
                    : 'No due date set',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hasDueDate ? null : Colors.grey,
                    ),
              ),
            ),
            if (hasDueDate)
              GestureDetector(
                onTap: () => setState(() => _selectedDueDate = null),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.error, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _save,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(_isEdit ? Icons.save_rounded : Icons.add_task_rounded),
          label: Text(_isEdit ? 'Save Changes' : 'Create Task'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
