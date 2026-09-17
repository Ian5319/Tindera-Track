import 'package:intl/intl.dart';

final currencyFormatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
final dateFormatter = DateFormat('MMM d, yyyy • h:mm a');
final shortDateFormatter = DateFormat('MMM d');
