import 'package:buruhku/utils/json.dart';

class Payout {
  String id, dest, status;
  int amount;
  DateTime at;
  Payout({required this.id, required this.amount, required this.dest, this.status = 'Diproses', DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'a': amount, 'd': dest, 's': status, 't': jDateStr(at)};
  factory Payout.fromJson(Map<String, dynamic> j) =>
      Payout(id: j['id'], amount: j['a'], dest: j['d'], status: j['s'], at: jDate(j['t']));
}
