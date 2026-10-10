import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../app_session.dart';
import 'auth_api.dart';

/// Client for Laravel's public GET /recherche endpoint.
/// The API currently returns French group names and raw Eloquent resources.
class SearchApi {
  SearchApi._();

  static Future<SearchCatalog> search({
    String query = '',
    String? country,
    List<String> categories = const [],
    List<String> tags = const [],
  }) async {
    final base = AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '');
    final countryCode = _countryCode(country);
    final params = <String, String>{
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (countryCode != null) 'pays': countryCode,
      'categorie': _categoryCode(categories),
    };
    var typeIndex = 0;
    var themeIndex = 0;
    for (final tag in tags) {
      final typeCode = _typeCode(tag);
      final themeCode = _themeCode(tag);
      if (typeCode != null) params['types[${typeIndex++}]'] = typeCode;
      if (themeCode != null) params['themes[${themeIndex++}]'] = themeCode;
    }
    final uri = Uri.parse('$base/recherche').replace(queryParameters: params);

    late final http.Response response;
    try {
      final token = AtlartSession.instance.token;
      response = await http.get(uri, headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const SearchApiException('Le serveur de recherche met trop de temps à répondre.');
    } on SocketException {
      throw const SearchApiException('Serveur de recherche inaccessible. Vérifiez l’API et le réseau.');
    } on IOException {
      throw const SearchApiException('Connexion au serveur de recherche impossible.');
    } on http.ClientException {
      throw const SearchApiException('Connexion au serveur de recherche impossible.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SearchApiException('Recherche indisponible (HTTP ${response.statusCode}).');
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final root = decoded['data'] ?? decoded['results'] ?? decoded;
        if (root is Map<String, dynamic>) return SearchCatalog.fromJson(root);
        if (root is List) return SearchCatalog.fromRows(root);
      }
      if (decoded is List) return SearchCatalog.fromRows(decoded);
    } on FormatException {
      // Normalized below as a clear API contract error.
    }
    throw const SearchApiException('La réponse de recherche du serveur est invalide.');
  }

  static String? _countryCode(String? country) => switch (country?.toLowerCase()) {
        'algérie' || 'algerie' || 'dz' => 'DZ',
        'maroc' || 'ma' => 'MA',
        'tunisie' || 'tn' => 'TN',
        'libye' || 'ly' => 'LY',
        'mauritanie' || 'mr' => 'MR',
        _ => null,
      };

  static String _categoryCode(List<String> categories) {
    if (categories.isEmpty) return 'tout';
    final value = categories.first.toLowerCase();
    if (value.contains('artisanat')) return 'artisanat';
    if (value.contains('artiste')) return 'artistes';
    if (value.contains('événement') || value.contains('evenement')) {
      return 'evenements';
    }
    if (value.contains('œuvre') || value.contains('oeuvre')) return 'oeuvres';
    return 'tout';
  }

  static String? _typeCode(String tag) => switch (tag.toLowerCase()) {
        'peinture' => 'PEINTURE',
        'sculpture' => 'SCULPTURE',
        'poterie' => 'POTERIE',
        'tissage' => 'TISSAGE',
        'cuivre' => 'CUIVRE',
        'bijoux' => 'BIJOUX',
        _ => null,
      };

  static String? _themeCode(String tag) => switch (tag.toLowerCase()) {
        'folklorique' => 'FOLKLORIQUE',
        'patrimoine' => 'PATRIMOINE',
        'abstrait' => 'ABSTRAIT',
        'calligraphie' => 'CALLIGRAPHIE',
        _ => null,
      };
}

class SearchApiException implements Exception {
  const SearchApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Client for Laravel's authenticated /recherches-recentes endpoints.
class RecentSearchApi {
  RecentSearchApi._();

  static Uri get _endpoint => Uri.parse(
        '${AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '')}/recherches-recentes',
      );

  static Map<String, String> _headers(String token, {bool json = false}) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        if (json) 'Content-Type': 'application/json',
      };

  static Future<List<String>> list(String token) async {
    final response = await http
        .get(_endpoint, headers: _headers(token))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SearchApiException('Historique indisponible (HTTP ${response.statusCode}).');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final rows = decoded is Map<String, dynamic>
        ? (decoded['data'] ?? decoded['recherches'] ?? decoded['historique'])
        : decoded;
    if (rows is! List) return const [];
    return rows
        .map((row) => row is Map ? '${row['terme'] ?? row['query'] ?? ''}' : '$row')
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
  }

  static Future<void> save(String token, String term) async {
    final response = await http
        .post(_endpoint,
            headers: _headers(token, json: true),
            body: jsonEncode({'terme': term.trim()}))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SearchApiException('Enregistrement de la recherche impossible (HTTP ${response.statusCode}).');
    }
  }

  static Future<void> remove(String token, String term) async {
    final uri = _endpoint.replace(
      path: '${_endpoint.path}/${Uri.encodeComponent(term)}',
    );
    final response = await http
        .delete(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SearchApiException('Suppression de la recherche impossible (HTTP ${response.statusCode}).');
    }
  }

  static Future<void> clear(String token) async {
    final response = await http
        .delete(_endpoint, headers: _headers(token))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SearchApiException('Effacement de l’historique impossible (HTTP ${response.statusCode}).');
    }
  }
}

class SearchCatalog {
  const SearchCatalog({
    this.artworks = const [],
    this.artisanat = const [],
    this.events = const [],
    this.artists = const [],
  });

  final List<Map<String, dynamic>> artworks;
  final List<Map<String, dynamic>> artisanat;
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> artists;

  factory SearchCatalog.fromJson(Map<String, dynamic> json) => SearchCatalog(
        artworks: _rows(json['artworks'] ?? json['oeuvres']),
        artisanat: _rows(json['artisanat'] ?? json['crafts'] ?? json['products']),
        events: _rows(json['events'] ?? json['evenements']),
        artists: _rows(json['artists'] ?? json['artistes']),
      );

  factory SearchCatalog.fromRows(List<dynamic> rows) {
    final groups = <String, List<Map<String, dynamic>>>{
      'artworks': [], 'artisanat': [], 'events': [], 'artists': [],
    };
    for (final value in rows) {
      if (value is! Map) continue;
      final row = Map<String, dynamic>.from(value);
      final type = '${row['type'] ?? row['category'] ?? ''}'.toLowerCase();
      final key = type.contains('event') || type.contains('événement') || type.contains('evenement')
          ? 'events'
          : type.contains('artist') || type.contains('artiste')
              ? 'artists'
              : type.contains('œuvre') || type.contains('oeuvre') || type.contains('work')
                  ? 'artworks'
                  : 'artisanat';
      groups[key]!.add(row);
    }
    return SearchCatalog(
      artworks: groups['artworks']!, artisanat: groups['artisanat']!,
      events: groups['events']!, artists: groups['artists']!,
    );
  }

  static List<Map<String, dynamic>> _rows(Object? value) {
    if (value is! List) return const [];
    return [for (final row in value) if (row is Map) Map<String, dynamic>.from(row)];
  }
}
