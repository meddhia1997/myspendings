import 'package:intl/intl.dart';

String formatMoney(int minorUnits, String currencyCode) {
  final format = NumberFormat.currency(
    name: currencyCode,
    symbol: '$currencyCode ',
    decimalDigits: 2,
  );
  return format.format(minorUnits / 100);
}

int parseAmountToMinor(String input) {
  final normalized = input.replaceAll(',', '.').trim();
  final value = double.tryParse(normalized) ?? 0;
  return (value * 100).round();
}
