import 'package:intl/intl.dart';

/// Philippine peso (PHP) formatting used across the app.
final NumberFormat pesoFormat = NumberFormat.currency(
  locale: 'en_PH',
  symbol: '₱',
  decimalDigits: 2,
);

String formatPeso(double amount) => pesoFormat.format(amount);
