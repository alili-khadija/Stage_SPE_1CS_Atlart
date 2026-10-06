import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/atlart_user.dart';

enum AuthErrorKind {
  invalidCredentials,
  validation,
  suspended,
  unauthorized,
  network,
  server,
}

class AuthException implements Exception {
  const AuthException(
    this.kind,
    this.message, {
    this.fieldErrors = const {},
  });

  final AuthErrorKind kind;
  final String message;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AtlartUser user;
}

class AuthApi {
  AuthApi._();

  // Laravel auth is intentionally opt-in while the backend is unavailable.
  // Enable it later with --dart-define=ATLART_USE_BACKEND=true.
  static const useBackend = bool.fromEnvironment(
    'ATLART_USE_BACKEND',
    defaultValue: false,
  );

  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  static const _timeout = Duration(seconds: 15);

  static Future<AuthResult> login(
    String identifiant,
    String motDePasse,
  ) async {
    final json = await _send('POST', '/auth/login', body: {
      'identifiant': identifiant,
      'mot_de_passe': motDePasse,
      'device_name': 'atlart-mobile',
    });
    return _result(json);
  }

  static Future<AuthResult> register({
    required String nomEmprunt,
    required String email,
    required String motDePasse,
    required String paysCode,
    String? localisation,
    required String roleSouhaite,
  }) async {
    final json = await _send('POST', '/auth/register', body: {
      'nom_emprunt': nomEmprunt,
      'email': email,
      'mot_de_passe': motDePasse,
      'pays_code': paysCode,
      'localisation':
          localisation == null || localisation.isEmpty ? null : localisation,
      'role_souhaite': roleSouhaite,
      'device_name': 'atlart-mobile',
    });
    return _result(json);
  }

  static Future<AtlartUser> me(String token) async {
    final json = await _send('GET', '/auth/me', token: token);
    final user = json['utilisateur'];
    if (user is! Map<String, dynamic>) {
      throw const AuthException(
        AuthErrorKind.server,
        'Réponse invalide du serveur.',
      );
    }
    return _parseUser(user);
  }

  static Future<void> logout(String token) async {
    await _send('POST', '/auth/logout', token: token);
  }

  static AuthResult _result(Map<String, dynamic> json) {
    final token = json['token'];
    final user = json['utilisateur'];
    if (token is! String ||
        token.isEmpty ||
        user is! Map<String, dynamic>) {
      throw const AuthException(
        AuthErrorKind.server,
        'Réponse invalide du serveur.',
      );
    }
    return AuthResult(token: token, user: _parseUser(user));
  }

  static AtlartUser _parseUser(Map<String, dynamic> json) {
    try {
      return AtlartUser.fromJson(json);
    } on FormatException {
      throw const AuthException(
        AuthErrorKind.server,
        'Réponse utilisateur invalide du serveur.',
      );
    }
  }

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.tryParse(
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path',
    );
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const AuthException(
        AuthErrorKind.server,
        'L’adresse de l’API est invalide.',
      );
    }

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    late final http.Response response;
    try {
      response = method == 'GET'
          ? await http.get(uri, headers: headers).timeout(_timeout)
          : await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
    } on TimeoutException {
      throw const AuthException(
        AuthErrorKind.network,
        'Le serveur met trop de temps à répondre. Réessayez.',
      );
    } on SocketException {
      throw const AuthException(
        AuthErrorKind.network,
        'Connexion impossible. Vérifiez votre réseau et l’adresse de l’API.',
      );
    } on IOException {
      throw const AuthException(
        AuthErrorKind.network,
        'Connexion sécurisée impossible avec le serveur.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthErrorKind.network,
        'Connexion impossible. Vérifiez votre réseau.',
      );
    }

    Map<String, dynamic>? json;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw const AuthException(
            AuthErrorKind.server,
            'Réponse invalide du serveur.',
          );
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (json == null) {
        if (method == 'POST' && path == '/auth/logout') return {};
        throw const AuthException(
          AuthErrorKind.server,
          'Réponse invalide du serveur.',
        );
      }
      return json;
    }

    final message = json?['message'] is String ? json!['message'] as String : '';
    switch (response.statusCode) {
      case 401:
        throw token == null
            ? const AuthException(
                AuthErrorKind.invalidCredentials,
                'E-mail/nom d’emprunt ou mot de passe incorrect.',
              )
            : const AuthException(
                AuthErrorKind.unauthorized,
                'Votre session a expiré. Reconnectez-vous.',
              );
      case 403:
        throw AuthException(
          AuthErrorKind.suspended,
          message.isNotEmpty ? message : 'Ce compte est suspendu.',
        );
      case 422:
        final errors = _fieldErrors(json?['errors']);
        throw AuthException(
          AuthErrorKind.validation,
          (errors.values.isNotEmpty ? errors.values.first : null) ??
              (message.isNotEmpty ? message : 'Vérifiez les champs saisis.'),
          fieldErrors: errors,
        );
      default:
        debugPrint('Atlart API returned HTTP ${response.statusCode} for $path.');
        throw AuthException(
          AuthErrorKind.server,
          message.isNotEmpty
              ? message
              : 'Une erreur serveur est survenue. Réessayez plus tard.',
        );
    }
  }

  static Map<String, String> _fieldErrors(Object? raw) {
    if (raw is! Map) return const {};
    final errors = <String, String>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty && value.first is String) {
        errors['${entry.key}'] = value.first as String;
      } else if (value is String) {
        errors['${entry.key}'] = value;
      }
    }
    return errors;
  }
}
