import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_search_widgets.dart';
import '../widgets/profile_shared_widgets.dart'
    show InitialsAvatar, RoundIconButton;
import '../services/auth_api.dart';
import '../services/event_api.dart';
import 'checkin_screen.dart';
import 'event_draft.dart';

enum _ParticipantsTab { pending, validated, present }

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({
    super.key,
    required this.eventTitle,
    this.eventId,
    this.initialParticipants,
  });

  final String eventTitle;
  final String? eventId;
  final List<EventParticipant>? initialParticipants;

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  late final List<EventParticipant> _all =
      widget.initialParticipants ??
      (AuthApi.useBackend ? <EventParticipant>[] : [
        EventParticipant(
          name: 'Leïla Mansouri',
          requestedOn: 'Demandé le 15 sept.',
          avatarColor: const Color(0xFF8A6FC9),
        ),
        EventParticipant(
          name: 'Sami Ben Amor',
          requestedOn: 'Demandé le 16 sept.',
          avatarColor: const Color(0xFF2F9E6B),
          status: RegistrationStatus.validated,
        ),
      ]);
  _ParticipantsTab _tab = _ParticipantsTab.pending;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (AuthApi.useBackend && widget.eventId != null) _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() => _loading = true);
    try {
      final rows = await EventApi.participants(widget.eventId!);
      if (!mounted) return;
      const colors = [Color(0xFF8A6FC9), Color(0xFF2F9E6B), Color(0xFF4A78B8)];
      final participants = rows.where((row) => row['statut'] != 'REJETE').map((row) {
        final name = '${row['nom_complet'] ?? 'Participant'}';
        final requested = DateTime.tryParse('${row['date_demande'] ?? ''}');
        final checkin = DateTime.tryParse('${row['date_checkin'] ?? ''}');
        return EventParticipant(
          name: name,
          requestedOn: requested == null
              ? 'Demande reçue'
              : 'Demandé le ${requested.day.toString().padLeft(2, '0')}/${requested.month.toString().padLeft(2, '0')}/${requested.year}',
          avatarColor: colors[name.hashCode.abs() % colors.length],
          registrationId: '${row['id'] ?? ''}',
          email: '${row['email'] ?? ''}',
          phone: '${row['telephone'] ?? ''}',
          message: '${row['message'] ?? ''}',
          placesRequested: int.tryParse('${row['nombre_participants'] ?? 1}') ?? 1,
          status: switch ('${row['statut'] ?? ''}') {
            'VALIDE' when row['checkin_effectue'] == true || row['checkin_effectue'] == 1 || row['checkin_effectue'] == '1' => RegistrationStatus.present,
            'VALIDE' => RegistrationStatus.validated,
            _ => RegistrationStatus.pending,
          },
          checkedInAt: checkin == null
              ? null
              : '${checkin.hour.toString().padLeft(2, '0')}:${checkin.minute.toString().padLeft(2, '0')}',
          checkedInManually: '${row['checkin_methode'] ?? ''}' == 'MANUEL',
        );
      }).toList();
      setState(() {
        _all
          ..clear()
          ..addAll(participants);
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les demandes : $error')),
      );
    }
  }

  List<EventParticipant> get _pending =>
      _all.where((p) => p.status == RegistrationStatus.pending).toList();

  List<EventParticipant> get _validated => _all
      .where(
        (p) =>
            p.status == RegistrationStatus.validated ||
            p.status == RegistrationStatus.present,
      )
      .toList();

  List<EventParticipant> get _present =>
      _all.where((p) => p.status == RegistrationStatus.present).toList();

  Future<void> _openCheckIn() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CheckInScreen(
          eventTitle: widget.eventTitle,
          eventId: widget.eventId,
          participants: _all,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _decide(EventParticipant participant, {required bool accept}) async {
    if (_saving) return;
    if (AuthApi.useBackend && participant.registrationId != null) {
      setState(() => _saving = true);
      try {
        await EventApi.decideRegistration(
          registrationId: participant.registrationId!,
          accept: accept,
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de traiter la demande : $error')),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        if (accept) {
          participant.status = RegistrationStatus.validated;
        } else {
          _all.remove(participant);
        }
        _saving = false;
      });
      return;
    }
    final oldStatus = participant.status;
    setState(() {
      if (accept) {
        participant.status = RegistrationStatus.validated;
      } else {
        _all.remove(participant);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accept
              ? '${participant.name} validé·e.'
              : '${participant.name} refusé·e.',
        ),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => setState(() {
            if (!accept) _all.add(participant);
            participant.status = oldStatus;
          }),
        ),
      ),
    );
  }

  void _navigateTab(int index) {
    if (index == 0) {
      Navigator.of(context).pushNamedAndRemoveUntil('/search', (_) => false);
    } else if (index == 3) {
      Navigator.of(context).pushNamed('/profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette section n’est pas encore disponible.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final participants = switch (_tab) {
      _ParticipantsTab.pending => _pending,
      _ParticipantsTab.validated => _validated,
      _ParticipantsTab.present => _present,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFC9DFF7), Color(0xFFE3EEFB)],
                ),
              ),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Participants',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AtlartPalette.navy,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openCheckIn,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                    label: const Text('Scanner'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AtlartPalette.navyDark,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eventTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AtlartPalette.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_all.length} inscrits · ${_present.length} présents',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AtlartPalette.blueTextLight,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _TabLabel(
                        label: 'En attente',
                        count: _pending.length,
                        selected: _tab == _ParticipantsTab.pending,
                        onTap: () =>
                            setState(() => _tab = _ParticipantsTab.pending),
                      ),
                      _TabLabel(
                        label: 'Validés',
                        count: _validated.length,
                        selected: _tab == _ParticipantsTab.validated,
                        onTap: () =>
                            setState(() => _tab = _ParticipantsTab.validated),
                      ),
                      _TabLabel(
                        label: 'Présents',
                        count: _present.length,
                        selected: _tab == _ParticipantsTab.present,
                        onTap: () =>
                            setState(() => _tab = _ParticipantsTab.present),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 20, color: Color(0xFFE1E9F2)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Chargement impossible : $_loadError',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          TextButton(
                            onPressed: _loadParticipants,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : participants.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          switch (_tab) {
                            _ParticipantsTab.pending =>
                              'Aucune demande en attente.',
                            _ParticipantsTab.validated =>
                              'Aucun participant validé.',
                            _ParticipantsTab.present =>
                              'Personne n’a encore été pointé.',
                          },
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AtlartPalette.blueTextLight,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      children: [
                        for (final participant in participants)
                          _ParticipantRow(
                            participant: participant,
                            showActions: _tab == _ParticipantsTab.pending,
                            onAccept: () => _decide(participant, accept: true),
                            onRefuse: () => _decide(participant, accept: false),
                          ),
                        if (_tab == _ParticipantsTab.pending)
                          const _InfoBanner(
                            text:
                                'Valider donne l’accord. Le pointage se fait '
                                'le jour J (QR ou manuel).',
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AtlartBottomNav(
        currentIndex: 3,
        onTap: _navigateTab,
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: [
            Text(
              '$label · $count',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AtlartPalette.coral
                    : AtlartPalette.blueTextLight,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 2,
              width: 24,
              color: selected ? AtlartPalette.coral : Colors.transparent,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.participant,
    required this.showActions,
    required this.onAccept,
    required this.onRefuse,
  });

  final EventParticipant participant;
  final bool showActions;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14273A56),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        InitialsAvatar(
          name: participant.name,
          radius: 19,
          gradient: [participant.avatarColor, participant.avatarColor],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                participant.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AtlartPalette.navy,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                participant.status == RegistrationStatus.present
                    ? 'Pointé·e à ${participant.checkedInAt ?? '--:--'}'
                    : participant.requestedOn,
                style: const TextStyle(
                  fontSize: 10,
                  color: AtlartPalette.blueTextLight,
                  fontFamily: 'Poppins',
                ),
              ),
              if (participant.email.isNotEmpty ||
                  participant.phone.isNotEmpty ||
                  participant.placesRequested > 1)
                Text(
                  [
                    if (participant.email.isNotEmpty) participant.email,
                    if (participant.phone.isNotEmpty) participant.phone,
                    if (participant.placesRequested > 1)
                      '${participant.placesRequested} places demandées',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AtlartPalette.blueTextLight,
                    fontFamily: 'Poppins',
                  ),
                ),
              if (participant.message.isNotEmpty)
                Text(
                  participant.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AtlartPalette.navy,
                    fontFamily: 'Poppins',
                  ),
                ),
            ],
          ),
        ),
        if (showActions) ...[
          _ActionButton(label: 'Valider', filled: true, onTap: onAccept),
          const SizedBox(width: 6),
          _ActionButton(label: 'Refuser', filled: false, onTap: onRefuse),
        ] else if (participant.status == RegistrationStatus.present)
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2F9E6B),
            size: 20,
          ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: filled ? Colors.white : AtlartPalette.navyDark,
      backgroundColor: filled ? AtlartPalette.coral : Colors.white,
      side: filled ? null : const BorderSide(color: AtlartPalette.navyDark),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10, fontFamily: 'Poppins'),
    ),
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFD3E6FA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.groups_outlined,
          size: 15,
          color: AtlartPalette.blueText,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color: AtlartPalette.navy,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    ),
  );
}
