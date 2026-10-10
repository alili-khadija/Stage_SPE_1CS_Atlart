import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

/// Client HTTP pour les routes Laravel de conversation.
class ConversationApi {
  ConversationApi._();

  static String get _base => AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '');
  static Uri _uri(String path) => Uri.parse('$_base$path');
  static Map<String, String> _headers(String token, {bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<List<Map<String, dynamic>>> list(String token) async {
    final response = await _request(
      () => http.get(_uri('/conversations'), headers: _headers(token)),
    );
    final decoded = _decode(response);
    final rows = decoded is List ? decoded : (decoded as Map)['data'];
    if (rows is! List) throw const ConversationApiException('Réponse invalide du serveur.');
    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<Map<String, dynamic>> create(
    String token,
    String recipientId, {
    required String contextType,
    required String contextId,
    required String contextTitle,
    String? contextSubtitle,
  }) async {
    final response = await _request(
      () => http.post(
        _uri('/conversations'),
        headers: _headers(token, json: true),
        body: jsonEncode({
          'destinataire_id': recipientId,
          'contexte_type': contextType,
          'contexte_id': contextId,
          'contexte_titre': contextTitle,
          'contexte_sous_titre': contextSubtitle,
        }),
      ),
    );
    return _object(_decode(response));
  }

  static Future<List<Map<String, dynamic>>> messages(String token, String conversationId) async {
    final response = await _request(
      () => http.get(
        _uri('/conversations/${Uri.encodeComponent(conversationId)}/messages'),
        headers: _headers(token),
      ),
    );
    final decoded = _decode(response);
    final rows = decoded is Map ? decoded['data'] : decoded;
    if (rows is! List) throw const ConversationApiException('Réponse invalide du serveur.');
    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<Map<String, dynamic>> send(String token, String conversationId, String text) async {
    final response = await _request(
      () => http.post(
        _uri('/conversations/${Uri.encodeComponent(conversationId)}/messages'),
        headers: _headers(token, json: true),
        body: jsonEncode({'contenu': text}),
      ),
    );
    return _object(_decode(response));
  }

  static Future<void> markRead(String token, String conversationId) async {
    final response = await _request(
      () => http.patch(
        _uri('/conversations/${Uri.encodeComponent(conversationId)}/lu'),
        headers: _headers(token),
      ),
    );
    _decode(response);
  }

  static Future<Map<String, dynamic>> resendFirstMessage(
    String token,
    String conversationId,
    String text,
  ) async {
    final response = await _request(
      () => http.patch(
        _uri(
          '/conversations/${Uri.encodeComponent(conversationId)}/premier-message',
        ),
        headers: _headers(token, json: true),
        body: jsonEncode({'contenu': text}),
      ),
    );
    return _object(_decode(response));
  }

  static Future<http.Response> _request(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ConversationApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const ConversationApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on IOException {
      throw const ConversationApiException('Connexion au serveur impossible.');
    } on http.ClientException {
      throw const ConversationApiException('Connexion au serveur impossible.');
    }
  }

  static dynamic _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } on FormatException {
      throw const ConversationApiException('Réponse invalide du serveur.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['message'] is String
          ? decoded['message'] as String
          : 'Erreur de messagerie (HTTP ${response.statusCode}).';
      throw ConversationApiException(message);
    }
    return decoded;
  }

  static Map<String, dynamic> _object(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ConversationApiException('Réponse invalide du serveur.');
  }
}

class ConversationApiException implements Exception {
  const ConversationApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
