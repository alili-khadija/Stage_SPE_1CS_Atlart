import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

/// Création et annulation des réservations d’achat direct Laravel.
class ReservationApi {
  ReservationApi._();

  static String get _base => AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '');

  static Future<Map<String, dynamic>> create({
    required String token,
    required String oeuvreId,
    required int quantity,
    required String fulfillment,
    required String phone,
    required String address,
    required String city,
    required String note,
  }) async {
    final uri = Uri.parse(
      '$_base/oeuvres/${Uri.encodeComponent(oeuvreId)}/reservations',
    );
    final response = await _request(() => http.post(
          uri,
          headers: _headers(token, json: true),
          body: jsonEncode({
            'quantite': quantity,
            'mode_retrait': fulfillment,
            'telephone_contact': phone,
            if (fulfillment == 'LIVRAISON') ...{
              'adresse_livraison': address,
              'ville_livraison': city,
            },
            if (note.trim().isNotEmpty) 'note_acheteur': note.trim(),
          }),
        ));
    return _object(response);
  }

  static Future<Map<String, dynamic>> updateStatus({
    required String token,
    required String reservationId,
    required String status,
  }) async {
    final uri = Uri.parse('$_base/reservations/${Uri.encodeComponent(reservationId)}');
    final response = await _request(() => http.patch(
          uri,
          headers: _headers(token, json: true),
          body: jsonEncode({'statut': status}),
        ));
    return _object(response);
  }

  static Future<List<Map<String, dynamic>>> listForArtisan({
    required String token,
  }) async {
    final response = await _request(() => http.get(
          Uri.parse('$_base/mes-commandes'),
          headers: _headers(token),
        ));
    final decoded = _object(response);
    final rows = decoded['data'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  static Future<Map<String, dynamic>> decide({
    required String token,
    required String reservationId,
    required bool accept,
  }) async {
    final uri = Uri.parse(
      '$_base/reservations/${Uri.encodeComponent(reservationId)}/decision',
    );
    final response = await _request(() => http.patch(
          uri,
          headers: _headers(token, json: true),
          body: jsonEncode({'decision': accept ? 'ACCEPTER' : 'REFUSER'}),
        ));
    return _object(response);
  }

  static Map<String, String> _headers(String token, {bool json = false}) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        if (json) 'Content-Type': 'application/json',
      };

  static Future<http.Response> _request(
    Future<http.Response> Function() call,
  ) async {
    try {
      return await call().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ReservationApiException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw const ReservationApiException('Serveur inaccessible. Vérifiez l’API et le réseau.');
    } on IOException {
      throw const ReservationApiException('Connexion au serveur impossible.');
    } on http.ClientException {
      throw const ReservationApiException('Connexion au serveur impossible.');
    }
  }

  static Map<String, dynamic> _object(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ReservationApiException('Réponse invalide du serveur.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['message'] is String
          ? decoded['message'] as String
          : 'Réservation impossible (HTTP ${response.statusCode}).';
      throw ReservationApiException(message);
    }
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const ReservationApiException('Réponse invalide du serveur.');
  }
}

class ReservationApiException implements Exception {
  const ReservationApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
