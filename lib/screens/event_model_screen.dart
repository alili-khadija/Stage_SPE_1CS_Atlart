import '../models/event_detail.dart';

class ProgramStep {
  const ProgramStep({
    required this.day,
    required this.title,
    required this.subtitle,
  });

  final String day;
  final String title;
  final String subtitle;
}

class EventItem {
  const EventItem({
    required this.title,
    required this.type,
    required this.dateLabel,
    required this.locationLabel,
    required this.capacityNote,
    required this.description,
    required this.placesLeft,
    required this.program,
    required this.organizerName,
    required this.organizerLocation,
    this.imageUrl,
    this.imageAsset,
    this.imagePath,
  });

  final String title;
  final String type;
  final String dateLabel;
  final String locationLabel;
  final String capacityNote;
  final String description;
  final int placesLeft;
  final List<ProgramStep> program;
  final String organizerName;
  final String organizerLocation;
  final String? imageUrl;
  final String? imageAsset;
  final String? imagePath;

  static const sample = EventItem(
    title: 'Résidence artistique · Médina de Tunis',
    type: 'Résidence',
    dateLabel: '15 – 17 mars 2027',
    locationLabel: 'Présentiel · Tunis, Tunisie',
    capacityNote: 'Places limitées · inscription soumise à la validation',
    description:
        'Une semaine de résidence dédiée aux artisans céramistes, avec '
        'ateliers partagés, rencontres avec des artistes locaux et '
        'exposition collective en fin de programme.',
    placesLeft: 6,
    program: [
      ProgramStep(
        day: 'J-15',
        title: 'Accueil',
        subtitle: "Prise de contact, visite de l'atelier",
      ),
      ProgramStep(
        day: 'J-16',
        title: 'Atelier de création',
        subtitle: 'Séances par artiste, matériel fourni',
      ),
      ProgramStep(
        day: 'J-17',
        title: 'Exposition collective',
        subtitle: 'Restitution ouverte au public',
      ),
    ],
    organizerName: 'Atelier Dorra',
    organizerLocation: 'Tlemcen, Algérie',
  );
}

extension EventItemDetails on EventItem {
  EventDetail toEventDetail({String? id, bool isMine = false}) {
    final locationParts = locationLabel.split(' · ');
    final mode = locationParts.length > 1 ? locationParts.first : '';
    final location = locationParts.length > 1
        ? locationParts.skip(1).join(' · ')
        : locationLabel;

    return EventDetail(
      id: id ?? EventDetail.idFromTitle(title),
      title: title,
      category: type,
      dateLabel: dateLabel,
      modeLabel: mode,
      location: location,
      description: description,
      placesLeft: placesLeft,
      requiresValidation: capacityNote.toLowerCase().contains('validation'),
      program: [
        for (final step in program)
          EventProgramItem(
            dayLabel: step.day,
            title: step.title,
            subtitle: step.subtitle,
          ),
      ],
      organizer: EventOrganizer(
        name: organizerName,
        location: organizerLocation,
      ),
      imageAsset: imageAsset,
      imagePath: imagePath,
      imageUrl: imageUrl,
      isMine: isMine,
    );
  }
}
