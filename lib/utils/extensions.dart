extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  bool isValidEmail() {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
}

extension ListExtension<T> on List<T> {
  List<T> removeDuplicates() {
    return toSet().toList();
  }

  T? firstWhereOrNull(bool Function(T element) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }

  List<T> chunk(int size) {
    if (size <= 0) throw ArgumentError('Size must be positive');
    final chunks = <T>[];
    for (var i = 0; i < length; i += size) {
      chunks.addAll(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

extension DateTimeExtension on DateTime {
  String toFormattedString() {
    return '$day/$month/$year';
  }

  bool isToday() {
    final now = DateTime.now();
    return day == now.day && month == now.month && year == now.year;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return day == yesterday.day &&
        month == yesterday.month &&
        year == yesterday.year;
  }

  String timeAgo() {
    final duration = DateTime.now().difference(this);

    if (duration.inDays > 365) {
      return '${(duration.inDays / 365).floor()} year${(duration.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (duration.inDays > 30) {
      return '${(duration.inDays / 30).floor()} month${(duration.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
