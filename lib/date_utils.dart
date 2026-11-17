abstract final class PetDates {
  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  static DateTime dateOnly([DateTime? value]) {
    final date = value ?? DateTime.now();
    return DateTime(date.year, date.month, date.day);
  }

  static String todayEyebrow(DateTime date) {
    return '星期${_weekdays[date.weekday - 1]} · ${date.month} 月 ${date.day} 日';
  }

  static String monthLabel(DateTime date) => '${date.year} 年 ${date.month} 月';

  static String reportDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String clock(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static String relativeDateTime(DateTime date, [DateTime? now]) {
    final current = now ?? DateTime.now();
    final day = dateOnly(date);
    final today = dateOnly(current);
    final days = today.difference(day).inDays;
    if (days == 0) return '今天 ${clock(date)}';
    if (days == 1) return '昨天 ${clock(date)}';
    if (days > 1 && days < 7) return '$days 天前';
    return '${date.month} 月 ${date.day} 日';
  }

  static String weekday(DateTime date) => '周${_weekdays[date.weekday - 1]}';

  static List<DateTime> currentWeek([DateTime? value]) {
    final current = dateOnly(value);
    final monday = current.subtract(Duration(days: current.weekday - 1));
    return List<DateTime>.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );
  }
}
