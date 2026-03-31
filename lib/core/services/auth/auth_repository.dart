import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'auth_service.dart';

class AuthRepository {
  final AuthService authService;
  final FlutterSecureStorage _secureStorage;
  static const String _userBoxName = 'auth_user';
  static const String _tokenKey = 'access_token';
  static const String _userIdKey = 'user_id';

  AuthRepository({
    required this.authService,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // Get saved user ID from local storage
  Future<String?> getSavedUserId() async {
    final box = await Hive.openBox(_userBoxName);
    return box.get(_userIdKey);
  }

  // Save user info locally after successful login
  Future<void> saveUserInfo({
    required String userId,
    required String email,
  }) async {
    final box = await Hive.openBox(_userBoxName);
    await box.put(_userIdKey, userId);
    await box.put('email', email);
    await box.put('loginTime', DateTime.now().millisecondsSinceEpoch);
  }

  // Get saved user email
  Future<String?> getSavedUserEmail() async {
    final box = await Hive.openBox(_userBoxName);
    return box.get('email');
  }

  // Clear user info on logout
  Future<void> clearUserInfo() async {
    final box = await Hive.openBox(_userBoxName);
    await box.clear();
  }

  // Check if user was logged in before
  Future<bool> hasUserInfo() async {
    final userId = await getSavedUserId();
    return userId != null && userId.isNotEmpty;
  }

  // Get last login timestamp
  Future<int?> getLastLoginTime() async {
    final box = await Hive.openBox(_userBoxName);
    return box.get('loginTime');
  }

  // Save auth token securely
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  // Get auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Delete auth token
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
