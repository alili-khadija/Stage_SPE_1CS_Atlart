import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/profile_shared_widgets.dart'
    show InitialsAvatar, RoundIconButton;
import 'event_draft.dart';
import 'qr_scanner_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({
    super.key,
    required this.eventTitle,
    required this.participants,
  });

  final String eventTitle;
  final List<EventParticipant> participants;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  List<EventParticipant> get _validated => widget.participants
      .where(
        (p) =>
            p.status == RegistrationStatus.validated ||
            p.status == RegistrationStatus.present,
      )
      .toList();

  List<EventParticipant> get _present => widget.participants
      .where((p) => p.status == RegistrationStatus.present)
      .toList();

  List<EventParticipant> get _waiting =>
      _validated.where((p) => p.status != RegistrationStatus.present).toList();

  List<EventParticipant> get _recent => _present.reversed.take(8).toList();

  String get _nowLabel {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  void _checkIn(EventParticipant participant, {required bool manual}) {
    if (participant.status == RegistrationStatus.present) return;
    setState(() {
      participant.status = RegistrationStatus.present;
      participant.checkedInAt = _nowLabel;
      participant.checkedInManually = manual;
      widget.participants.remove(participant);
      widget.participants.add(participant);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${participant.name} · pointage réussi.')),
    );
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<EventParticipant>(
      MaterialPageRoute<EventParticipant>(
        builder: (_) => QrScannerScreen(waitingParticipants: _waiting),
      ),
    );
    if (result != null && mounted) {
      _checkIn(result, manual: false);
    }
  }

  Future<void> _openManualSheet() async {
    final selected = await showModalBottomSheet<EventParticipant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualCheckInSheet(candidates: _waiting),
    );
    if (selected != null && mounted) {
      _checkIn(selected, manual: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _validated.length;
    final presentCount = _present.length;
    final ratio = total == 0 ? 0.0 : presentCount / total;
    final latest = _recent.isEmpty ? null : _recent.first;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
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
                      'Pointage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AtlartPalette.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AtlartPalette.coral,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Événement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pointage des billets',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AtlartPalette.navy,
                    ),
                  ),
                  Text(
                    widget.eventTitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AtlartPalette.blueTextLight,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _openScanner,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14273A56),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: const Color(0xFF16324A),
                                child: const Center(child: _ScanFrame()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Appuyez pour ouvrir le scanner QR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AtlartPalette.blueTextLight,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (latest != null) ...[
                    const SizedBox(height: 12),
                    _LatestScanRow(participant: latest),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_outlined,
                        size: 16,
                        color: AtlartPalette.blueText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$presentCount présents sur $total validés',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AtlartPalette.navy,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Text(
                        '${(ratio * 100).round()} %',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AtlartPalette.coral,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE1E9F2),
                      valueColor: const AlwaysStoppedAnimation(
                        AtlartPalette.coral,
                      ),
                    ),
                  ),
                  if (_recent.length > 1) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'DERNIERS POINTAGES',
                      style: AtlartType.stepsLabel,
                    ),
                    const SizedBox(height: 8),
                    for (final participant in _recent.skip(1))
                      _RecentRow(participant: participant),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: _openManualSheet,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AtlartPalette.navyDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Pointer manuellement'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: 0.62,
    heightFactor: 0.72,
    child: CustomPaint(painter: _CornerPainter()),
  );
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtlartPalette.coral
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const length = 18.0;
    final width = size.width;
    final height = size.height;
    final corners = [
      [Offset.zero, Offset(length, 0), Offset(0, length)],
      [Offset(width, 0), Offset(width - length, 0), Offset(width, length)],
      [Offset(0, height), Offset(length, height), Offset(0, height - length)],
      [
        Offset(width, height),
        Offset(width - length, height),
        Offset(width, height - length),
      ],
    ];
    for (final corner in corners) {
      canvas
        ..drawLine(corner[0], corner[1], paint)
        ..drawLine(corner[0], corner[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LatestScanRow extends StatelessWidget {
  const _LatestScanRow({required this.participant});

  final EventParticipant participant;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
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
          radius: 18,
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
                'Pointage réussi · ${participant.checkedInManually ? 'manuel' : 'QR'} · ${participant.checkedInAt}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AtlartPalette.blueTextLight,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF2F9E6B),
          size: 20,
        ),
      ],
    ),
  );
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.participant});

  final EventParticipant participant;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        InitialsAvatar(
          name: participant.name,
          radius: 16,
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
                participant.checkedInAt ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  color: AtlartPalette.blueTextLight,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        if (participant.checkedInManually)
          const Text(
            'MANUEL',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A5A0A),
              fontFamily: 'Poppins',
            ),
          ),
      ],
    ),
  );
}

class _ManualCheckInSheet extends StatelessWidget {
  const _ManualCheckInSheet({required this.candidates});

  final List<EventParticipant> candidates;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.7,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFFEAF2FB),
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFCBD8E8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Pointer manuellement', style: AtlartType.stepTitle),
          ),
        ),
        Flexible(
          child: candidates.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'Aucun participant validé à pointer.',
                    style: TextStyle(
                      color: AtlartPalette.blueTextLight,
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    for (final participant in candidates)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: InitialsAvatar(
                          name: participant.name,
                          radius: 17,
                          gradient: [
                            participant.avatarColor,
                            participant.avatarColor,
                          ],
                        ),
                        title: Text(
                          participant.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: AtlartPalette.navy,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AtlartPalette.blueTextLight,
                        ),
                        onTap: () => Navigator.of(context).pop(participant),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
