import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/week.dart';
import '../models/daily_reflection.dart';
import '../models/weekly_review.dart';
import '../core/utils/week_utils.dart';

class WeekService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Get or create week row in Supabase
  Future<WeekModel?> getOrCreateWeek([String? weekStartDate]) async {
    final uid = _userId;
    if (uid == null) return null;

    final wsd = weekStartDate ?? WeekUtils.getWeekStartDate();

    final existing = await _client
        .from('weeks')
        .select('*')
        .eq('user_id', uid)
        .eq('week_start_date', wsd)
        .maybeSingle();

    if (existing != null) {
      return WeekModel.fromJson(existing);
    }

    final newRow = await _client
        .from('weeks')
        .insert({
          'user_id': uid,
          'week_start_date': wsd,
          'quote': '',
        })
        .select()
        .single();

    return WeekModel.fromJson(newRow);
  }

  /// Update weekly quote
  Future<void> updateWeekQuote(String weekId, String quote) async {
    await _client.from('weeks').update({'quote': quote}).eq('id', weekId);
  }

  /// Get all past and present weeks for current user
  Future<List<WeekModel>> getAllWeeks() async {
    final uid = _userId;
    if (uid == null) return [];

    final data = await _client
        .from('weeks')
        .select('*')
        .eq('user_id', uid)
        .order('week_start_date', ascending: false);

    return (data as List).map((e) => WeekModel.fromJson(e)).toList();
  }

  /// Get reflection for a specific day in a week
  Future<DailyReflectionModel?> getReflection(String weekId, int dayOfWeek) async {
    final data = await _client
        .from('daily_reflections')
        .select('*')
        .eq('week_id', weekId)
        .eq('day_of_week', dayOfWeek)
        .maybeSingle();

    if (data == null) return null;
    return DailyReflectionModel.fromJson(data);
  }

  /// Save reflection for a day
  Future<void> saveReflection(String weekId, int dayOfWeek, String text) async {
    final uid = _userId;
    if (uid == null) return;

    final existing = await getReflection(weekId, dayOfWeek);
    if (existing != null) {
      await _client
          .from('daily_reflections')
          .update({'text': text})
          .eq('id', existing.id);
    } else {
      await _client.from('daily_reflections').insert({
        'user_id': uid,
        'week_id': weekId,
        'day_of_week': dayOfWeek,
        'text': text,
      });
    }
  }

  /// Get all reflections for a week
  Future<List<DailyReflectionModel>> getReflectionsForWeek(String weekId) async {
    final data = await _client
        .from('daily_reflections')
        .select('*')
        .eq('week_id', weekId);

    return (data as List).map((e) => DailyReflectionModel.fromJson(e)).toList();
  }

  /// Get weekly review
  Future<WeeklyReviewModel?> getWeeklyReview(String weekId) async {
    final data = await _client
        .from('weekly_reviews')
        .select('*')
        .eq('week_id', weekId)
        .maybeSingle();

    if (data == null) return null;
    return WeeklyReviewModel.fromJson(data);
  }

  /// Save weekly review
  Future<void> saveWeeklyReview({
    required String weekId,
    required String learnedText,
    required String goodText,
    required String hardText,
    required String changeText,
    required List<String> nextGoals,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final existing = await getWeeklyReview(weekId);
    final payload = {
      'learned_text': learnedText,
      'good_text': goodText,
      'hard_text': hardText,
      'change_text': changeText,
      'next_goals': nextGoals,
    };

    if (existing != null) {
      await _client
          .from('weekly_reviews')
          .update(payload)
          .eq('id', existing.id);
    } else {
      await _client.from('weekly_reviews').insert({
        'user_id': uid,
        'week_id': weekId,
        ...payload,
      });
    }
  }
}
