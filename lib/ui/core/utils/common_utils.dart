import 'package:intl/intl.dart';

class CommonUtil {
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (now.year == date.year) {
      return DateFormat('MMM d').format(date); // e.g., Jul 25
    } else {
      return DateFormat('MMM d, yyyy').format(date); // e.g., Jul 25, 2024
    }
  }
}
