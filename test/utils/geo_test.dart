import 'package:flutter_test/flutter_test.dart';
import 'package:buruhku/config/env.dart';
import 'package:buruhku/utils/geo.dart';

void main() {
  test('pointAt menaruh titik tepat sejauh yang diminta dari pusat demo', () {
    for (final km in [0.4, 3.0, 7.5, 13.4]) {
      final p = pointAt(km, 'a7');
      expect(kmBetween(kMapCenter, p), closeTo(km, 0.05));
    }
  });

  test('pointAt selalu memberi titik yang sama untuk key yang sama', () {
    expect(pointAt(5, 'a3'), pointAt(5, 'a3'));
    expect(pointAt(5, 'a3'), isNot(pointAt(5, 'a4')));
  });

  test('nearestArea mengembalikan kelurahan dari titik tengahnya', () {
    for (final name in ['Palabuhanratu', 'Cikembang', 'Citepus', 'Jayanti', 'Pasirsuren', 'Sukamulya', 'Gunungguruh', 'Cibodas']) {
      expect(nearestArea(areaPoint(name)), name);
    }
  });

  test('koordinat lama (pecahan 0..1) diganti pusat demo, koordinat sungguhan dipertahankan', () {
    expect(fixLat(0.5, 0.5), Env.mapLat);
    expect(fixLng(0.5, 0.5), Env.mapLng);
    expect(fixLat(-6.9, 106.6), -6.9);
    expect(fixLng(-6.9, 106.6), 106.6);
  });
}
