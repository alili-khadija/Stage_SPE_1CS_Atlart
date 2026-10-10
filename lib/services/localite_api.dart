import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class Localite {
  const Localite({
    required this.id,
    required this.nom,
    required this.paysCode,
    this.nomAr,
    this.region,
  });

  final int id;
  final String nom;
  final String paysCode;
  final String? nomAr;
  final String? region;

  factory Localite.fromJson(Map<String, dynamic> j) => Localite(
        id: int.tryParse('${j['id']}') ?? 0,
        nom: '${j['nom']}',
        paysCode: '${j['pays_code']}',
        nomAr: j['nom_ar'] as String?,
        region: j['region'] as String?,
      );
}

class LocaliteApi {
  LocaliteApi._();

  /// Suggestions de communes pour un pays (DZ, TN, MA) et un debut de nom.
  static Future<List<Localite>> rechercher(String pays, String q) async {
    final base = AuthApi.baseUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/localites').replace(
      queryParameters: {'pays': pays, 'q': q, 'limit': '8'},
    );
    try {
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is! List) return const [];
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) Localite.fromJson(e),
      ];
    } on Exception {
      return const [];
    }
  }
}