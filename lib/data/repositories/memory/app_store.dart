import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buruhku/data/models/models.dart';
import 'package:buruhku/data/repositories/snapshot_storage.dart';
import 'package:buruhku/data/seed/seed.dart';
import 'package:buruhku/core/ui/ui.dart' show rp, fdt;

part 'account_ops.dart';
part 'catalog_ops.dart';
part 'request_ops.dart';
part 'order_ops.dart';
part 'agent_ops.dart';
part 'chat_ops.dart';
part 'safety_ops.dart';
part 'sim_ops.dart';

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child}) : super(notifier: store);
}

extension StoreCtx on BuildContext {
  AppStore get s => dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
  AppStore get r => getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// Order langsung yang menunggu respons agen (muncul di Home agen dan di chat).
class DirectReq {
  final Chat chat;
  final Msg msg;
  DirectReq(this.chat, this.msg);
}

class AppStore extends ChangeNotifier {
  AppStore({required SnapshotStorage storage}) : _storage = storage;

  /// Jumlah agen yang terus dicari untuk daftar "Sedang mencari agen" pada request banyak agen.
  static const int kSearchTarget = 5;

  final SnapshotStorage _storage;
  final agents = buildAgents();
  late final List<Svc> simSvcs = buildServices(agents);
  final _rnd = Random();
  Timer? _tick, _saveT;

  // ---- akun ----
  bool onboarded = false, loggedIn = false, agentMode = false;
  String phone = '', name = '', address = '', emName = '', emPhone = '', pin = '';
  bool nOrder = true, nChat = true, nPromo = false, biometric = false;
  List<String> wallets = []; // 'GoPay|0812xxxx'
  Set<String> favs = {}, blocked = {}, hidden = {};
  Kyc kyc = Kyc();
  // ---- data ----
  List<Req> reqs = [];
  List<Ord> orders = [];
  List<Chat> chats = [];
  List<Note> notes = [];
  List<Led> ledger = [];
  List<Rep> reports = [];
  List<Sos> soses = [];
  List<Tix> tickets = [];
  List<Disp> disputes = [];
  List<Rev> revs = [];
  List<Payout> payouts = [];
  List<SavedLoc> places = [];
  List<Svc> mySvcs = [];
  Set<String> favSvc = {};
  Map<String, List<int>> rate = {};
  int balance = 0, penalty = 0, idc = 1000, declines = 0, accepts = 0;
  DateTime lastActive = DateTime.now();
  // ---- sementara (tidak disimpan) ----
  int tab = 0;
  String openChatId = '';
  Note? toastNote;
  String otp = '123456', pendingPhone = '';
  int otpTries = 0;
  DateTime? otpLock;

  String nid(String p) => '$p${++idc}';
  String _pin() => (1000 + _rnd.nextInt(9000)).toString();
  int _round5(num n) => ((n / 5000).round() * 5000).toInt();
  T _pick<T>(List<T> l) => l[_rnd.nextInt(l.length)];
  int _h(String s) => s.codeUnits.fold(0, (a, b) => a + b);

  // ================= persistensi =================
  Future<void> init() async {
    final raw = await _storage.load();
    var ok = false;
    if (raw != null) {
      try {
        _load(raw);
        ok = true;
      } catch (_) {
        ok = false;
      }
    }
    if (!ok) _seed();
    _tick = Timer.periodic(const Duration(seconds: 3), (_) => this._onTick()); // ignore: unnecessary_this
  }

  @override
  void dispose() {
    _tick?.cancel();
    _saveT?.cancel();
    super.dispose();
  }

  void _seed() {
    reqs = seedIncoming();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveT?.cancel();
    _saveT = Timer(const Duration(milliseconds: 600), _save);
  }

  void _save() => _storage.save(_dump());

  Map<String, dynamic> _dump() => {
        'onboarded': onboarded, 'loggedIn': loggedIn, 'agentMode': agentMode, 'phone': phone, 'name': name,
        'address': address, 'emName': emName, 'emPhone': emPhone, 'pin': pin, 'nOrder': nOrder, 'nChat': nChat,
        'nPromo': nPromo, 'biometric': biometric, 'wallets': wallets, 'favs': favs.toList(),
        'blocked': blocked.toList(), 'hidden': hidden.toList(), 'kyc': kyc.toJson(),
        'reqs': reqs.map((e) => e.toJson()).toList(), 'orders': orders.map((e) => e.toJson()).toList(),
        'chats': chats.map((e) => e.toJson()).toList(), 'notes': notes.map((e) => e.toJson()).toList(),
        'ledger': ledger.map((e) => e.toJson()).toList(), 'reports': reports.map((e) => e.toJson()).toList(),
        'soses': soses.map((e) => e.toJson()).toList(), 'tickets': tickets.map((e) => e.toJson()).toList(),
        'disputes': disputes.map((e) => e.toJson()).toList(), 'revs': revs.map((e) => e.toJson()).toList(),
        'payouts': payouts.map((e) => e.toJson()).toList(), 'places': places.map((e) => e.toJson()).toList(), 'mySvcs': mySvcs.map((e) => e.toJson()).toList(),
        'favSvc': favSvc.toList(), 'rate': rate, 'balance': balance,
        'penalty': penalty, 'idc': idc, 'declines': declines, 'accepts': accepts, 'lastActive': lastActive.toIso8601String(),
      };

  void _load(Map<String, dynamic> j) {
    onboarded = j['onboarded'];
    loggedIn = j['loggedIn'];
    agentMode = j['agentMode'];
    phone = j['phone'];
    name = j['name'];
    address = j['address'];
    emName = j['emName'];
    emPhone = j['emPhone'];
    pin = j['pin'];
    nOrder = j['nOrder'];
    nChat = j['nChat'];
    nPromo = j['nPromo'];
    biometric = j['biometric'];
    wallets = List<String>.from(j['wallets']);
    favs = Set<String>.from(j['favs']);
    blocked = Set<String>.from(j['blocked']);
    hidden = Set<String>.from(j['hidden']);
    kyc = Kyc.fromJson(Map<String, dynamic>.from(j['kyc']));
    reqs = listFrom(j['reqs'], Req.fromJson);
    orders = listFrom(j['orders'], Ord.fromJson);
    chats = listFrom(j['chats'], Chat.fromJson);
    notes = listFrom(j['notes'], Note.fromJson);
    ledger = listFrom(j['ledger'], Led.fromJson);
    reports = listFrom(j['reports'], Rep.fromJson);
    soses = listFrom(j['soses'], Sos.fromJson);
    tickets = listFrom(j['tickets'], Tix.fromJson);
    disputes = listFrom(j['disputes'], Disp.fromJson);
    revs = listFrom(j['revs'], Rev.fromJson);
    payouts = listFrom(j['payouts'], Payout.fromJson);
    places = listFrom(j['places'], SavedLoc.fromJson);
    mySvcs = listFrom(j['mySvcs'], Svc.fromJson);
    favSvc = Set<String>.from(j['favSvc'] ?? []);
    rate = (j['rate'] as Map).map((k, v) => MapEntry(k as String, List<int>.from(v)));
    balance = j['balance'];
    penalty = j['penalty'];
    idc = j['idc'];
    declines = j['declines'];
    accepts = j['accepts'];
    lastActive = DateTime.parse(j['lastActive']);
  }

  void _wipe() {
    onboarded = true;
    agentMode = false;
    name = address = emName = emPhone = pin = '';
    wallets = [];
    favs = {};
    blocked = {};
    hidden = {};
    kyc = Kyc();
    orders = [];
    chats = [];
    notes = [];
    ledger = [];
    reports = [];
    soses = [];
    tickets = [];
    disputes = [];
    revs = [];
    payouts = [];
    places = [];
    mySvcs = [];
    favSvc = {};
    rate = {};
    balance = penalty = declines = accepts = 0;
    tab = 0;
    _seed();
  }
}
