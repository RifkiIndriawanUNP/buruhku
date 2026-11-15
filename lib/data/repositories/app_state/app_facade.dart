part of 'app_state.dart';

/// Fasad: menjaga API lama `store.xxx` agar layar yang belum memakai ViewModel tetap jalan.
/// Semua logika ada di repository masing-masing.
extension AccountRepositoryFacade on AppState {
  bool get otpLocked => accountRepo.otpLocked;
  String requestOtp(String ph) => accountRepo.requestOtp(ph);
  String? checkOtp(String code) => accountRepo.checkOtp(code);
  void finishOnboarding() => accountRepo.finishOnboarding();
  void completeLogin() => accountRepo.completeLogin();
  void logout() => accountRepo.logout();
  void saveProfile({required String n, String? addr, String? en, String? ep}) => accountRepo.saveProfile(n: n, addr: addr, en: en, ep: ep);
  void deleteAccount() => accountRepo.deleteAccount();
  String exportJson() => accountRepo.exportJson();
  void setMode(bool agent) => accountRepo.setMode(agent);
  void goTab(int i) => accountRepo.goTab(i);
  void touch() => accountRepo.touch();
  void setAddress(String v) => accountRepo.setAddress(v);
  void addPlace(String label, String addr, LatLng pin) => accountRepo.addPlace(label, addr, pin);
  void updatePlace(SavedLoc p, String label, String addr, LatLng pin) => accountRepo.updatePlace(p, label, addr, pin);
  void deletePlace(SavedLoc p) => accountRepo.deletePlace(p);
  void submitKyc() => accountRepo.submitKyc();
  void adminKyc(String act, [String reason = '']) => accountRepo.adminKyc(act, reason);
  void uploadSkck() => accountRepo.uploadSkck();
}

extension NotificationRepositoryFacade on AppState {
  void notify(String t, String b, {String? refType, String? refId}) => notificationRepo.notify(t, b, refType: refType, refId: refId);
  int get unreadNotes => notificationRepo.unreadNotes;
  int get unreadChats => notificationRepo.unreadChats;
  void readAllNotes() => notificationRepo.readAllNotes();
}

extension OrderRepositoryFacade on AppState {
  void payOrder(Ord o, String method) => orderRepo.payOrder(o, method);
  void chooseCod(Ord o) => orderRepo.chooseCod(o);
  String cancelOrder(Ord o, reason, {bool forceFull = false}) => orderRepo.cancelOrder(o, reason, forceFull: forceFull);
  void claimClientNoShow(Ord o) => orderRepo.claimClientNoShow(o);
  void demoNoShow(Ord o) => orderRepo.demoNoShow(o);
  void demoSkip(Ord o) => orderRepo.demoSkip(o);
  void confirmAsAgent(Ord o) => orderRepo.confirmAsAgent(o);
  void depart(Ord o) => orderRepo.depart(o);
  void arrive(Ord o) => orderRepo.arrive(o);
  bool startWithPin(Ord o, String p) => orderRepo.startWithPin(o, p);
  void finishJob(Ord o) => orderRepo.finishJob(o);
  void confirmArrival(Ord o) => orderRepo.confirmArrival(o);
  void completeOrder(Ord o, {bool auto = false}) => orderRepo.completeOrder(o, auto: auto);
  void requestChange(Ord o, int amount, String reason, bool byMe) => orderRepo.requestChange(o, amount, reason, byMe);
  void respondChange(Ord o, bool ok) => orderRepo.respondChange(o, ok);
  void tip(Ord o, int amt) => orderRepo.tip(o, amt);
  void submitReview(Ord o, int rating, List<String> tags, String comment) => orderRepo.submitReview(o, rating, tags, comment);
  Disp openDispute(Ord o, String type, String desc, int evid) => orderRepo.openDispute(o, type, desc, evid);
  void resolveDispute(Disp d, String decision) => orderRepo.resolveDispute(d, decision);
  void cancelDispute(Disp d) => orderRepo.cancelDispute(d);
}

extension WalletRepositoryFacade on AppState {
  int get held => walletRepo.held;
  String? withdraw(int amount, String dest, String pinIn) => walletRepo.withdraw(amount, dest, pinIn);
  int earned(Duration d) => walletRepo.earned(d);
  int get myJobs => walletRepo.myJobs;
  double get myRating => walletRepo.myRating;
  int get myLevel => walletRepo.myLevel;
  double get acceptRate => walletRepo.acceptRate;
}

extension CatalogRepositoryFacade on AppState {
  Agent agentById(String id) => catalogRepo.agentById(id);
  double ratingOf(Agent a) => catalogRepo.ratingOf(a);
  List<Rev> reviewsOf(String id) => catalogRepo.reviewsOf(id);
  List<Agent> searchAgents({String? cat, String q = '', double maxDist = 15, double minRating = 0, bool verified = false, bool online = false, int maxBase = 999999, String sort = 'relevansi'}) => catalogRepo.searchAgents(cat: cat, q: q, maxDist: maxDist, minRating: minRating, verified: verified, online: online, maxBase: maxBase, sort: sort);
  void toggleFav(String id) => catalogRepo.toggleFav(id);
  Svc? svcById(String id) => catalogRepo.svcById(id);
  List<Svc> svcsOfAgent(String agentId) => catalogRepo.svcsOfAgent(agentId);
  List<Svc> svcsNear({String? cat, String q = '', String sort = 'jarak'}) => catalogRepo.svcsNear(cat: cat, q: q, sort: sort);
  void toggleFavSvc(String id) => catalogRepo.toggleFavSvc(id);
  void addSvc(Svc v) => catalogRepo.addSvc(v);
  void updateSvc(Svc v) => catalogRepo.updateSvc(v);
  void deleteSvc(Svc v) => catalogRepo.deleteSvc(v);
  List<DirectReq> get incomingDirect => catalogRepo.incomingDirect;
  String? acceptDirect(Chat c, Msg m) => catalogRepo.acceptDirect(c, m);
  void rejectDirect(Chat c, Msg m) => catalogRepo.rejectDirect(c, m);
  void _spawnSimDirect() => catalogRepo._spawnSimDirect();
}

extension RequestRepositoryFacade on AppState {
  List<String> moderate(String text) => requestRepo.moderate(text);
  int interestCount(Req r) => requestRepo.interestCount(r);
  List<Acc> activeAcc(Req r) => requestRepo.activeAcc(r);
  List<Req> get myReqs => requestRepo.myReqs;
  void _refreshReq(Req r) => requestRepo._refreshReq(r);
  List<String> submitReq(Req r) => requestRepo.submitReq(r);
  void afterEdit(Req r, bool material) => requestRepo.afterEdit(r, material);
  void cancelReq(Req r) => requestRepo.cancelReq(r);
  void relist(Req r, {double addRadius = 0, int addPrice = 0}) => requestRepo.relist(r, addRadius: addRadius, addPrice: addPrice);
  void declineAcc(Req r, Acc a) => requestRepo.declineAcc(r, a);
  void adminApproveReq(Req r) => requestRepo.adminApproveReq(r);
  void adminRejectReq(Req r) => requestRepo.adminRejectReq(r);
  DateTime? _schedOf(Req r) => requestRepo._schedOf(r);
  Ord? selectAgent(Req r, Acc a) => requestRepo.selectAgent(r, a);
  int startGroup(Req r) => requestRepo.startGroup(r);
  void inviteAgent(Req r, Agent a) => requestRepo.inviteAgent(r, a);
  Chat? _chatOf(String refId, String otherId) => requestRepo._chatOf(refId, otherId);
  Chat? chatOfOrder(Ord o) => requestRepo.chatOfOrder(o);
  Req? reqById(String id) => requestRepo.reqById(id);
  Disp? disputeOf(String id) => requestRepo.disputeOf(id);
  Ord? orderById(String id) => requestRepo.orderById(id);
  void _reopenSlot(Ord o, [String? note]) => requestRepo._reopenSlot(o, note);
}

extension ChatRepositoryFacade on AppState {
  Chat chatFor({required String type, required String refId, required String otherId, required String otherName, required bool otherAgent, String title = ''}) => chatRepo.chatFor(type: type, refId: refId, otherId: otherId, otherName: otherName, otherAgent: otherAgent, title: title);
  Chat? chatById(String id) => chatRepo.chatById(id);
  void markRead(Chat c) => chatRepo.markRead(c);
  void _sys(Chat c, String t) => chatRepo._sys(c, t);
  void _sysFor(Ord o, String t) => chatRepo._sysFor(o, t);
  bool looksFraud(String t) => chatRepo.looksFraud(t);
  void _incoming(Chat c, String body, {String type = 'text', Map<String, dynamic>? data, bool silent = false}) => chatRepo._incoming(c, body, type: type, data: data, silent: silent);
  void sendText(Chat c, String text) => chatRepo.sendText(c, text);
  void sendMedia(Chat c, String type, String body, [Map<String, dynamic>? data]) => chatRepo.sendMedia(c, type, body, data);
  void shareWa(Chat c, String number) => chatRepo.shareWa(c, number);
  void shareEwallet(Chat c, String wallet, String purpose) => chatRepo.shareEwallet(c, wallet, purpose);
  void blockUser(Chat c) => chatRepo.blockUser(c);
  void sendOffer(Chat c, int price, String ptype, {String note = ''}) => chatRepo.sendOffer(c, price, ptype, note: note);
  void sendOrderOffer(Chat c, Map<String, dynamic> d) => chatRepo.sendOrderOffer(c, d);
  void respondOffer(Chat c, Msg m, String act, {int? counter}) => chatRepo.respondOffer(c, m, act, counter: counter);
}

extension AgentModeRepositoryFacade on AppState {
  List<Req> get incoming => agentModeRepo.incoming;
  String? agentAccept(Req r, {int? counter, String note = ''}) => agentModeRepo.agentAccept(r, counter: counter, note: note);
  void agentReject(Req r) => agentModeRepo.agentReject(r);
  void withdrawAcc(Req r) => agentModeRepo.withdrawAcc(r);
  void setOnline(bool v) => agentModeRepo.setOnline(v);
  void _simClientSelects(Req r, Acc a) => agentModeRepo._simClientSelects(r, a);
  void _spawnSimReq() => agentModeRepo._spawnSimReq();
}

extension SimulatedBackendServiceFacade on AppState {
  void _onTick() => simulator._onTick();
}

