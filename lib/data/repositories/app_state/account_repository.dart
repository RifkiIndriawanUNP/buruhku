part of 'app_state.dart';

/// Akun: login/OTP, profil, tempat tersimpan, KYC.
class AccountRepository extends RepoBase {
  AccountRepository(super.hub);

  // ---- akses ke state bersama & domain lain (lewat AppState) ----
  void _wipe() => hub._wipe();
  Map<String, dynamic> _dump() => hub._dump();
  bool get onboarded => hub.onboarded;
  set onboarded(bool v) => hub.onboarded = v;
  bool get loggedIn => hub.loggedIn;
  set loggedIn(bool v) => hub.loggedIn = v;
  bool get agentMode => hub.agentMode;
  set agentMode(bool v) => hub.agentMode = v;
  String get phone => hub.phone;
  set phone(String v) => hub.phone = v;
  String get name => hub.name;
  set name(String v) => hub.name = v;
  String get address => hub.address;
  set address(String v) => hub.address = v;
  String get emName => hub.emName;
  set emName(String v) => hub.emName = v;
  String get emPhone => hub.emPhone;
  set emPhone(String v) => hub.emPhone = v;
  String get pin => hub.pin;
  set pin(String v) => hub.pin = v;
  Kyc get kyc => hub.kyc;
  set kyc(Kyc v) => hub.kyc = v;
  List<Note> get notes => hub.notes;
  set notes(List<Note> v) => hub.notes = v;
  List<SavedLoc> get places => hub.places;
  set places(List<SavedLoc> v) => hub.places = v;
  DateTime get lastActive => hub.lastActive;
  set lastActive(DateTime v) => hub.lastActive = v;
  int get tab => hub.tab;
  set tab(int v) => hub.tab = v;
  String get otp => hub.otp;
  set otp(String v) => hub.otp = v;
  String get pendingPhone => hub.pendingPhone;
  set pendingPhone(String v) => hub.pendingPhone = v;
  int get otpTries => hub.otpTries;
  set otpTries(int v) => hub.otpTries = v;
  DateTime? get otpLock => hub.otpLock;
  set otpLock(DateTime? v) => hub.otpLock = v;
  Random get _rnd => hub._rnd;
  String nid(String p) => hub.nid(p);
  void notify(String t, String b) => hub.notify(t, b);
  Chat chatFor({required String type, required String refId, required String otherId, required String otherName, required bool otherAgent, String title = ''}) => hub.chatFor(type: type, refId: refId, otherId: otherId, otherName: otherName, otherAgent: otherAgent, title: title);

  // ================= auth =================
  bool get otpLocked => otpLock != null && DateTime.now().isBefore(otpLock!);
  String requestOtp(String ph) {
    pendingPhone = ph;
    otp = (100000 + _rnd.nextInt(900000)).toString();
    return otp;
  }

  String? checkOtp(String code) {
    if (otpLocked) return 'Terlalu banyak percobaan. Coba lagi dalam 1 menit.';
    if (code == otp) {
      otpTries = 0;
      return null;
    }
    otpTries++;
    if (otpTries >= 5) {
      otpLock = DateTime.now().add(const Duration(minutes: 1));
      otpTries = 0;
      return 'OTP salah 5 kali. Akun dikunci sementara 1 menit.';
    }
    return 'Kode OTP salah (${5 - otpTries} percobaan lagi).';
  }

  void finishOnboarding() {
    onboarded = true;
    notifyListeners();
  }

  void completeLogin() {
    if (phone.isNotEmpty && phone != pendingPhone) _wipe();
    phone = pendingPhone;
    loggedIn = true;
    onboarded = true;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    agentMode = false;
    tab = 0;
    notifyListeners();
  }

  void saveProfile({required String n, String? addr, String? en, String? ep}) {
    name = n;
    if (addr != null) address = addr;
    if (en != null) emName = en;
    if (ep != null) emPhone = ep;
    if (notes.isEmpty) notify('Selamat datang di Buruhku', 'Buat request pertamamu atau jelajahi agen terdekat.');
    notifyListeners();
  }

  void deleteAccount() {
    _wipe();
    phone = '';
    loggedIn = false;
    onboarded = false;
    notifyListeners();
  }

  String exportJson() {
    final d = _dump();
    d.remove('pin');
    return const JsonEncoder.withIndent('  ').convert(d);
  }

  void setMode(bool agent) {
    agentMode = agent;
    tab = 0;
    notifyListeners();
  }

  void goTab(int i) {
    tab = i;
    notifyListeners();
  }

  void touch() => lastActive = DateTime.now();

  void setAddress(String v) {
    address = v;
    notifyListeners();
  }

  // ================= lokasi tersimpan =================
  void addPlace(String label, String addr, LatLng pin) {
    places.add(SavedLoc(id: nid('PL'), label: label, address: addr, lat: pin.latitude, lng: pin.longitude));
    if (address.isEmpty) address = addr;
    notifyListeners();
  }

  void updatePlace(SavedLoc p, String label, String addr, LatLng pin) {
    if (address == p.address) address = addr;
    p.label = label;
    p.address = addr;
    p.lat = pin.latitude;
    p.lng = pin.longitude;
    notifyListeners();
  }

  void deletePlace(SavedLoc p) {
    places.remove(p);
    notifyListeners();
  }

  // ================= KYC =================
  void submitKyc() {
    kyc.status = 'pending';
    kyc.submitted = DateTime.now();
    kyc.tries++;
    kyc.reason = '';
    notify('Pendaftaran agen dikirim', 'Cek otomatis lolos. Data kamu masuk antrean review admin.');
    notifyListeners();
  }

  void adminKyc(String act, [String reason = '']) {
    if (act == 'approve') {
      kyc.status = 'approved';
      kyc.online = true;
      lastActive = DateTime.now();
      notify('Verifikasi disetujui', 'Kamu sekarang bisa menerima order. Mulai dari Mode Agen.');
      final c = chatFor(type: 'direct', refId: '', otherId: 'c:Ibu Mawar', otherName: 'Ibu Mawar', otherAgent: false);
      if (c.msgs.isEmpty) {
        c.msgs.add(Msg(id: nid('m'), from: 'other', body: 'Halo, saya dapat nama kamu dari tetangga. Bisa bantu bersihkan gudang kecil?'));
        c.msgs.add(Msg(id: nid('m'), from: 'other', type: 'order_offer', body: 'Penawaran order', data: {
          'title': 'Bersihkan gudang kecil', 'cat': 'clean', 'desc': 'Membuang barang bekas dan menyapu gudang ukuran 3x4 meter.',
          'address': 'Jl. Kenanga 12, Cikembang', 'price': 180000, 'ptype': 'lump', 'dur': 0.0, 'when': 'Besok, 09:00', 'sched': 'date',
          'schedAt': DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1, 9).toIso8601String(),
          'status': 'pending', 'by': 'other'}));
        c.unread = 2;
      }
    } else if (act == 'reject') {
      kyc.status = 'rejected';
      kyc.reason = reason.isEmpty ? 'Foto KTP kurang jelas.' : reason;
      notify('Verifikasi ditolak', kyc.reason);
    } else {
      kyc.status = 'needs_more';
      kyc.reason = reason.isEmpty ? 'Mohon unggah ulang selfie dengan KTP.' : reason;
      notify('Data tambahan diperlukan', kyc.reason);
    }
    notifyListeners();
  }

  void uploadSkck() {
    kyc.skck = true;
    notify('SKCK diunggah', 'SKCK tercatat. Level L2 aktif setelah 5 pekerjaan dengan rating baik.');
    notifyListeners();
  }
}
