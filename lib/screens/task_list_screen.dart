import 'package:flodo/core/utils/debouncer.dart';
import 'package:flodo/models/task_model.dart';
import 'package:flodo/providers/task_provider.dart';
import 'package:flodo/screens/task_form_screen.dart';
import 'package:flodo/widgets/search_bar.dart';
import 'package:flodo/widgets/status_filter.dart';
import 'package:flodo/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(TaskModel task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('This will permanently delete "${task.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final id = task.id;
    if (id == null) return;

    await context.read<TaskController>().deleteTask(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final filter = controller.filter;
    final query = controller.query;
    final tasks = controller.filteredTasks;
    final blockedByMap = controller.blockedByMap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TaskSearchBar(
              controller: _searchController,
              onChanged: (value) {
                _debouncer.run(() {
                  context.read<TaskController>().query = value;
                });
              },
            ),
            const SizedBox(height: 12),
            StatusFilter(
              value: filter,
              onChanged: (v) => context.read<TaskController>().filter = v,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Builder(
                builder: (ctx) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.error != null) {
                    return Center(
                      child: Text(
                        'Something went wrong.\n${controller.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (tasks.isEmpty) {
                    return _EmptyState(
                      hasQueryOrFilter:
                          query.trim().isNotEmpty || filter.label != 'All',
                    );
                  }

                  return ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final t = tasks[i];
                      final blocker = t.blockedBy == null
                          ? null
                          : blockedByMap[t.blockedBy!];
                      final isBlocked = t.blockedBy != null &&
                          blocker != null &&
                          blocker.status != 'Done';

                      return TaskCard(
                        task: t,
                        isBlocked: isBlocked,
                        blockedByTitle: blocker?.title,
                        searchQuery: query,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TaskFormScreen(task: t),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(t),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQueryOrFilter});

  final bool hasQueryOrFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_check_circle_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              hasQueryOrFilter ? 'No matching tasks' : 'No tasks yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasQueryOrFilter
                  ? 'Try adjusting your search or filter.'
                  : 'Tap “Add Task” to create your first task.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

