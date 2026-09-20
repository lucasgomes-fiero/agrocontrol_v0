import 'package:intl/intl.dart';

class AppFormatters {
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _month = DateFormat('MMM/yy', 'pt_BR');

  static String date(DateTime? value) => value == null ? '—' : _date.format(value);
  static String month(DateTime value) => _month.format(value).replaceAll('.', '');
  static String isoDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

  static double? decimal(String value) {
    var normalized = value.trim().replaceAll(' ', '');
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '.');
    }
    return double.tryParse(normalized);
  }

  static String weight(num value) =>
      '${value.toDouble().toStringAsFixed(value % 1 == 0 ? 0 : 1).replaceAll('.', ',')} kg';

  static DateTime? parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
