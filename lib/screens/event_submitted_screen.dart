import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import 'event_draft.dart';
import 'event_form_widgets.dart' show EventPageBackground;
import 'event_detail_page.dart';

/// Écran affiché juste après "Soumettre l'événement" : l'événement part
/// en modération, l'organisateur peut déjà consulter sa fiche ou
/// retourner à la liste de ses événements.
class EventSubmittedScreen extends StatelessWidget {
  const EventSubmittedScreen({super.key, required this.draft});

  final EventDraft draft;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: EventPageBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(color: AtlartPalette.coral, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Événement soumis',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                            color: AtlartPalette.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Un modérateur examine votre événement. Vous serez '
                          'notifié·e dans l\'application et par e-mail.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, height: 1.6, color: AtlartPalette.blueTextLight, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 26),
                        _TrackingCard(draft: draft),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AtlartPalette.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EventDetailPage(
                          event: draft.toEventDetail(),
                        ),
                      ),
                    ),
                    child: const Text('Voir l\'événement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AtlartPalette.navyDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.of(context).pop(draft),
                    child: const Text(
                      'Retour à mes événements',
                      style: TextStyle(color: AtlartPalette.navyDark, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.draft});
  final EventDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SUIVI DE VOTRE ÉVÉNEMENT', style: AtlartType.stepsLabel),
          const SizedBox(height: 10),
          const _TrackingRow(text: 'Détails complétés', color: Color(0xFF2F9E6B)),
          const _TrackingRow(text: 'Soumis pour modération', color: Color(0xFF2F9E6B)),
          _TrackingRow(text: 'Décision sous 24 h · en attente', color: const Color(0xFFE0A53C), last: true),
        ],
      ),
    );
  }
}

class _TrackingRow extends StatelessWidget {
  const _TrackingRow({required this.text, required this.color, this.last = false});
  final String text;
  final Color color;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 7),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Text(text, style: const TextStyle(fontSize: 12, color: AtlartPalette.navy, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
