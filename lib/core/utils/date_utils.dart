import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  static String toIsoDate(DateTime date) => _iso.format(date);

  static DateTime? tryParseIso(String value) {
    try {
      return _iso.parseStrict(value);
    } catch (_) {
      return null;
    }
  }
}

