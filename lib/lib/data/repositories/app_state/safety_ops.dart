part of 'app_state.dart';

/// Pintu masuk lama untuk laporan, SOS, dan tiket. Logikanya kini ada di
/// SafetyRepository; layar yang belum dipindah ke ViewModel tetap memakai ini.
extension SafetyOps on AppState {
  List<Rep> get reports => safety.reports;
  List<Sos> get soses => safety.soses;
  List<Tix> get tickets => safety.tickets;

  Rep fileReport({required String cat, required String desc, String target = '', String orderId = '', int evid = 0}) =>
      safety.fileReport(cat: cat, desc: desc, target: target, orderId: orderId, evid: evid);
  void adminTriage(Rep r, String act) => safety.adminTriage(r, act);
  Sos triggerSos(String orderId) => safety.triggerSos(orderId);
  void resolveSos(Sos s) => safety.resolveSos(s);
  Tix createTicket(String subject, String body) => safety.createTicket(subject, body);
}
