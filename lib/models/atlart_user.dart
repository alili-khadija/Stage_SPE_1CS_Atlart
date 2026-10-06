class AtlartUser {
  const AtlartUser({
    required this.id,
    required this.email,
    required this.nomEmprunt,
    required this.role,
    this.paysCode,
    this.ville,
  });

  final String id;
  final String email;
  final String nomEmprunt;
  final String role;
  final String? paysCode;
  final String? ville;

  bool get isVisiteur => role == 'visiteur';
  bool get isArtiste => role == 'artiste';
  bool get isArtisan => role == 'artisan';
  bool get isStaff => role == 'moderateur' || role == 'admin';

  factory AtlartUser.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('Missing or invalid user field: $key');
      }
      return value;
    }

    String? optionalString(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) {
        throw FormatException('Invalid user field: $key');
      }
      return value;
    }

    return AtlartUser(
      id: requiredString('id'),
      email: requiredString('email'),
      nomEmprunt: json['nom_emprunt'] is String
          ? json['nom_emprunt'] as String
          : '',
      role: requiredString('role'),
      paysCode: optionalString('pays_code'),
      ville: optionalString('ville'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nom_emprunt': nomEmprunt,
        'role': role,
        'pays_code': paysCode,
        'ville': ville,
      };
}
