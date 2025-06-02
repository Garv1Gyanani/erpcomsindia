class TaskStatusModel {
  final int pendingTask;
  final int completedTask;
  final int totalTask;

  TaskStatusModel({
    required this.pendingTask,
    required this.completedTask,
    required this.totalTask,
  });

  factory TaskStatusModel.fromJson(Map<String, dynamic> json) {
    return TaskStatusModel(
      pendingTask: json['PendingTask'] ?? 0,
      completedTask: json['CompletedTask'] ?? 0,
      totalTask: json['TotalTask'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PendingTask': pendingTask,
      'CompletedTask': completedTask,
      'TotalTask': totalTask,
    };
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (totalTask == 0) return 0.0;
    return (completedTask / totalTask) * 100;
  }

  // Check if all tasks are completed
  bool get isAllCompleted => completedTask == totalTask && totalTask > 0;

  @override
  String toString() {
    return 'TaskStatusModel(pendingTask: $pendingTask, completedTask: $completedTask, totalTask: $totalTask)';
  }
}
