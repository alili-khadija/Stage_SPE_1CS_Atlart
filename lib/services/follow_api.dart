import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class FollowApi {
  FollowApi._();

  static Uri _endpoint(String userId) => Uri.parse(
        '${AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '')}/utilisateurs/${Uri.encodeComponent(userId)}/suivre',
      );

  static Future<bool> setFollowing({
    required String token,
    required String userId,
    required bool follow,
  }) async {
    try {
      final request = follow
          ? http.post(_endpoint(userId), headers: _headers(token))
          : http.delete(_endpoint(userId), headers: _headers(token));
      final response = await request.timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FollowApiException(
          'Mise à jour du suivi impossible (HTTP ${response.statusCode}).',
        );
      }
      return follow;
    } on TimeoutException {
      throw const FollowApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const FollowApiException(
        'Serveur inaccessible. Vérifiez l’API et le réseau.',
      );
    } on IOException {
      throw const FollowApiException('Connexion au serveur impossible.');
    } on http.ClientException {
      throw const FollowApiException('Connexion au serveur impossible.');
    }
  }

  static Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
}

class FollowApiException implements Exception {
  const FollowApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
