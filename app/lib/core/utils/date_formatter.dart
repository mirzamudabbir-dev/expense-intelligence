import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _date = DateFormat('dd MMM yyyy');
  static final _short = DateFormat('dd MMM');
  static final _month = DateFormat('MMMM yyyy');
  static final _time = DateFormat('hh:mm a');

  static String format(DateTime dt) => _date.format(dt);
  static String short(DateTime dt) => _short.format(dt);
  static String month(DateTime dt) => _month.format(dt);
  static String time(DateTime dt) => _time.format(dt);
}
