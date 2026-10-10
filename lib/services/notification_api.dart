import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class NotificationApi {
  NotificationApi._();

  static Uri get _endpoint => Uri.parse(
        '${AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '')}/notifications',
      );

  static Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<List<Map<String, dynamic>>> list(String token) async {
    late final http.Response response;
    try {
      response = await http
          .get(_endpoint, headers: _headers(token))
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const NotificationApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const NotificationApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on IOException {
      throw const NotificationApiException('Connexion au serveur impossible.');
    } on http.ClientException {
      throw const NotificationApiException('Connexion au serveur impossible.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationApiException('Notifications indisponibles (HTTP ${response.statusCode}).');
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final rows = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      if (rows is! List) return const [];
      return [
        for (final row in rows)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
    } on FormatException {
      throw const NotificationApiException('La réponse des notifications est invalide.');
    }
  }

  static Future<void> markAsRead(String token, String id) async {
    late final http.Response response;
    try {
      response = await http
          .patch(
            _endpoint.replace(
              path: '${_endpoint.path}/${Uri.encodeComponent(id)}/lu',
            ),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const NotificationApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const NotificationApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on IOException {
      throw const NotificationApiException('Connexion au serveur impossible.');
    } on http.ClientException {
      throw const NotificationApiException('Connexion au serveur impossible.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationApiException('Impossible de marquer la notification comme lue (HTTP ${response.statusCode}).');
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final isRead = body is Map &&
          (body['lu'] == true || body['lu'] == 1 || body['lu'] == '1');
      if (!isRead) {
        throw const NotificationApiException(
          'Le serveur n’a pas confirmé la lecture de la notification.',
        );
      }
    } on FormatException {
      throw const NotificationApiException(
        'La confirmation de lecture renvoyée par le serveur est invalide.',
      );
    }
  }
}

class NotificationApiException implements Exception {
  const NotificationApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
