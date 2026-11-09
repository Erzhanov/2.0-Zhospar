class TaskModel {
  final String id;
  final String weekId;
  final String userId;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String title;
  final String? description;
  final String? category;
  final String priority; // 'low' | 'med' | 'high'
  final String? dueTime;
  final String status; // 'todo' | 'done'
  final String? notDoneReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.weekId,
    required this.userId,
    required this.dayOfWeek,
    required this.title,
    this.description,
    this.category,
    this.priority = 'med',
    this.dueTime,
    this.status = 'todo',
    this.notDoneReason,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDone => status == 'done';

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      weekId: json['week_id'] as String,
      userId: json['user_id'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as String? ?? 'med',
      dueTime: json['due_time'] as String?,
      status: json['status'] as String? ?? 'todo',
      notDoneReason: json['not_done_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'week_id': weekId,
      'user_id': userId,
      'day_of_week': dayOfWeek,
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'priority': priority,
      if (dueTime != null) 'due_time': dueTime,
      'status': status,
      if (notDoneReason != null) 'not_done_reason': notDoneReason,
    };
  }

  TaskModel copyWith({
    String? id,
    String? weekId,
    String? userId,
    int? dayOfWeek,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? dueTime,
    String? status,
    String? notDoneReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      weekId: weekId ?? this.weekId,
      userId: userId ?? this.userId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueTime: dueTime ?? this.dueTime,
      status: status ?? this.status,
      notDoneReason: notDoneReason ?? this.notDoneReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
