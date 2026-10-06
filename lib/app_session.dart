import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models/atlart_user.dart';
import 'services/auth_api.dart';

class AtlartSession extends ChangeNotifier {
  AtlartSession._();

  static final AtlartSession instance = AtlartSession._();
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'atlart_token';
  static const _userKey = 'atlart_user';

  String? _token;
  AtlartUser? _user;

  static String? get role => instance._user?.role;
  static String get firstName => instance._user?.nomEmprunt ?? '';

  AtlartUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;

  Future<void> restore() async {
    final token = await _storage.read(key: _tokenKey);
    final rawUser = await _storage.read(key: _userKey);

    if (token == null && rawUser == null) return;
    if (token == null || rawUser == null) {
      await _clearStorage();
      return;
    }

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Cached user must be a JSON object.');
      }
      _user = AtlartUser.fromJson(decoded);
      _token = token;
    } on FormatException catch (error) {
      debugPrint('Discarding invalid cached Atlart session: $error');
      await _clearStorage();
      return;
    } on TypeError catch (error) {
      debugPrint('Discarding invalid cached Atlart session: $error');
      await _clearStorage();
      return;
    }

    // Offline front-end mode keeps the cached preview account and deliberately
    // skips /auth/me until the Laravel API is available.
    if (!AuthApi.useBackend) return;

    try {
      final currentUser = await AuthApi.me(token);
      await _save(token, currentUser);
    } on AuthException catch (error) {
      if (error.kind == AuthErrorKind.unauthorized ||
          error.kind == AuthErrorKind.suspended) {
        await _expire();
        return;
      }
      debugPrint('Could not refresh cached Atlart session: $error');
    }
  }

  Future<void> login(String identifiant, String motDePasse) async {
    if (!AuthApi.useBackend) {
      final normalized = identifiant.trim();
      final name = normalized.contains('@')
          ? normalized.substring(0, normalized.indexOf('@'))
          : normalized;
      await _save(
        'atlart-local-preview',
        AtlartUser(
          id: 'local-preview-user',
          email: normalized.contains('@') ? normalized : 'preview@atlart.local',
          nomEmprunt: name.isEmpty ? 'Visiteur Atlart' : name,
          role: 'visiteur',
        ),
      );
      return;
    }

    final result = await AuthApi.login(identifiant, motDePasse);
    await _save(result.token, result.user);
  }

  Future<void> register({
    required String nomEmprunt,
    required String email,
    required String motDePasse,
    required String paysCode,
    String? localisation,
    required String roleSouhaite,
  }) async {
    if (!AuthApi.useBackend) {
      // Local preview only: use the requested role to preview its UI.
      // Laravel remains the source of truth and creates new accounts as visitors.
      await _save(
        'atlart-local-preview',
        AtlartUser(
          id: 'local-preview-user',
          email: email.trim(),
          nomEmprunt: nomEmprunt.trim(),
          role: roleSouhaite,
          paysCode: paysCode,
          ville: localisation,
        ),
      );
      return;
    }

    final result = await AuthApi.register(
      nomEmprunt: nomEmprunt,
      email: email,
      motDePasse: motDePasse,
      paysCode: paysCode,
      localisation: localisation,
      roleSouhaite: roleSouhaite,
    );
    await _save(result.token, result.user);
  }

  Future<void> refresh() async {
    if (!AuthApi.useBackend) return;

    final token = _token;
    if (token == null) return;

    try {
      await _save(token, await AuthApi.me(token));
    } on AuthException catch (error) {
      if (error.kind == AuthErrorKind.unauthorized ||
          error.kind == AuthErrorKind.suspended) {
        await _expire();
        return;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final token = _token;
    await _expire();
    if (token == null || !AuthApi.useBackend) return;

    try {
      await AuthApi.logout(token);
    } on AuthException catch (error) {
      debugPrint('Local logout succeeded; server token revocation failed: $error');
    }
  }

  Future<void> handleUnauthorized() => _expire();

  Future<void> _save(String token, AtlartUser user) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } catch (error, stackTrace) {
      try {
        await _clearStorage();
      } catch (cleanupError, cleanupStackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: cleanupError,
            stack: cleanupStackTrace,
            library: 'session storage cleanup',
          ),
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    _token = token;
    _user = user;
    notifyListeners();
  }

  Future<void> _expire() async {
    _token = null;
    _user = null;
    notifyListeners();
    await _clearStorage();
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
