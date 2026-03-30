import 'package:flodo/core/theme/app_theme.dart';
import 'package:flodo/providers/task_provider.dart';
import 'package:flodo/screens/task_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskController()..init(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: AppTheme.light(),
      home: const TaskListScreen(),
    );
  }
}
