import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class FavoriteApi {
  FavoriteApi._();

  static Uri get _endpoint => Uri.parse(
        '${AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '')}/favoris',
      );

  static Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  static Future<List<Map<String, dynamic>>> list(String token) async {
    final response = await _send(() => http.get(_endpoint, headers: _headers(token)));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FavoriteApiException('Favoris indisponibles (HTTP ${response.statusCode}).');
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) return const [];
      return [
        for (final row in decoded)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
    } on FormatException {
      throw const FavoriteApiException('La réponse des favoris est invalide.');
    }
  }

  static Future<void> add(String token, String type, String id) async {
    final response = await _send(() => http.post(
          _endpoint,
          headers: _headers(token),
          body: jsonEncode({'entite_type': type, 'entite_id': id}),
        ));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FavoriteApiException('Ajout aux favoris impossible (HTTP ${response.statusCode}).');
    }
  }

  static Future<void> remove(String token, String type, String id) async {
    final response = await _send(() => http.delete(
          _endpoint,
          headers: _headers(token),
          body: jsonEncode({'entite_type': type, 'entite_id': id}),
        ));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FavoriteApiException('Suppression du favori impossible (HTTP ${response.statusCode}).');
    }
  }

  static Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const FavoriteApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const FavoriteApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on IOException {
      throw const FavoriteApiException('Connexion au serveur impossible.');
    } on http.ClientException {
      throw const FavoriteApiException('Connexion au serveur impossible.');
    }
  }
}

class FavoriteApiException implements Exception {
  const FavoriteApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
