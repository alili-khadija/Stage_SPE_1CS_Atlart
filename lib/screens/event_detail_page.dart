import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/event_detail.dart';
import '../models/event_registration.dart';
import '../widgets/event_ui.dart';
import 'event_registration_form_screen.dart';
import 'registration_sent_screen.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({
    super.key,
    this.event = EventDetail.demoResidence,
    this.onViewOrganizer,
    this.onMore,
    this.onViewRegistrations,
  });

  final EventDetail event;
  final VoidCallback? onViewOrganizer;
  final VoidCallback? onMore;
  final VoidCallback? onViewRegistrations;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Future<void> _register() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EventRegistrationFormScreen(
          event: widget.event,
          onViewRegistrations: _viewRegistrations,
        ),
      ),
    );
  }

  void _openStatus(EventRegistration registration) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistrationSentPage(
          registration: registration,
          onViewRegistrations: _viewRegistrations,
        ),
      ),
    );
  }

  void _viewRegistrations() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pop();
    widget.onViewRegistrations?.call();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isFull = event.isFull;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCover(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
                    child: _buildContent(event),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE3E8F0)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 14),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ListenableBuilder(
                  listenable: EventRegistrationStore.instance,
                  builder: (context, _) {
                    final registration = EventRegistrationStore.instance.of(
                      event.id,
                    );
                    return ElevatedButton(
                      onPressed:
                          event.isMine || (isFull && registration == null)
                          ? null
                          : registration == null
                          ? _register
                          : () => _openStatus(registration),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _EventColors.coral,
                        disabledBackgroundColor: const Color(0xFFB8BEC8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        event.isMine
                            ? 'Événement organisé par vous'
                            : registration != null
                            ? registration.status.label
                            : isFull
                            ? 'Complet'
                            : "S'inscrire",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final event = widget.event;
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _eventImage(),
          Positioned(
            top: topPadding + 12,
            left: 20,
            child: _RoundButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.maybePop(context),
            ),
          ),
          Positioned(
            top: topPadding + 12,
            right: 20,
            child: _RoundButton(icon: Icons.more_horiz, onTap: widget.onMore),
          ),
          Positioned(
            left: 26,
            bottom: 16,
            child: _EventTypePill(label: event.category),
          ),
        ],
      ),
    );
  }

  Widget _eventImage() {
    return EventHeroImage(event: widget.event);
  }

  Widget _buildContent(EventDetail event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _EventColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        _infoRow(Icons.calendar_today_outlined, event.dateLabel),
        _infoRow(Icons.location_on_outlined, event.locationLabel),
        if (event.registrationNote.isNotEmpty)
          _infoRow(Icons.access_time, event.registrationNote),
        const SizedBox(height: 10),
        Text(
          event.description,
          style: GoogleFonts.poppins(
            fontSize: 9,
            height: 1.6,
            color: _EventColors.ink.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 22),
        if (event.placesLeft != null)
          Row(
            children: [
              const _AvatarStack(),
              const SizedBox(width: 10),
              Text(
                '${event.placesLeft} places restantes',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _EventColors.ink,
                ),
              ),
            ],
          ),
        const SizedBox(height: 22),
        _sectionLabel('Programme'),
        const SizedBox(height: 12),
        for (final step in event.program) _ProgramTile(step: step),
        const SizedBox(height: 14),
        _sectionLabel('Organisateur'),
        const SizedBox(height: 12),
        _buildOrganizer(event),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: _EventColors.blueText,
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _EventColors.blueText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 9, color: _EventColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizer(EventDetail event) {
    final organizer = event.organizer;
    if (organizer == null) {
      return Text(
        'Informations organisateur indisponibles.',
        style: GoogleFonts.poppins(fontSize: 9, color: _EventColors.blueText),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD6E4F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 15, backgroundColor: Color(0xFFD9D9D9)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organizer.name,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _EventColors.title,
                  ),
                ),
                Text(
                  organizer.location,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: _EventColors.title.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onViewOrganizer,
            child: Text(
              'Voir le profil',
              style: GoogleFonts.poppins(
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
                color: _EventColors.blueText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTypePill extends StatelessWidget {
  const _EventTypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _EventColors.coral,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: _EventColors.ink),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 20,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 12.0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _EventColors.sky,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({required this.step});

  final EventProgramItem step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _EventColors.sky,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              step.dayLabel,
              style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: _EventColors.title,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _EventColors.ink,
                  ),
                ),
                Text(
                  step.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: _EventColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventColors {
  static const coral = Color(0xFFFA7B6B);
  static const sky = Color(0xFFA8CFF1);
  static const title = Color(0xFF4A6FA5);
  static const blueText = Color(0xFF5B7DB1);
  static const ink = Color(0xFF1F2F46);
  static const muted = Color(0xFF8A94A6);
}
