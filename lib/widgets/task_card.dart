import 'package:flodo/constants/enums.dart';
import 'package:flodo/models/task_model.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.isBlocked,
    required this.blockedByTitle,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
  });

  final TaskModel task;
  final bool isBlocked;
  final String? blockedByTitle;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color _chipColor(TaskStatus status, ColorScheme scheme) {
    return switch (status) {
      TaskStatus.todo => scheme.outlineVariant,
      TaskStatus.inProgress => scheme.primaryContainer,
      TaskStatus.done => Colors.green.shade200,
    };
  }

  Color _chipTextColor(TaskStatus status, ColorScheme scheme) {
    return switch (status) {
      TaskStatus.todo => scheme.onSurfaceVariant,
      TaskStatus.inProgress => scheme.onPrimaryContainer,
      TaskStatus.done => Colors.green.shade900,
    };
  }

  TextSpan _highlightTitle(BuildContext context, String title, String query) {
    final base = DefaultTextStyle.of(context).style.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        );
    if (query.trim().isEmpty) return TextSpan(text: title, style: base);

    final lower = title.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) return TextSpan(text: title, style: base);

    final before = title.substring(0, idx);
    final match = title.substring(idx, idx + q.length);
    final after = title.substring(idx + q.length);

    final highlight = base.copyWith(
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
    );

    return TextSpan(
      children: [
        TextSpan(text: before, style: base),
        TextSpan(text: match, style: highlight),
        TextSpan(text: after, style: base),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = task.statusEnum;

    final bg = isBlocked ? Colors.grey.shade200 : Colors.white;
    final opacity = isBlocked ? 0.65 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Card(
        color: bg,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isBlocked ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isBlocked)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.lock, size: 18, color: scheme.outline),
                      ),
                    Expanded(
                      child: RichText(
                        text: _highlightTitle(context, task.title, searchQuery),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.event, size: 18, color: scheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      task.dueDate,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _chipColor(status, scheme),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        task.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _chipTextColor(status, scheme),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isBlocked) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Blocked by ${blockedByTitle ?? 'Task ${task.blockedBy}'}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

