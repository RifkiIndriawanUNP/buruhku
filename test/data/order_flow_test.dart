import 'package:flutter_test/flutter_test.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';
import '../fake_snapshot_storage.dart';

Ord makeOrder({bool client = true, String status = 'AGREED', int price = 200000}) => Ord(
    id: 'o1', reqId: 'r-tidak-ada', title: 'Bersihkan halaman', cat: 'Taman', otherId: 'a1', otherName: 'Budi S.',
    pin: '1234', iAmClient: client, price: price, fee: 3000, status: status);

void main() {
  late AppState store;

  setUp(() => store = AppState(storage: FakeSnapshotStorage()));
  tearDown(() => store.dispose());

  group('Escrow (sisi klien)', () {
    test('bayar menahan dana dan mencatat ledger sebesar harga + biaya layanan', () {
      final o = makeOrder()..pin = '1234';
      store.orders.add(o);
      store.payOrder(o, 'QRIS');
      expect(o.escrow, 'held');
      expect(o.status, 'SCHEDULED');
      expect(store.ledger.first.type, 'escrow_hold');
      expect(store.ledger.first.amount, -(o.total + o.fee));
    });

    test('batal tanpa jadwal setelah bayar: refund penuh', () {
      final o = makeOrder();
      store.orders.add(o);
      store.payOrder(o, 'QRIS');
      store.cancelOrder(o, 'berubah rencana');
      expect(o.status, 'REFUNDED');
      expect(o.escrow, 'refunded');
      expect(store.ledger.first.type, 'refund');
      expect(store.ledger.first.amount, o.total + o.fee);
    });

    test('batal sebelum bayar: tanpa biaya dan tanpa ledger', () {
      final o = makeOrder();
      store.orders.add(o);
      store.cancelOrder(o, 'salah pesan');
      expect(o.status, 'CANCELLED');
      expect(store.ledger, isEmpty);
    });
  });

  group('Pelaksanaan pekerjaan', () {
    test('PIN salah ditolak, PIN benar memulai pekerjaan', () {
      final o = makeOrder(status: 'ARRIVED');
      store.orders.add(o);
      expect(store.startWithPin(o, '0000'), isFalse);
      expect(o.status, 'ARRIVED');
      expect(store.startWithPin(o, '1234'), isTrue);
      expect(o.status, 'IN_PROGRESS');
    });

    test('alur berangkat -> tiba -> mulai -> selesai berjalan berurutan', () {
      final o = makeOrder(status: 'SCHEDULED');
      store.orders.add(o);
      store.depart(o);
      expect(o.status, 'ON_THE_WAY');
      store.arrive(o);
      expect(o.status, 'ARRIVED');
      store.startWithPin(o, o.pin);
      store.finishJob(o);
      expect(o.status, 'PENDING_CONFIRM');
    });
  });

  group('Dana dilepas ke agen (sisi agen)', () {
    test('konfirmasi selesai: dana cair dikurangi komisi 10% dan tercatat di ledger', () {
      final o = makeOrder(client: false, status: 'PENDING_CONFIRM')..escrow = 'held';
      store.orders.add(o);
      store.completeOrder(o);
      expect(o.status, 'COMPLETED');
      expect(o.escrow, 'released');
      expect(store.balance, o.total - o.commission);
      expect(store.ledger.map((l) => l.type), containsAll(['release', 'fee']));
    });

    test('tarik saldo melebihi saldo ditolak', () {
      store.balance = 50000;
      store.pin = '123456';
      final hasil = store.withdraw(100000, 'GoPay|0812', '123456');
      expect(hasil, 'Saldo tidak cukup.');
      expect(store.balance, 50000);
    });

    test('tarik saldo dengan PIN salah ditolak', () {
      store.balance = 100000;
      store.pin = '123456';
      expect(store.withdraw(30000, 'GoPay|0812', '000000'), 'PIN salah.');
      expect(store.balance, 100000);
    });

    test('tarik saldo valid mengurangi saldo dan mencatat payout', () {
      store.balance = 100000;
      store.pin = '123456';
      expect(store.withdraw(30000, 'GoPay|0812', '123456'), isNull);
      expect(store.balance, 70000);
      expect(store.payouts.length, 1);
    });
  });
}
