class WeeklyReviewModel {
  final String id;
  final String weekId;
  final String userId;
  final String learnedText;
  final String goodText;
  final String hardText;
  final String changeText;
  final List<String> nextGoals;
  final DateTime? updatedAt;

  WeeklyReviewModel({
    required this.id,
    required this.weekId,
    required this.userId,
    this.learnedText = '',
    this.goodText = '',
    this.hardText = '',
    this.changeText = '',
    this.nextGoals = const [],
    this.updatedAt,
  });

  factory WeeklyReviewModel.fromJson(Map<String, dynamic> json) {
    List<String> goals = [];
    if (json['next_goals'] is List) {
      goals = (json['next_goals'] as List).map((e) => e.toString()).toList();
    }
    return WeeklyReviewModel(
      id: json['id'] as String? ?? '',
      weekId: json['week_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      learnedText: json['learned_text'] as String? ?? '',
      goodText: json['good_text'] as String? ?? '',
      hardText: json['hard_text'] as String? ?? '',
      changeText: json['change_text'] as String? ?? '',
      nextGoals: goals,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_id': weekId,
      'user_id': userId,
      'learned_text': learnedText,
      'good_text': goodText,
      'hard_text': hardText,
      'change_text': changeText,
      'next_goals': nextGoals,
    };
  }
}
