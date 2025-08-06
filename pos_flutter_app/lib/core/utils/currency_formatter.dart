import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _idrFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format a number to Indonesian Rupiah currency format
  /// Example: 150000 -> "Rp 150.000"
  static String formatIDR(double amount) {
    return _idrFormatter.format(amount);
  }

  /// Format a number to Indonesian Rupiah currency format with custom decimal
  /// Example: 150000.50 -> "Rp 150.000,50"
  static String formatIDRWithDecimal(double amount, {int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Parse IDR formatted string back to double
  /// Example: "Rp 150.000" -> 150000.0
  static double parseIDR(String formattedAmount) {
    // Remove currency symbol and spaces
    String cleanAmount = formattedAmount
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '') // Remove thousand separators
        .replaceAll(',', '.'); // Convert decimal separator

    return double.tryParse(cleanAmount) ?? 0.0;
  }

  /// Format number with thousand separators (no currency symbol)
  /// Example: 150000 -> "150.000"
  static String formatNumber(double amount) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(amount);
  }
}
