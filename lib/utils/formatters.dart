import 'package:intl/intl.dart';

/// Currency, distance, and number formatters tuned for ₹ / km / L.
class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _currencyDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _decimal1 = NumberFormat('#,##0.0', 'en_IN');
  static final _decimal2 = NumberFormat('#,##0.00', 'en_IN');
  static final _integer = NumberFormat('#,##0', 'en_IN');
  static final _dateShort = DateFormat('d MMM');
  static final _dateFull = DateFormat('d MMM yyyy');
  static final _time = DateFormat('h:mm a');
  static final _dateTime = DateFormat('d MMM, h:mm a');

  /// ₹1,250
  static String currency(double value) => _currency.format(value);

  /// ₹1,250.75
  static String currencyDecimal(double value) =>
      _currencyDecimal.format(value);

  /// 52.4
  static String decimal1(double value) => _decimal1.format(value);

  /// 52.43
  static String decimal2(double value) => _decimal2.format(value);

  /// 1,250
  static String integer(double value) => _integer.format(value);

  /// 12 Jun
  static String dateShort(DateTime dt) => _dateShort.format(dt);

  /// 12 Jun 2025
  static String dateFull(DateTime dt) => _dateFull.format(dt);

  /// 3:45 PM
  static String time(DateTime dt) => _time.format(dt);

  /// 12 Jun, 3:45 PM
  static String dateTime(DateTime dt) => _dateTime.format(dt);

  /// "52.4 km/L"
  static String mileage(double kmPerL) => '${decimal1(kmPerL)} km/L';

  /// "2.4 L"
  static String litres(double l) => '${decimal1(l)} L';

  /// "15.6 km"
  static String distance(double km) => '${decimal1(km)} km';

  /// "₹3.2/km"
  static String costPerKm(double cost) => '₹${decimal1(cost)}/km';

  /// "93%"
  static String percentage(double fraction) =>
      '${(fraction * 100).round()}%';
}
