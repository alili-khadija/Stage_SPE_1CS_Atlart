import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_nav.dart';
import '../widgets/atlart_ui_widgets.dart';
import 'candidature_method_screen.dart';
import 'candidature_sent_screen.dart';

class CandidatureFile {
  const CandidatureFile(this.name, this.typeLabel, this.sizeLabel);

  final String name;
  final String typeLabel;
  final String sizeLabel;
}

class CandidatureDocumentsScreen extends StatefulWidget {
  const CandidatureDocumentsScreen({
    super.key,
    required this.roleLabel,
    required this.method,
  });

  final String roleLabel;
  final CandidatureMethod method;

  @override
  State<CandidatureDocumentsScreen> createState() =>
      _CandidatureDocumentsScreenState();
}

class _CandidatureDocumentsScreenState
    extends State<CandidatureDocumentsScreen> {
  final List<CandidatureFile> _files = [];

  void _addDemoFile() {
    setState(() {
      _files.add(
        _files.isEmpty
            ? const CandidatureFile(
                'diplome_beaux_arts.pdf', 'DIPLÔME', '2,1 Mo')
            : const CandidatureFile(
                'carte_artisan_2024.jpg', 'CARTE ARTISAN', '860 Ko'),
      );
    });
  }

  void _removeFile(int index) => setState(() => _files.removeAt(index));

  void _continue() {
    if (_files.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CandidatureSentScreen(
          roleLabel: widget.roleLabel,
          method: widget.method,
          fileCount: _files.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profil = widget.roleLabel == 'Artiste' ? 'd’artiste' : 'd’artisan';

    return AtlartCandidatureScaffold(
      step: 2,
      child: AtlartCandidatureBody(
        footer: AtlartButton(
          label: 'Envoyer ma candidature',
          onPressed: _files.isEmpty ? null : _continue,
        ),
        children: [
          Text(
            'Vos justificatifs $profil',
            textAlign: TextAlign.center,
            style: AtlartCandidatureType.title,
          ),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: const Text(
                'Ajoutez au moins un document. Formats acceptés : '
                'PDF, JPG, PNG (max 10 Mo).',
                textAlign: TextAlign.center,
                style: AtlartCandidatureType.subtitle,
              ),
            ),
          ),
          const SizedBox(height: 32),
          for (int i = 0; i < _files.length; i++) ...[
            _FileRow(file: _files[i], onRemove: () => _removeFile(i)),
            const SizedBox(height: 12),
          ],
          _DropZone(onTap: _addDemoFile),
        ],
      ),
    );
  }
}

/// Zone « Ajouter un document » avec bordure pointillée (Figma).
class _DropZone extends StatelessWidget {
  const _DropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DashedRRectPainter(
            color: const Color(0xFFCFC3B5),
            radius: 14,
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 26, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  Icons.file_upload_outlined,
                  color: AtlartPalette.error,
                  size: 22,
                ),
                SizedBox(height: 8),
                Text(
                  'Ajouter un document',
                  style: TextStyle(
                    color: AtlartPalette.navyDark,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Glissez un fichier ou parcourez vos dossiers',
                  textAlign: TextAlign.center,
                  style: AtlartCandidatureType.subtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove});

  final CandidatureFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [AtlartShadows.field],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE2D9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: AtlartPalette.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    color: AtlartPalette.navyDark,
                    fontSize: 12.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${file.typeLabel} \u00b7 ${file.sizeLabel}',
                  style: AtlartCandidatureType.subtitle.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 18,
              color: AtlartPalette.error,
            ),
          ),
        ],
      ),
    );
  }
}