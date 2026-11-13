import 'package:buruhku/utils/json.dart';

class Kyc {
  String status = 'none'; // none / pending / approved / rejected / needs_more
  String name = '', nik = '', birth = '', addr = '', emName = '', emPhone = '', bank = 'BCA', bankNo = '',
      bankHolder = '', reason = '';
  bool photo = false, ktp = false, selfie = false, skck = false, agree = false, online = false, directOk = true;
  List<String> cats = [];
  double radius = 5;
  int fromH = 8, toH = 17, tries = 0;
  DateTime? submitted;
  Map<String, dynamic> toJson() => {'status': status, 'name': name, 'nik': nik, 'birth': birth, 'addr': addr,
        'emName': emName, 'emPhone': emPhone, 'bank': bank, 'bankNo': bankNo, 'bankHolder': bankHolder,
        'reason': reason, 'photo': photo, 'ktp': ktp, 'selfie': selfie, 'skck': skck, 'agree': agree,
        'online': online, 'directOk': directOk, 'cats': cats, 'radius': radius, 'fromH': fromH, 'toH': toH,
        'tries': tries, 'submitted': jDateStr(submitted)};
  static Kyc fromJson(Map<String, dynamic> j) {
    final k = Kyc();
    k.status = j['status'];
    k.name = j['name'];
    k.nik = j['nik'];
    k.birth = j['birth'];
    k.addr = j['addr'];
    k.emName = j['emName'];
    k.emPhone = j['emPhone'];
    k.bank = j['bank'];
    k.bankNo = j['bankNo'];
    k.bankHolder = j['bankHolder'];
    k.reason = j['reason'];
    k.photo = j['photo'];
    k.ktp = j['ktp'];
    k.selfie = j['selfie'];
    k.skck = j['skck'];
    k.agree = j['agree'];
    k.online = j['online'];
    k.directOk = j['directOk'];
    k.cats = List<String>.from(j['cats']);
    k.radius = (j['radius'] as num).toDouble();
    k.fromH = j['fromH'];
    k.toH = j['toH'];
    k.tries = j['tries'];
    k.submitted = jDate(j['submitted']);
    return k;
  }
}
