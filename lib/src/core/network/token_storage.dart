import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT bearer token returned by `POST /api/auth/login`
/// across app restarts.
class TokenStorage {
  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  // As of flutter_secure_storage 10.x, Android no longer needs an explicit
  // encryptedSharedPreferences flag — Jetpack's EncryptedSharedPreferences
  // was deprecated upstream by Google, and the package now auto-migrates
  // to its own cipher on first access. iOS always uses Keychain regardless.
  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  String? _cached;

  Future<String?> read() async {
    if (_cached != null) return _cached;
    _cached = await _storage.read(key: _tokenKey);
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _tokenKey);
  }
}
