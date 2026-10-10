import 'package:flutter/foundation.dart';

import 'event_detail.dart';
import '../services/auth_api.dart';
import '../services/event_api.dart';

enum EventRegistrationStatus { pending, validated, declined }

extension EventRegistrationStatusX on EventRegistrationStatus {
  String get label => switch (this) {
    EventRegistrationStatus.pending => 'En attente',
    EventRegistrationStatus.validated => 'Inscrit(e)',
    EventRegistrationStatus.declined => 'Refusée',
  };
}

class EventRegistrationForm {
  const EventRegistrationForm({
    required this.fullName,
    required this.email,
    required this.phone,
    this.city = '',
    this.participants = 1,
    this.message = '',
  });

  final String fullName;
  final String email;
  final String phone;
  final String city;
  final int participants;
  final String message;
}

class EventRegistration {
  const EventRegistration({
    required this.event,
    required this.requestedAt,
    required this.status,
    this.form,
  });

  final EventDetail event;
  final DateTime requestedAt;
  final EventRegistrationStatus status;
  final EventRegistrationForm? form;

  EventRegistration copyWith({EventRegistrationStatus? status}) =>
      EventRegistration(
        event: event,
        requestedAt: requestedAt,
        status: status ?? this.status,
        form: form,
      );
}

class EventRegistrationStore extends ChangeNotifier {
  EventRegistrationStore._();

  static final EventRegistrationStore instance = EventRegistrationStore._();

  final Map<String, EventRegistration> _items = {};

  List<EventRegistration> get registrations =>
      _items.values.toList().reversed.toList();

  EventRegistration? of(String eventId) => _items[eventId];

  bool isRegistered(String eventId) => _items.containsKey(eventId);

  /// Stores the registration in Laravel when backend mode is enabled.
  Future<EventRegistration> register(
    EventDetail event, {
    EventRegistrationForm? form,
  }) async {
    final existing = _items[event.id];
    if (existing != null) return existing;
    if (event.isMine) {
      throw StateError(
        'Vous ne pouvez pas vous inscrire à votre propre événement.',
      );
    }
    if (event.isFull) {
      throw StateError('Cet événement est complet.');
    }

    Map<String, dynamic> response = {};
    if (AuthApi.useBackend) {
      if (form == null) {
        throw StateError('Les coordonnées d’inscription sont manquantes.');
      }
      response = await EventApi.register(
        eventId: event.id,
        details: {
          'nom_complet': form.fullName,
          'email': form.email,
          'telephone': form.phone,
          'ville': form.city,
          'nombre_participants': form.participants,
          'message': form.message,
        },
      );
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    final registration = EventRegistration(
      event: event,
      requestedAt:
          DateTime.tryParse('${response['date_demande'] ?? ''}') ??
          DateTime.now(),
      form: form,
      status: switch ('${response['statut'] ?? ''}') {
        'VALIDE' => EventRegistrationStatus.validated,
        'REJETE' => EventRegistrationStatus.declined,
        _ => event.requiresValidation
            ? EventRegistrationStatus.pending
            : EventRegistrationStatus.validated,
      },
    );
    _items[event.id] = registration;
    notifyListeners();
    return registration;
  }

  Future<void> cancel(String eventId) async {
    // Remplacer par DELETE /events/{id}/registrations/me.
    if (_items.remove(eventId) != null) notifyListeners();
  }

  void updateStatus(String eventId, EventRegistrationStatus status) {
    final current = _items[eventId];
    if (current == null || current.status == status) return;
    _items[eventId] = current.copyWith(status: status);
    notifyListeners();
  }
}
