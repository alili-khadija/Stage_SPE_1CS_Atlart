import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../app_session.dart';
import 'auth_api.dart';

class EventApi {
  EventApi._();

  static String get _base => AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '');

  static Future<String> create({
    required Map<String, dynamic> event,
    String? coverPath,
  }) async {
    if (!AuthApi.useBackend) return '';
    final token = AtlartSession.instance.token;
    if (token == null) {
      throw const EventApiException('Connectez-vous pour soumettre un événement.');
    }

    final request = http.MultipartRequest('POST', Uri.parse('$_base/evenements'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';

    for (final entry in event.entries) {
      if (entry.key == 'programme') continue;
      final value = entry.value;
      if (value != null) request.fields[entry.key] = '$value';
    }
    final programme = event['programme'];
    if (programme is List) request.fields['programme'] = jsonEncode(programme);
    if (coverPath != null) {
      request.files.add(await http.MultipartFile.fromPath('fichier', coverPath));
    }

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 10));
      final decoded = _decode(response);
      final id = '${decoded['id'] ?? ''}';
      if (id.isEmpty) {
        throw const EventApiException('Le serveur n’a pas retourné l’identifiant de l’événement.');
      }
      return id;
    } on TimeoutException {
      throw const EventApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const EventApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on IOException {
      throw const EventApiException('Impossible de lire la couverture sélectionnée.');
    } on http.ClientException {
      throw const EventApiException('Connexion au serveur impossible.');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String eventId,
    required Map<String, dynamic> details,
  }) async {
    if (!AuthApi.useBackend) return {};
    final token = AtlartSession.instance.token;
    if (token == null) {
      throw const EventApiException('Connectez-vous pour vous inscrire.');
    }
    try {
      final response = await http
          .post(
            Uri.parse('$_base/evenements/$eventId/inscription'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: {
              'nom_complet': '${details['nom_complet'] ?? ''}',
              'email': '${details['email'] ?? ''}',
              'telephone': '${details['telephone'] ?? ''}',
              'ville': '${details['ville'] ?? ''}',
              'nombre_participants': '${details['nombre_participants'] ?? 1}',
              'message': '${details['message'] ?? ''}',
            },
          )
          .timeout(const Duration(seconds: 20));
      return _decode(response);
    } on TimeoutException {
      throw const EventApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const EventApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on http.ClientException {
      throw const EventApiException('Connexion au serveur impossible.');
    }
  }

  static Future<List<Map<String, dynamic>>> participants(String eventId) async {
    if (!AuthApi.useBackend) return const [];
    final token = AtlartSession.instance.token;
    if (token == null) {
      throw const EventApiException('Connectez-vous pour consulter les inscriptions.');
    }
    try {
      final response = await http
          .get(
            Uri.parse('$_base/evenements/$eventId/inscriptions'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const EventApiException('Réponse invalide du serveur.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map && decoded['message'] is String
            ? decoded['message'] as String
            : 'Chargement des inscriptions impossible (HTTP ${response.statusCode}).';
        throw EventApiException(message);
      }
      if (decoded is! List) {
        throw const EventApiException('Réponse invalide du serveur.');
      }
      return decoded
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } on TimeoutException {
      throw const EventApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const EventApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on http.ClientException {
      throw const EventApiException('Connexion au serveur impossible.');
    }
  }

  static Future<void> decideRegistration({
    required String registrationId,
    required bool accept,
  }) async {
    if (!AuthApi.useBackend) return;
    final token = AtlartSession.instance.token;
    if (token == null) {
      throw const EventApiException('Connectez-vous pour traiter cette demande.');
    }
    try {
      final response = await http
          .patch(
            Uri.parse('$_base/inscriptions/$registrationId'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: {'statut': accept ? 'VALIDE' : 'REJETE'},
          )
          .timeout(const Duration(seconds: 20));
      _decode(response);
    } on TimeoutException {
      throw const EventApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const EventApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on http.ClientException {
      throw const EventApiException('Connexion au serveur impossible.');
    }
  }

  static Future<Map<String, dynamic>> checkIn({
    required String eventId,
    required String registrationId,
    required bool manual,
  }) async {
    if (!AuthApi.useBackend) return {};
    final token = AtlartSession.instance.token;
    if (token == null) {
      throw const EventApiException('Connectez-vous pour pointer un participant.');
    }
    try {
      final response = await http
          .patch(
            Uri.parse(
              '$_base/evenements/$eventId/inscriptions/$registrationId/pointage',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: {'methode': manual ? 'MANUEL' : 'QR_CODE'},
          )
          .timeout(const Duration(seconds: 20));
      return _decode(response);
    } on TimeoutException {
      throw const EventApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const EventApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on http.ClientException {
      throw const EventApiException('Connexion au serveur impossible.');
    }
  }

  static Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const EventApiException('Réponse invalide du serveur.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['message'] is String
          ? decoded['message'] as String
          : 'Soumission impossible (HTTP ${response.statusCode}).';
      throw EventApiException(message);
    }
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const EventApiException('Réponse invalide du serveur.');
  }
}

class EventApiException implements Exception {
  const EventApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
