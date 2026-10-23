import '../models/user.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<void> requestOtp(String phone);
  Future<User> verifyOtp(String phone, String code, {String? fullName});
  Future<void> updateProfile({String? fullName, String? address});
  Future<void> becomeAgent();
  Future<void> logout();
}