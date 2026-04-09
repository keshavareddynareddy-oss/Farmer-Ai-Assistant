class Helpers {
  static String formatCurrency(double value) {
    return 'Rs ${value.toStringAsFixed(2)}';
  }

  static String formatDays(int days) {
    return days == 1 ? '1 day' : '$days days';
  }
}
