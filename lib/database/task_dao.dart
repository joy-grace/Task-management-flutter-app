import 'package:flodo/database/db_helper.dart';
import 'package:flodo/models/task_model.dart';
import 'package:sqflite/sqflite.dart';

class TaskDao {
  static const String table = 'tasks';

  Future<int> insert(TaskModel task) async {
    final db = await DbHelper.instance.database;
    return db.insert(
      table,
      task.toDb()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<TaskModel>> fetchAll() async {
    final db = await DbHelper.instance.database;
    final rows = await db.query(table, orderBy: 'id DESC');
    return rows.map(TaskModel.fromDb).toList(growable: false);
  }

  Future<int> update(TaskModel task) async {
    final db = await DbHelper.instance.database;
    return db.update(
      table,
      task.toDb()..remove('id'),
      where: 'id = ?',
      whereArgs: [task.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> deleteById(int id) async {
    final db = await DbHelper.instance.database;
    await db.transaction((txn) async {
      // Remove references to this task in other tasks.
      await txn.update(
        table,
        {'blocked_by': null},
        where: 'blocked_by = ?',
        whereArgs: [id],
      );
      await txn.delete(table, where: 'id = ?', whereArgs: [id]);
    });
  }
}

