import 'package:intl/intl.dart';

/// Date utility functions
class DateUtils {
  DateUtils._();

  /// Get time-based greeting word (morning, afternoon, evening)
  static String getTimeWord() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  /// Get time-based emoji
  static String getTimeEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  /// Format date as "Wednesday, July 16, 2026"
  static String getFormattedDate([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    return DateFormat('EEEE, MMMM d, yyyy').format(targetDate);
  }

  /// Get relative time string (1m ago, 2h ago, Yesterday, 3d ago)
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '${mins < 1 ? 1 : mins}m ago';
    }
    
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    
    final days = difference.inDays;
    if (days == 1) return 'Yesterday';
    
    return '${days}d ago';
  }

  /// Get relative time from ISO string
  static String getRelativeTimeFromIso(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return getRelativeTime(dateTime);
    } catch (e) {
      return '';
    }
  }
}
