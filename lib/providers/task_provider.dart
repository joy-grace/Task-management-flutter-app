import 'package:flodo/constants/enums.dart';
import 'package:flodo/database/task_dao.dart';
import 'package:flodo/models/task_model.dart';
import 'package:flutter/foundation.dart';

class TaskController extends ChangeNotifier {
  TaskController({TaskDao? dao}) : _dao = dao ?? TaskDao();

  final TaskDao _dao;

  List<TaskModel> _tasks = const [];
  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;

  TaskFilter _filter = TaskFilter.all;
  String _query = '';
  bool _initialized = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;

  TaskFilter get filter => _filter;
  String get query => _query;

  set filter(TaskFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  set query(String value) {
    final normalized = value;
    if (_query == normalized) return;
    _query = normalized;
    notifyListeners();
  }

  Map<int, TaskModel> get blockedByMap =>
      {for (final t in _tasks) if (t.id != null) t.id!: t};

  List<TaskModel> get filteredTasks {
    final q = _query.trim().toLowerCase();
    Iterable<TaskModel> result = _tasks;

    if (_filter != TaskFilter.all) {
      result = result.where((t) => t.status == _filter.label);
    }
    if (q.isNotEmpty) {
      result = result.where((t) => t.title.toLowerCase().contains(q));
    }
    return result.toList(growable: false);
  }

  /// Call once after the first frame (prevents startup jank).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _dao.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _load();

  Future<void> createTask(TaskModel task) async {
    if (_isMutating) return;
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      await _dao.insert(task);
      _tasks = await _dao.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(TaskModel task) async {
    if (_isMutating) return;
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      await _dao.update(task);
      _tasks = await _dao.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(int id) async {
    _error = null;
    notifyListeners();
    try {
      await _dao.deleteById(id);
      _tasks = await _dao.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }
}

