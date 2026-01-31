import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class StorageService {
  
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure Storage for Tokens
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: AppConstants.accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveIdToken(String token) async {
    print('💾 StorageService: Salvando ID token...');
    await _secureStorage.write(key: 'id_token', value: token);
    print('✅ StorageService: ID token salvo!');
  }

  Future<String?> getIdToken() async {
    print('🔍 StorageService: Buscando ID token...');
    final token = await _secureStorage.read(key: 'id_token');
    print('🔍 StorageService: ID token encontrado: ${token != null ? "SIM" : "NÃO"}');
    if (token != null) {
      print('🔍 StorageService: Token (primeiros 50 chars): ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
    }
    return token;
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: 'id_token');
  }

  // User Data
  Future<void> saveUserId(String userId) async {
    await _prefs?.setString(AppConstants.userIdKey, userId);
  }

  String? getUserId() {
    return _prefs?.getString(AppConstants.userIdKey);
  }

  Future<void> saveUserEmail(String email) async {
    await _prefs?.setString(AppConstants.userEmailKey, email);
  }

  String? getUserEmail() {
    return _prefs?.getString(AppConstants.userEmailKey);
  }

  Future<void> saveUserName(String name) async {
    await _prefs?.setString(AppConstants.userNameKey, name);
  }

  String? getUserName() {
    return _prefs?.getString(AppConstants.userNameKey);
  }

  // Email Verified Flag
  Future<void> saveEmailVerified(bool verified) async {
    print('💾 StorageService: Salvando flag EmailVerified = $verified');
    await _prefs?.setBool('email_verified', verified);
  }

  bool isEmailVerified() {
    final verified = _prefs?.getBool('email_verified') ?? false;
    print('🔍 StorageService: EmailVerified flag = $verified');
    return verified;
  }

  // First Launch
  Future<void> setFirstLaunchDone() async {
    await _prefs?.setBool(AppConstants.isFirstLaunchKey, false);
  }

  bool isFirstLaunch() {
    return _prefs?.getBool(AppConstants.isFirstLaunchKey) ?? true;
  }

  // Clear All Data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}
