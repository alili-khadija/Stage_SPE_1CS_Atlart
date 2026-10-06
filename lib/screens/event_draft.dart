import 'package:flutter/material.dart';

import '../models/event_detail.dart';
import 'event_model_screen.dart';

enum EventType { exposition, atelier, residence }

extension EventTypeLabels on EventType {
  String get label => switch (this) {
    EventType.exposition => 'Exposition',
    EventType.atelier => 'Atelier',
    EventType.residence => 'Résidence',
  };

  String get scheduleTitle => switch (this) {
    EventType.exposition => 'Temps forts',
    EventType.atelier => 'Séances',
    EventType.residence => 'Programme',
  };

  String get scheduleCodePrefix => this == EventType.atelier ? 'S' : 'J';

  String get addScheduleLabel =>
      this == EventType.residence ? '+ Ajouter un jour' : '+ Ajouter';

  String get capacityLabel => this == EventType.exposition
      ? 'Capacité de la galerie'
      : 'Places disponibles';

  bool get usesSingleDateAndTime => this == EventType.atelier;
}

enum EventMode { presentiel, virtuel }

extension EventModeLabels on EventMode {
  String get label => this == EventMode.presentiel ? 'Présentiel' : 'Virtuel';
}

class ScheduleItem {
  ScheduleItem({required this.code, required this.title, this.subtitle = ''});

  String code;
  String title;
  String subtitle;
}

enum RegistrationStatus { pending, validated, present }

class EventParticipant {
  EventParticipant({
    required this.name,
    required this.requestedOn,
    required this.avatarColor,
    this.status = RegistrationStatus.pending,
    this.checkedInAt,
    this.checkedInManually = false,
  });

  final String name;
  final String requestedOn;
  final Color avatarColor;
  RegistrationStatus status;
  String? checkedInAt;
  bool checkedInManually;
}

class EventDraft {
  EventDraft({
    String? id,
    this.type = EventType.exposition,
    this.title = '',
    this.startDate,
    this.endDate,
    this.timeRange = '',
    this.mode = EventMode.presentiel,
    this.location = '',
    this.capacity = 20,
    this.description = '',
    List<ScheduleItem>? schedule,
    this.imagePath,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       schedule = schedule ?? [];

  final String id;
  EventType type;
  String title;
  DateTime? startDate;
  DateTime? endDate;
  String timeRange;
  EventMode mode;
  String location;
  int capacity;
  String description;
  List<ScheduleItem> schedule;
  String? imagePath;

  String get nextScheduleCode =>
      '${type.scheduleCodePrefix}-${(schedule.length + 1).toString().padLeft(2, '0')}';

  EventItem toEventItem({String organizerName = 'Votre organisation'}) {
    final date = startDate == null ? '' : _formatDate(startDate!);
    final dateLabel = type.usesSingleDateAndTime
        ? '$date${timeRange.isEmpty ? '' : ' · $timeRange'}'
        : '$date${endDate == null ? '' : ' – ${_formatDate(endDate!)}'}';
    final locationLabel =
        '${mode == EventMode.presentiel ? 'Présentiel' : 'En ligne'} · $location';

    return EventItem(
      title: title,
      type: type.label,
      dateLabel: dateLabel,
      locationLabel: locationLabel,
      capacityNote: type == EventType.exposition
          ? 'Capacité de la galerie · $capacity places'
          : 'Places limitées · inscription soumise à validation',
      description: description,
      placesLeft: capacity,
      program: [
        for (final item in schedule)
          ProgramStep(
            day: item.code,
            title: item.title,
            subtitle: item.subtitle,
          ),
      ],
      organizerName: organizerName,
      organizerLocation: location,
      imagePath: imagePath,
    );
  }

  EventDetail toEventDetail({String organizerName = 'Votre organisation'}) =>
      toEventItem(organizerName: organizerName)
          .toEventDetail(id: id, isMine: true);

  static String _formatDate(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
