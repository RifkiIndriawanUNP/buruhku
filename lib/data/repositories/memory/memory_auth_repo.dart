import 'dart:async';
import 'dart:math';

import '../../models/user.dart';
import '../auth_repository.dart';
import 'reactive.dart';

class MemoryAuthRepo implements AuthRepository {
  final _user = Reactive<User?>(null);
  final Map<String, String> _otpStore = {};
  User? _current;

  @override
  Stream<User?> get authStateChanges => _user.stream;

  @override
  User? get currentUser => _current;

  @override
  Future<void> requestOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _otpStore[phone] = '123456';
  }

  @override
  Future<User> verifyOtp(String phone, String code, {String? fullName}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final expected = _otpStore[phone];
    if (expected == null) {
      throw Exception('Kode OTP belum diminta untuk nomor ini.');
    }
    if (code != expected) {
      throw Exception('Kode OTP salah.');
    }
    final user = User(
      id: 'u_${_rand(6)}',
      phone: phone,
      fullName: fullName ?? 'Pengguna ${phone.substring(phone.length - 4)}',
      roles: {UserRole.client},
      createdAt: DateTime.now(),
    );
    _current = user;
    _user.set(user);
    return user;
  }

  @override
  Future<void> updateProfile({String? fullName, String? address}) async {
    if (_current == null) throw Exception('Belum login');
    _current = _current!.copyWith(
      fullName: fullName,
      defaultAddress: address,
    );
    _user.set(_current);
  }

  @override
  Future<void> becomeAgent() async {
    if (_current == null) throw Exception('Belum login');
    final roles = {..._current!.roles, UserRole.agent};
    _current = _current!.copyWith(roles: roles, isAgentVerified: true);
    _user.set(_current);
  }

  @override
  Future<void> logout() async {
    _current = null;
    _user.set(null);
  }

  String _rand(int n) {
    final r = Random();
    return List.generate(n, (_) => r.nextInt(10)).join();
  }
}