import 'package:flodo/constants/enums.dart';
import 'package:flutter/material.dart';

class StatusFilter extends StatelessWidget {
  const StatusFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TaskFilter value;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TaskFilter>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Status',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: TaskFilter.values
          .map(
            (f) => DropdownMenuItem(
              value: f,
              child: Text(f.label),
            ),
          )
          .toList(growable: false),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

