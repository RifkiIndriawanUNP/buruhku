import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
final _date = DateFormat('dd MMM yyyy, HH:mm', 'id');

String rupiah(num v) => _idr.format(v);
String fmtDate(DateTime d) => _date.format(d);
String fmtDuration(Duration d) {
  if (d.inHours > 0) return '${d.inHours}j ${d.inMinutes % 60}m';
  return '${d.inMinutes}m';
}