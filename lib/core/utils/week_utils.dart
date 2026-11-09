import 'package:intl/intl.dart';

class WeekUtils {
  /// Returns the Monday date string (yyyy-MM-dd) for the given date (default: today).
  static String getWeekStartDate([DateTime? date]) {
    final d = date ?? DateTime.now();
    // In Dart: weekday is 1 for Monday, 7 for Sunday
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  /// Shift a week start date string by delta weeks (+1 or -1)
  static String shiftWeek(String weekStartDate, int deltaWeeks) {
    final parsed = DateFormat('yyyy-MM-dd').parse(weekStartDate);
    final shifted = parsed.add(Duration(days: deltaWeeks * 7));
    return DateFormat('yyyy-MM-dd').format(shifted);
  }

  /// Today's day of week: 1 = Monday, 7 = Sunday
  static int getTodayDayOfWeek() {
    return DateTime.now().weekday;
  }

  /// Get DateTime for a specific dayOfWeek (1..7) of a given week start
  static DateTime getDayDate(String weekStartDate, int dayOfWeek) {
    final start = DateFormat('yyyy-MM-dd').parse(weekStartDate);
    return start.add(Duration(days: dayOfWeek - 1));
  }

  /// Check if the specified day of week in given week start is today
  static bool isDayToday(String weekStartDate, int dayOfWeek) {
    final dayDate = getDayDate(weekStartDate, dayOfWeek);
    final now = DateTime.now();
    return dayDate.year == now.year &&
        dayDate.month == now.month &&
        dayDate.day == now.day;
  }

  /// Format week label like "10–16 қараша"
  static String formatWeekRange(String weekStartDate, String lang) {
    final start = DateFormat('yyyy-MM-dd').parse(weekStartDate);
    final end = start.add(const Duration(days: 6));

    final monthNamesKk = [
      'қаңтар',
      'ақпан',
      'наурыз',
      'сәуір',
      'мамыр',
      'маусым',
      'шілде',
      'тамыз',
      'қыркүйек',
      'қазан',
      'қараша',
      'желтоқсан'
    ];
    final monthNamesRu = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    final monthNamesEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    if (lang == 'kk') {
      if (start.month == end.month) {
        return '${start.day}–${end.day} ${monthNamesKk[start.month - 1]}';
      } else {
        return '${start.day} ${monthNamesKk[start.month - 1]} – ${end.day} ${monthNamesKk[end.month - 1]}';
      }
    } else if (lang == 'ru') {
      if (start.month == end.month) {
        return '${start.day}–${end.day} ${monthNamesRu[start.month - 1]}';
      } else {
        return '${start.day} ${monthNamesRu[start.month - 1]} – ${end.day} ${monthNamesRu[end.month - 1]}';
      }
    } else {
      if (start.month == end.month) {
        return '${monthNamesEn[start.month - 1]} ${start.day}–${end.day}';
      } else {
        return '${monthNamesEn[start.month - 1]} ${start.day} – ${monthNamesEn[end.month - 1]} ${end.day}';
      }
    }
  }
}
