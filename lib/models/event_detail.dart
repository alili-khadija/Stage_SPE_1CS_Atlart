class EventProgramItem {
  const EventProgramItem({
    required this.dayLabel,
    required this.title,
    this.subtitle = '',
  });

  final String dayLabel;
  final String title;
  final String subtitle;
}

class EventOrganizer {
  const EventOrganizer({required this.name, required this.location});

  final String name;
  final String location;
}

class EventDetail {
  const EventDetail({
    required this.id,
    required this.title,
    required this.category,
    required this.dateLabel,
    required this.location,
    this.modeLabel = 'Présentiel',
    this.description = '',
    this.placesLeft,
    this.requiresValidation = true,
    this.program = const [],
    this.organizer,
    this.imageAsset,
    this.imagePath,
    this.imageUrl,
    this.isMine = false,
  });

  final String id;
  final String title;
  final String category;
  final String dateLabel;
  final String modeLabel;
  final String location;
  final String description;
  final int? placesLeft;
  final bool requiresValidation;
  final List<EventProgramItem> program;
  final EventOrganizer? organizer;
  final String? imageAsset;
  final String? imagePath;
  final String? imageUrl;
  final bool isMine;

  bool get isFull => placesLeft != null && placesLeft! <= 0;

  String get locationLabel =>
      [modeLabel, location].where((s) => s.trim().isNotEmpty).join(' · ');

  String get registrationNote => [
    if (placesLeft != null) 'Places limitées',
    if (requiresValidation) 'Inscription soumise à la validation',
  ].join(' · ');

  static String idFromTitle(String title) {
    var normalized = title.toLowerCase();
    const replacements = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'œ': 'oe',
    };
    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static const demoResidence = EventDetail(
    id: 'residence-medina-tunis',
    title: 'Résidence artistique · Médina de Tunis',
    category: 'Résidence',
    dateLabel: '15 – 17 mars 2027',
    modeLabel: 'Présentiel',
    location: 'Tunis, Tunisie',
    description:
        'Une semaine de résidence dédiée aux artisans céramistes, avec '
        'ateliers partagés, rencontres avec des artistes locaux et '
        'exposition collective en fin de programme.',
    placesLeft: 6,
    requiresValidation: true,
    program: [
      EventProgramItem(
        dayLabel: 'J-15',
        title: 'Accueil',
        subtitle: 'Prise de contact, visite de l’atelier',
      ),
      EventProgramItem(
        dayLabel: 'J-16',
        title: 'Atelier de création',
        subtitle: 'Séances encadrées, matériel fourni',
      ),
      EventProgramItem(
        dayLabel: 'J-17',
        title: 'Exposition collective',
        subtitle: 'Restitution ouverte au public',
      ),
    ],
    organizer: EventOrganizer(
      name: 'Atelier Dorra',
      location: 'Tlemcen, Algérie',
    ),
  );
}
