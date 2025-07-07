enum Priority { high, medium, low }

class Task {
  String title;
  String description;
  Priority priority;
  String assignedTo;
  DateTime dueDate;
  bool completed;

  Task({
    required this.title,
    required this.description,
    required this.priority,
    required this.assignedTo,
    required this.dueDate,
    required this.completed,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    Priority priority;
    switch (json['priority']) {
      case 'high':
        priority = Priority.high;
        break;
      case 'medium':
        priority = Priority.medium;
        break;
      case 'low':
      default:
        priority = Priority.low;
    }

    return Task(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: priority,
      assignedTo: json['assignedTo'] != null ? json['assignedTo']['name'] ?? '' : '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      completed: json['status'] == 'done',
    );
  }
}
