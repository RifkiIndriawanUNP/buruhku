// Helper JSON bersama untuk model (serialisasi lokal/API).
Map<String, dynamic> jMap(dynamic x) => Map<String, dynamic>.from(x as Map);
List<T> jList<T>(dynamic x, T Function(Map<String, dynamic>) f) =>
    ((x ?? []) as List).map((e) => f(jMap(e))).toList();
DateTime? jDate(dynamic s) => s == null ? null : DateTime.parse(s as String);
String? jDateStr(DateTime? d) => d?.toIso8601String();

List<T> listFrom<T>(dynamic x, T Function(Map<String, dynamic>) f) => jList(x, f);

