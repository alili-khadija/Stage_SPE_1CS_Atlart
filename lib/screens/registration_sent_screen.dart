import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/event_detail.dart';
import '../models/event_registration.dart';

class RegistrationSentPage extends StatelessWidget {
  const RegistrationSentPage({
    super.key,
    required this.registration,
    this.logo,
    this.onViewRegistrations,
  });

  final EventRegistration registration;
  final Widget? logo;
  final VoidCallback? onViewRegistrations;

  String _sentLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "Aujourd'hui, $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EventRegistrationStore.instance,
      builder: (context, _) {
        final current =
            EventRegistrationStore.instance.of(registration.event.id) ??
            registration;
        final event = current.event;
        final isPending = current.status == EventRegistrationStatus.pending;
        final isDeclined = current.status == EventRegistrationStatus.declined;
        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8FB5E0), Colors.white, Colors.white],
                stops: [0, 0.17, 1],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child:
                        logo ??
                        Text(
                          'ATLART',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: _EventColors.title,
                          ),
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 24, 10),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.maybePop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.arrow_back,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Événement',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(26, 24, 26, 16),
                      child: Column(
                        children: [
                          const _CheckBadge(),
                          const SizedBox(height: 18),
                          Text(
                            isPending
                                ? 'Demande envoyée'
                                : isDeclined
                                ? 'Demande refusée'
                                : 'Inscription confirmée',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _EventColors.navy,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _EventSummaryCard(event: event),
                          const SizedBox(height: 12),
                          _StatusCard(
                            steps: [
                              _StatusStep(
                                title: 'Demande envoyée',
                                subtitle: _sentLabel(current.requestedAt),
                                state: _StepState.done,
                              ),
                              _StatusStep(
                                title: isPending
                                    ? "Validation par l'organisateur"
                                    : isDeclined
                                    ? 'Demande refusée'
                                    : "Inscription validée",
                                subtitle: isPending
                                    ? '${event.organizer?.name ?? 'Organisateur'} · en cours'
                                    : current.status.label,
                                state: isPending || isDeclined
                                    ? _StepState.current
                                    : _StepState.done,
                              ),
                              _StatusStep(
                                title: 'Billet QR disponible',
                                subtitle: isPending
                                    ? "Une fois l'inscription validée"
                                    : isDeclined
                                    ? 'Contactez l’organisateur pour en savoir plus'
                                    : 'Votre inscription est confirmée',
                                state: isPending || isDeclined
                                    ? _StepState.pending
                                    : _StepState.done,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 8, 30, 14),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: onViewRegistrations,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _EventColors.coral,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Voir mes inscriptions",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => Navigator.maybePop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _EventColors.navy,
                                side: const BorderSide(
                                  color: _EventColors.navy,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: Text(
                                "Retour à l'événement",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _EventColors.coral.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.check, size: 22, color: _EventColors.title),
    );
  }
}

class _EventSummaryCard extends StatelessWidget {
  const _EventSummaryCard({required this.event});

  final EventDetail event;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B5B8C).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (event.imagePath != null)
                    Image.file(
                      File(event.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: _EventColors.sky),
                    )
                  else if (event.imageAsset != null)
                    Image.asset(
                      event.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: _EventColors.sky),
                    )
                  else if (event.imageUrl != null)
                    Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: _EventColors.sky),
                    )
                  else
                    const ColoredBox(color: _EventColors.sky),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _EventTypePill(label: event.category),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _EventColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(Icons.calendar_today_outlined, event.dateLabel),
                  const SizedBox(height: 8),
                  _infoRow(Icons.location_on_outlined, event.locationLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFB9D0EC)),
          ),
          child: Icon(icon, size: 11, color: _EventColors.title),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 9, color: _EventColors.ink),
          ),
        ),
      ],
    );
  }
}

class _EventTypePill extends StatelessWidget {
  const _EventTypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: _EventColors.coral,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 7,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

enum _StepState { done, current, pending }

class _StatusStep {
  const _StatusStep({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final _StepState state;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.steps});

  final List<_StatusStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _StatusStepRow(step: steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }
}

class _StatusStepRow extends StatelessWidget {
  const _StatusStepRow({required this.step, required this.isLast});

  final _StatusStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isPending = step.state == _StepState.pending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                _buildDot(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: const Color(0xFFD5E2F3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isPending
                          ? _EventColors.ink.withValues(alpha: 0.35)
                          : _EventColors.ink,
                    ),
                  ),
                  Text(
                    step.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: isPending
                          ? _EventColors.muted.withValues(alpha: 0.6)
                          : _EventColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    switch (step.state) {
      case _StepState.done:
        return Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: _EventColors.navy,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 8, color: Colors.white),
        );
      case _StepState.current:
        return Container(
          width: 12,
          height: 12,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _EventColors.coral,
            shape: BoxShape.circle,
          ),
          child: Text(
            '!',
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        );
      case _StepState.pending:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFB9D0EC), width: 2),
          ),
        );
    }
  }
}

class _EventColors {
  static const coral = Color(0xFFFA7B6B);
  static const sky = Color(0xFFA8CFF1);
  static const title = Color(0xFF4A6FA5);
  static const ink = Color(0xFF1F2F46);
  static const muted = Color(0xFF8A94A6);
  static const navy = Color(0xFF234779);
}
