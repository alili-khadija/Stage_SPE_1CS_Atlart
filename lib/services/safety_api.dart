import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

/// Signalements et blocages rattachés à la session AtlArt.
class SafetyApi {
  SafetyApi._();

  static String get _base => AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '');
  static Map<String, String> _headers(String token, {bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<void> reportConversation({
    required String token,
    required String conversationId,
    required String reason,
  }) async {
    final response = await _request(() => http.post(
          Uri.parse('$_base/signalements'),
          headers: _headers(token, json: true),
          body: jsonEncode({
            'entite_type': 'CONVERSATION',
            'entite_id': conversationId,
            'raison': reason,
          }),
        ));
    _expectSuccess(response);
  }

  static Future<void> blockUser({
    required String token,
    required String userId,
  }) async {
    final response = await _request(() => http.post(
          Uri.parse('$_base/utilisateurs-bloques'),
          headers: _headers(token, json: true),
          body: jsonEncode({'bloque_id': userId}),
        ));
    _expectSuccess(response);
  }

  static Future<List<Map<String, dynamic>>> blockedUsers(String token) async {
    final response = await _request(() => http.get(
          Uri.parse('$_base/utilisateurs-bloques'),
          headers: _headers(token),
        ));
    _expectSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const SafetyApiException('Réponse invalide du serveur.');
    }
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<void> unblockUser({
    required String token,
    required String userId,
  }) async {
    final response = await _request(() => http.delete(
          Uri.parse('$_base/utilisateurs-bloques/${Uri.encodeComponent(userId)}'),
          headers: _headers(token),
        ));
    _expectSuccess(response);
  }

  static Future<http.Response> _request(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const SafetyApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const SafetyApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on IOException {
      throw const SafetyApiException('Connexion au serveur impossible.');
    } on http.ClientException {
      throw const SafetyApiException('Connexion au serveur impossible.');
    }
  }

  static void _expectSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message = 'Action impossible (HTTP ${response.statusCode}).';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      }
    } on FormatException {
      // Keep the HTTP fallback for a non-JSON error page.
    }
    throw SafetyApiException(message);
  }
}

class SafetyApiException implements Exception {
  const SafetyApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
