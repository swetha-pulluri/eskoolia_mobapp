/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is email
  bool get isEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  /// Check if string is phone number
  bool get isPhoneNumber {
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    return phoneRegex.hasMatch(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Check if string is null or empty
  bool get isNullOrEmpty => trim().isEmpty;
}

/// Nullable String extensions
extension NullableStringExtensions on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// Get string or default
  String orDefault(String defaultValue) => this ?? defaultValue;
}
