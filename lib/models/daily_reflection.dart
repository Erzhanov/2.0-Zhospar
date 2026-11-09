class DailyReflectionModel {
  final String id;
  final String weekId;
  final String userId;
  final int dayOfWeek;
  final String text;
  final DateTime? updatedAt;

  DailyReflectionModel({
    required this.id,
    required this.weekId,
    required this.userId,
    required this.dayOfWeek,
    required this.text,
    this.updatedAt,
  });

  factory DailyReflectionModel.fromJson(Map<String, dynamic> json) {
    return DailyReflectionModel(
      id: json['id'] as String? ?? '',
      weekId: json['week_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      text: json['text'] as String? ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_id': weekId,
      'user_id': userId,
      'day_of_week': dayOfWeek,
      'text': text,
    };
  }
}
