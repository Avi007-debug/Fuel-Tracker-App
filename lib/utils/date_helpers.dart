/// Date helper utilities for analytics, greeting logic, and trip grouping.
class DateHelpers {
  DateHelpers._();

  /// Start of today (midnight).
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Start of this month.
  static DateTime get startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Start of last month.
  static DateTime get startOfLastMonth {
    final now = DateTime.now();
    final m = now.month == 1 ? 12 : now.month - 1;
    final y = now.month == 1 ? now.year - 1 : now.year;
    return DateTime(y, m);
  }

  /// End of last month (= start of this month minus 1 ms).
  static DateTime get endOfLastMonth {
    return startOfMonth.subtract(const Duration(milliseconds: 1));
  }

  /// Whether [date] is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Whether today is a weekday (Mon-Fri).
  static bool get isWeekday {
    final weekday = DateTime.now().weekday;
    return weekday >= DateTime.monday && weekday <= DateTime.friday;
  }

  /// Returns "Good Morning", "Good Afternoon", or "Good Evening".
  static String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Days elapsed since [from] until now.
  static int daysSince(DateTime from) {
    return DateTime.now().difference(from).inDays;
  }

  /// Days remaining in the current month.
  static int get daysRemainingInMonth {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return lastDay.day - now.day;
  }

  /// N days ago from now.
  static DateTime daysAgo(int n) {
    return DateTime.now().subtract(Duration(days: n));
  }

  /// Whether [date] falls within the last [days] days.
  static bool isWithinDays(DateTime date, int days) {
    return date.isAfter(daysAgo(days));
  }
}
