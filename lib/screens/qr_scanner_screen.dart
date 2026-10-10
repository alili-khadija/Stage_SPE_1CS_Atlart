import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import 'event_draft.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, required this.waitingParticipants, this.previewMode = true});

  final List<EventParticipant> waitingParticipants;
  final bool previewMode;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _scanning = false;

  Future<void> _simulateScan() async {
    if (_scanning) return;
    if (!widget.previewMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le scanner caméra n’est pas encore relié. Utilisez le pointage manuel.'),
        ),
      );
      return;
    }
    if (widget.waitingParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun billet validé à scanner.')),
      );
      return;
    }
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final participant = widget.waitingParticipants.first;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop(participant);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF16324A),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Pointage',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              !widget.previewMode
                  ? 'Le scanner caméra sera disponible prochainement. Le pointage manuel est relié au serveur.'
                  : widget.waitingParticipants.isEmpty
                  ? 'Aucun participant validé en attente de pointage.'
                  : 'Mode aperçu : appuyez dans le cadre pour simuler un scan QR.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _simulateScan,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const CustomPaint(
                        size: Size(240, 240),
                        painter: _CornerPainter(),
                      ),
                      if (_scanning)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AtlartPalette.coral,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Pointer manuellement',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtlartPalette.coral
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const length = 22.0;
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
