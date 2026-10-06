import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';

/// Bandeau "Atlart" + titre de page + badge d'étape ("2/4") + barre de
/// progression, utilisé dans les parcours multi-étapes (ajout d'article,
/// complétion de profil...).
class AtlartStepHeader extends StatelessWidget {
  const AtlartStepHeader({
    super.key,
    required this.title,
    required this.step,
    this.totalSteps = 4,
    this.showBack = false,
    this.showBrand = true,
    this.onBack,
    this.trailing,
  });

  final String title;
  final int step;
  final int totalSteps;
  final bool showBack;

  /// Le mot "Atlart" centré au-dessus du titre — visible sur la plupart des
  /// écrans du parcours, absent sur l'accueil dans la maquette.
  final bool showBrand;
  final VoidCallback? onBack;

  /// Widget affiché à la place du badge d'étape (ex: cloche de
  /// notifications sur l'écran Profil).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps == 0 ? 0.0 : step / totalSteps;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AtlartPalette.skyHeader, Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBrand) ...[
            const Center(
              child: Text(
                "Atlart",
                style: TextStyle(
                  color: AtlartPalette.navyDark,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 15, color: AtlartPalette.navy),
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AtlartPalette.navyDark,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              trailing ??
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [AtlartShadows.tile],
                    ),
                    child: Text(
                      "$step/$totalSteps",
                      style: const TextStyle(
                        color: AtlartPalette.navyDark,
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFD5E6F7),
              valueColor: const AlwaysStoppedAnimation(AtlartPalette.blueText),
            ),
          ),
        ],
      ),
    );
  }
}