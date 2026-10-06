import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_nav.dart';
import '../widgets/atlart_ui_widgets.dart';
import 'candidature_method_screen.dart';
import 'search_screen.dart';

class CandidatureSentScreen extends StatelessWidget {
  const CandidatureSentScreen({
    super.key,
    required this.roleLabel,
    required this.method,
    required this.fileCount,
  });

  final String roleLabel;
  final CandidatureMethod method;
  final int fileCount;

  @override
  Widget build(BuildContext context) {
    final profil = roleLabel == 'Artiste' ? 'd’artiste' : 'd’artisan';

    return AtlartCandidatureScaffold(
      step: 3,
      child: AtlartCandidatureBody(
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtlartButton(
              label: 'Réponse immédiate',
              onPressed: () {
                // TODO: brancher le flow de vérification instantanée
                // (démo / test), une fois disponible côté back-end.
              },
            ),
            const SizedBox(height: 12),
            AtlartGhostButton(
              label: 'Explorer Atlart',
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const SearchScreen(),
                ),
                (_) => false,
              ),
            ),
          ],
        ),
        children: [
          Center(
            child: Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: AtlartPalette.coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Candidature envoyée',
            textAlign: TextAlign.center,
            style: AtlartType.title,
          ),
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Notre équipe examine votre dossier. Vous serez notifié(e) '
                'dans l\u2019application et par e-mail pour votre candidature '
                '$profil.',
                textAlign: TextAlign.center,
                style: AtlartType.subtitle,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [AtlartShadows.field],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SUIVI DE VOTRE CANDIDATURE',
                    style: AtlartType.fieldLabel),
                const SizedBox(height: 14),
                _TrackRow(
                  title: 'Méthode choisie',
                  subtitle: method.label,
                  done: true,
                ),
                _TrackRow(
                  title: 'Justificatifs envoyés',
                  subtitle:
                      fileCount == 1 ? '1 document' : '$fileCount documents',
                  done: true,
                ),
                const _TrackRow(
                  title: 'Décision sous 48 h',
                  subtitle: 'Statut : en attente',
                  done: false,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.title,
    required this.subtitle,
    required this.done,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AtlartPalette.blueText : AtlartPalette.error,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.4,
                  height: 28,
                  color: const Color(0xFFD5E4F4),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AtlartPalette.navyDark,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AtlartType.subtitle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}