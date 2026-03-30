import 'package:flutter/material.dart';

class TaskSearchBar extends StatelessWidget {
  const TaskSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search tasks by title…',
      ),
    );
  }
}

