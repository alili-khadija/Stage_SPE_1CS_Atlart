import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_session.dart';
import '../models/event_detail.dart';
import '../models/event_registration.dart';
import '../theme/atlart_ui_theme.dart';
import 'event_draft.dart';
import 'event_detail_page.dart';
import 'event_model_screen.dart';
import 'new_event_screen.dart';
import 'participants_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _selectedTab = 0;
  final Set<String> _favorites = {};
  final List<_CreatedEvent> _createdEvents = [];

  bool get _canOrganizeEvents =>
      AtlartSession.role == 'artiste' || AtlartSession.role == 'artisan';

  static const List<EventItem> _events = [
    EventItem(
      title: 'Regards sur la Médina',
      type: 'Exposition',
      dateLabel: '12 – 20 octobre 2026',
      locationLabel: 'Présentiel · Galerie El Morso, Tunis',
      capacityNote: 'Entrée libre',
      description:
          'Une exposition consacrée aux métiers d’art et aux créations '
          'inspirées par la Médina de Tunis.',
      placesLeft: 24,
      program: [
        ProgramStep(
          day: 'J-1',
          title: 'Ouverture de l’exposition',
          subtitle: 'Accueil à la Galerie El Morso',
        ),
        ProgramStep(
          day: 'J-2',
          title: 'Rencontre avec les artistes',
          subtitle: 'Présentation des œuvres exposées',
        ),
      ],
      organizerName: 'Galerie El Morso',
      organizerLocation: 'Tunis, Tunisie',
      imageAsset: 'assets/images/evt_regards_medina.png',
    ),
    EventItem(
      title: "Initiation à l'aquarelle",
      type: 'Atelier',
      dateLabel: '14 octobre 2026 · 18:30',
      locationLabel: 'En ligne',
      capacityNote: 'Places limitées · matériel fourni',
      description:
          'Un atelier d’initiation à l’aquarelle ouvert à tous les niveaux.',
      placesLeft: 8,
      program: [
        ProgramStep(
          day: '18:30',
          title: 'Découverte du matériel',
          subtitle: 'Présentation des couleurs et des pinceaux',
        ),
        ProgramStep(
          day: '19:00',
          title: 'Premiers exercices',
          subtitle: 'Pratique guidée en ligne',
        ),
      ],
      organizerName: 'Atelier Créatif',
      organizerLocation: 'En ligne',
      imageAsset: 'assets/images/evt_calligraphie.png',
    ),
    EventItem(
      title: 'Résidence Sahara',
      type: 'Résidence',
      dateLabel: '1 – 15 novembre 2026',
      locationLabel: 'Présentiel · Tozeur, Tunisie',
      capacityNote: 'Places limitées · inscription soumise à validation',
      description:
          'Une résidence artistique autour des savoir-faire et matières '
          'traditionnelles du Sahara.',
      placesLeft: 6,
      program: [
        ProgramStep(
          day: 'J-15',
          title: 'Accueil des participants',
          subtitle: 'Installation et découverte du lieu',
        ),
        ProgramStep(
          day: 'J-10',
          title: 'Ateliers de création',
          subtitle: 'Rencontres avec des artisans locaux',
        ),
        ProgramStep(
          day: 'J-1',
          title: 'Présentation des créations',
          subtitle: 'Exposition ouverte au public',
        ),
      ],
      organizerName: 'Atelier Dorra',
      organizerLocation: 'Tozeur, Tunisie',
      imageAsset: 'assets/images/tapis_beni_ourain.png',
    ),
  ];

  void _openEvent(EventDetail event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailPage(
          event: event,
          onViewRegistrations: () => setState(() => _selectedTab = 1),
        ),
      ),
    );
  }

  Future<void> _createEvent() async {
    final draft = await Navigator.of(context).push<EventDraft>(
      MaterialPageRoute<EventDraft>(builder: (_) => const NewEventScreen()),
    );
    if (!mounted || draft == null) return;
    setState(() {
      _createdEvents.insert(0, _CreatedEvent(draft));
      _selectedTab = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Événement ajouté à vos événements organisés.'),
      ),
    );
  }

  void _openParticipants(_CreatedEvent event) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ParticipantsScreen(
          eventTitle: event.draft.title,
          initialParticipants: event.participants,
        ),
      ),
    );
  }

  void _toggleFavorite(String title) {
    setState(() {
      if (!_favorites.add(title)) {
        _favorites.remove(title);
      }
    });
  }

  void _selectBottomTab(int index) {
    if (index == 0) return;

    if (index == 3) {
      Navigator.of(context).pushNamed('/profile');
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Cette section n’est pas encore disponible.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AtlartPalette.skyHeader, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _HeaderButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Les notifications ne sont pas encore reliées.',
                              ),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      Image.asset(
                        AtlartAssets.logoHorizontal,
                        height: 24,
                        errorBuilder: (_, _, _) => Text(
                          'ATLART',
                          style: GoogleFonts.poppins(
                            color: AtlartPalette.blueText,
                            fontSize: 14,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _HeaderButton(
                        icon: Icons.menu_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Menu bientôt disponible.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Événements',
                    style: GoogleFonts.poppins(
                      color: AtlartPalette.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: EventRegistrationStore.instance,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    _Tabs(
                      selectedIndex: _selectedTab,
                      onSelected: (index) {
                        setState(() => _selectedTab = index);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedTab == 0) ...[
                      for (final event in _events) ...[
                        _EventCard(
                          event: event,
                          isFavorite: _favorites.contains(event.title),
                          onFavorite: () => _toggleFavorite(event.title),
                          onTap: () => _openEvent(event.toEventDetail()),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ] else if (_selectedTab == 1 &&
                        EventRegistrationStore
                            .instance
                            .registrations
                            .isNotEmpty) ...[
                      for (final registration
                          in EventRegistrationStore.instance.registrations) ...[
                        _RegistrationEventCard(
                          registration: registration,
                          onTap: () => _openEvent(registration.event),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ] else if (_selectedTab == 2 &&
                        _createdEvents.isNotEmpty) ...[
                      for (final event in _createdEvents) ...[
                        _OrganizedEventCard(
                          event: event,
                          onOpen: () => _openEvent(event.draft.toEventDetail()),
                          onParticipants: () => _openParticipants(event),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ] else
                      _EmptyTab(
                        message: _selectedTab == 1
                            ? "Vous n'avez pas encore d'inscription."
                            : _canOrganizeEvents
                            ? "Vous n'organisez pas encore d'événement. "
                                  "Organisez votre premier événement."
                            : 'La création d’événements est réservée aux profils artiste et artisan.',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _canOrganizeEvents
          ? FloatingActionButton.extended(
              onPressed: _createEvent,
              backgroundColor: AtlartPalette.coral,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('Organiser'),
            )
          : null,
      bottomNavigationBar: _BottomNav(onTap: _selectBottomTab),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 19, color: AtlartPalette.navy),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _labels = ['À venir', 'Mes inscriptions', 'Organisés'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < _labels.length; index++)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Text(
                      _labels[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: selectedIndex == index
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selectedIndex == index
                            ? AtlartPalette.coral
                            : AtlartPalette.blueTextLight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: selectedIndex == index ? 28 : 0,
                      height: 2,
                      color: AtlartPalette.coral,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  final EventItem event;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: const Color(0x183B5B8C),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _eventImage(event),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AtlartPalette.coral,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.type,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onFavorite,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 17,
                            color: AtlartPalette.coral,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.poppins(
                      color: AtlartPalette.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _InfoLine(
                    icon: Icons.calendar_today_outlined,
                    text: event.dateLabel,
                  ),
                  const SizedBox(height: 5),
                  _InfoLine(
                    icon: Icons.location_on_outlined,
                    text: event.locationLabel,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${event.placesLeft} places restantes',
                    style: GoogleFonts.poppins(
                      color: AtlartPalette.blueText,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _eventImage(EventItem event) {
  if (event.imagePath != null) {
    return Image.file(
      File(event.imagePath!),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFA8CFF1),
        child: Icon(Icons.event_outlined, color: Colors.white, size: 36),
      ),
    );
  }

  if (event.imageAsset != null) {
    return Image.asset(
      event.imageAsset!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFA8CFF1),
        child: Icon(Icons.event_outlined, color: Colors.white, size: 36),
      ),
    );
  }

  if (event.imageUrl != null) {
    return Image.network(
      event.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFA8CFF1),
        child: Icon(Icons.event_outlined, color: Colors.white, size: 36),
      ),
    );
  }

  return const ColoredBox(
    color: Color(0xFFA8CFF1),
    child: Icon(Icons.event_outlined, color: Colors.white, size: 36),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AtlartPalette.blueText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: AtlartPalette.navy, fontSize: 9),
          ),
        ),
      ],
    );
  }
}

class _RegistrationEventCard extends StatelessWidget {
  const _RegistrationEventCard({
    required this.registration,
    required this.onTap,
  });

  final EventRegistration registration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final event = registration.event;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: const Color(0x183B5B8C),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: GoogleFonts.poppins(
                  color: AtlartPalette.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${event.dateLabel} · ${event.locationLabel}',
                style: GoogleFonts.poppins(
                  color: AtlartPalette.blueTextLight,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                registration.status.label,
                style: GoogleFonts.poppins(
                  color: AtlartPalette.coral,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AtlartPalette.blueTextLight,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CreatedEvent {
  _CreatedEvent(this.draft);

  final EventDraft draft;
  final List<EventParticipant> participants = [];
}

class _OrganizedEventCard extends StatelessWidget {
  const _OrganizedEventCard({
    required this.event,
    required this.onOpen,
    required this.onParticipants,
  });

  final _CreatedEvent event;
  final VoidCallback onOpen;
  final VoidCallback onParticipants;

  @override
  Widget build(BuildContext context) {
    final item = event.draft.toEventItem();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x183B5B8C),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEAF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_outlined,
                  color: AtlartPalette.navyDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AtlartPalette.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${item.type} · Aperçu local',
                      style: GoogleFonts.poppins(
                        color: AtlartPalette.blueTextLight,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine(icon: Icons.calendar_today_outlined, text: item.dateLabel),
          const SizedBox(height: 5),
          _InfoLine(icon: Icons.location_on_outlined, text: item.locationLabel),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpen,
                  child: const Text('Voir l’événement'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onParticipants,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtlartPalette.coral,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Participants'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onTap});

  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.search_rounded, 'Découvrir'),
    (Icons.chat_bubble_outline_rounded, 'Messagerie'),
    (Icons.favorite_border_rounded, 'Favoris'),
    (Icons.person_outline_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEDF2F7))),
        ),
        child: Row(
          children: [
            for (var index = 0; index < _items.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _items[index].$1,
                        size: 20,
                        color: index == 0
                            ? AtlartPalette.coral
                            : AtlartPalette.blueTextLight,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _items[index].$2,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: index == 0
                              ? AtlartPalette.coral
                              : AtlartPalette.blueTextLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
