import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../app_session.dart';
import 'auth_api.dart';

/// Publication des articles artisanaux et de leurs photos.
class OeuvreApi {
  OeuvreApi._();

  static String get _base => AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '');
  static Map<String, String> _headers(String token, {bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<String> publishArtisanArticle({
    required Map<String, dynamic> article,
    required List<String> photoPaths,
  }) async {
    if (!AuthApi.useBackend) return '';
    final token = AtlartSession.instance.token;
    if (token == null) throw const OeuvreApiException('Connectez-vous pour publier un article.');
    if (photoPaths.isEmpty) throw const OeuvreApiException('Ajoutez au moins une photo.');

    final createResponse = await _request(() => http.post(
          Uri.parse('$_base/oeuvres'),
          headers: _headers(token, json: true),
          body: jsonEncode(article),
        ));
    final created = _object(createResponse);
    final id = '${created['id'] ?? ''}';
    if (id.isEmpty) throw const OeuvreApiException('Le serveur n’a pas retourné l’identifiant de l’article.');

    try {
      for (var i = 0; i < photoPaths.length; i++) {
        await _uploadPhoto(token, id, photoPaths[i], i);
      }
      final publishResponse = await _request(() => http.patch(
            Uri.parse('$_base/oeuvres/${Uri.encodeComponent(id)}'),
            headers: _headers(token, json: true),
            body: jsonEncode({'brouillon': false, 'etape_courante': 4}),
          ));
      _object(publishResponse);
      return id;
    } catch (error) {
      try {
        await _request(() => http.delete(
              Uri.parse('$_base/oeuvres/${Uri.encodeComponent(id)}'),
              headers: _headers(token),
            ));
      } catch (cleanupError) {
        debugPrint('Unable to clean up failed article draft: $cleanupError');
      }
      rethrow;
    }
  }

  static Future<void> _uploadPhoto(
    String token,
    String oeuvreId,
    String path,
    int order,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_base/images'))
      ..headers.addAll(_headers(token))
      ..fields['entite_type'] = 'OEUVRE'
      ..fields['entite_id'] = oeuvreId
      ..fields['principale'] = order == 0 ? '1' : '0'
      ..fields['ordre'] = '$order'
      ..files.add(await http.MultipartFile.fromPath('fichier', path));

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      _object(response);
    } on TimeoutException {
      throw const OeuvreApiException('Le téléversement d’une photo a expiré.');
    } on SocketException {
      throw const OeuvreApiException('Connexion impossible pendant le téléversement.');
    } on IOException {
      throw const OeuvreApiException('Impossible de lire une photo sélectionnée.');
    }
  }

  static Future<http.Response> _request(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const OeuvreApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const OeuvreApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on IOException {
      throw const OeuvreApiException('Connexion au serveur impossible.');
    } on http.ClientException {
      throw const OeuvreApiException('Connexion au serveur impossible.');
    }
  }

  static Map<String, dynamic> _object(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const OeuvreApiException('Réponse invalide du serveur.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['message'] is String
          ? decoded['message'] as String
          : 'Publication impossible (HTTP ${response.statusCode}).';
      throw OeuvreApiException(message);
    }
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const OeuvreApiException('Réponse invalide du serveur.');
  }
}

class OeuvreApiException implements Exception {
  const OeuvreApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
