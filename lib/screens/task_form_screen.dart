import 'dart:convert';

import 'package:flodo/constants/enums.dart';
import 'package:flodo/core/utils/date_utils.dart';
import 'package:flodo/models/task_model.dart';
import 'package:flodo/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final TaskModel? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _dueDate;

  TaskStatus _status = TaskStatus.todo;
  int? _blockedBy;

  bool _saving = false;
  SharedPreferences? _prefs;

  String get _draftKey => widget.task?.id == null
      ? 'draft_task_new'
      : 'draft_task_${widget.task!.id}';

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title ?? '');
    _description = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = TextEditingController(text: widget.task?.dueDate ?? '');
    _status = TaskStatus.fromLabel(widget.task?.status ?? TaskStatus.todo.label);
    _blockedBy = widget.task?.blockedBy;

    _wireDraftPersistence();
  }

  void _wireDraftPersistence() {
    Future<void>(() async {
      _prefs = await SharedPreferences.getInstance();
      await _restoreDraftIfNeeded();
      _title.addListener(_persistDraft);
      _description.addListener(_persistDraft);
      _dueDate.addListener(_persistDraft);
    });
  }

  Future<void> _restoreDraftIfNeeded() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return;

    // Only restore if user hasn't typed anything yet (prevents overwriting edits).
    final isPristine = _title.text.isEmpty &&
        _description.text.isEmpty &&
        _dueDate.text.isEmpty &&
        widget.task == null;
    if (!isPristine) return;

    try {
      final map = jsonDecode(raw) as Map<String, Object?>;
      final title = (map['title'] as String?) ?? '';
      final description = (map['description'] as String?) ?? '';
      final dueDate = (map['dueDate'] as String?) ?? '';
      final status = (map['status'] as String?) ?? TaskStatus.todo.label;
      final blockedBy = map['blockedBy'] as int?;

      setState(() {
        _title.text = title;
        _description.text = description;
        _dueDate.text = dueDate;
        _status = TaskStatus.fromLabel(status);
        _blockedBy = blockedBy;
      });
    } catch (_) {
      // If draft is corrupted, ignore.
    }
  }

  Future<void> _persistDraft() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final map = <String, Object?>{
      'title': _title.text,
      'description': _description.text,
      'dueDate': _dueDate.text,
      'status': _status.label,
      'blockedBy': _blockedBy,
    };
    await prefs.setString(_draftKey, jsonEncode(map));
  }

  Future<void> _clearDraft() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_draftKey);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _dueDate.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final initial = AppDateUtils.tryParseIso(_dueDate.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _dueDate.text = AppDateUtils.toIsoDate(picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);
    try {
      final existingId = widget.task?.id;
      final task = TaskModel(
        id: existingId,
        title: _title.text.trim(),
        description: _description.text.trim(),
        dueDate: _dueDate.text.trim(),
        status: _status.label,
        blockedBy: _blockedBy,
      );

      final controller = context.read<TaskController>();
      if (existingId == null) {
        await controller.createTask(task);
      } else {
        await controller.updateTask(task);
      }

      await _clearDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existingId == null ? 'Task created' : 'Task updated')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final allTasks = controller.tasks;
    final selfId = widget.task?.id;

    final blockerOptions = allTasks
        .where((t) => t.id != null && t.id != selfId)
        .toList(growable: false);

    if (_blockedBy != null && blockerOptions.every((t) => t.id != _blockedBy)) {
      // If blocker was deleted, clear selection (avoid mutating state during build).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_blockedBy == null) return;
        if (blockerOptions.any((t) => t.id == _blockedBy)) return;
        setState(() => _blockedBy = null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 3,
                maxLines: 6,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueDate,
                readOnly: true,
                onTap: _pickDueDate,
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Due date is required';
                  if (AppDateUtils.tryParseIso(value) == null) {
                    return 'Use format YYYY-MM-DD';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: TaskStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(growable: false),
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() => _status = v);
                        _persistDraft();
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _blockedBy,
                decoration: const InputDecoration(labelText: 'Blocked By'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...blockerOptions.map(
                    (t) => DropdownMenuItem<int?>(
                      value: t.id,
                      child: Text('${t.title} (ID ${t.id})'),
                    ),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (v) {
                        setState(() => _blockedBy = v);
                        _persistDraft();
                      },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              await _persistDraft();
                              if (!mounted) return;
                              Navigator.of(context).pop();
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: Your draft is auto-saved if you leave this screen.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

