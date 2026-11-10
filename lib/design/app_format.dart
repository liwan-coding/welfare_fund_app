/// Number formatting shared by the UI.
class AppFormat {
  /// Whole-number amount with thousands separators, Western digits in every
  /// locale (matches the rest of the app): 85000 -> "85,000".
  static String amount(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}
