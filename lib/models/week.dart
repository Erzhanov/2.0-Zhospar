class WeekModel {
  final String id;
  final String userId;
  final String weekStartDate; // YYYY-MM-DD
  final String quote;
  final DateTime? createdAt;

  WeekModel({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    this.quote = '',
    this.createdAt,
  });

  factory WeekModel.fromJson(Map<String, dynamic> json) {
    return WeekModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      weekStartDate: json['week_start_date'] as String? ?? '',
      quote: json['quote'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'week_start_date': weekStartDate,
      'quote': quote,
    };
  }

  WeekModel copyWith({
    String? id,
    String? userId,
    String? weekStartDate,
    String? quote,
    DateTime? createdAt,
  }) {
    return WeekModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      quote: quote ?? this.quote,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
