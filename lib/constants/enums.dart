enum TaskStatus {
  todo('To-Do'),
  inProgress('In Progress'),
  done('Done');

  const TaskStatus(this.label);
  final String label;

  static TaskStatus fromLabel(String label) {
    return TaskStatus.values.firstWhere(
      (e) => e.label == label,
      orElse: () => TaskStatus.todo,
    );
  }
}

enum TaskFilter {
  all('All'),
  todo('To-Do'),
  inProgress('In Progress'),
  done('Done');

  const TaskFilter(this.label);
  final String label;
}

