import 'package:flutter/material.dart';

import '../theme/atlart_layout.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_ui_widgets.dart';
import 'candidature_method_screen.dart';
import 'role_selection_screen.dart';
import 'search_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.role,
    required this.firstName,
  });

  final AtlartRole role;
  final String firstName;

  bool get _needsVerification => role.requiresVerification;

  void _goToExplore(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const SearchScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _needsVerification
        ? 'Votre compte est créé. Pour publier vos œuvres, votre\n'
            'profil d’${role == AtlartRole.artiste ? "artiste" : "artisan"} '
            'doit d’abord être vérifié.'
        : 'Votre compte est créé. Vous pouvez explorer Atlart\n'
            'dès maintenant.';

    return AtlartPage(
      gradient: AtlartPalette.welcomeGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AtlartHeaderLogo(),
          SizedBox(height: AtlartHeaderLogo.gapBefore(context, 159)),
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [AtlartShadows.field],
              ),
              child: const Icon(
                Icons.check,
                size: 20,
                color: AtlartPalette.blueText,
              ),
            ),
          ),
          const SizedBox(height: 47),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Bienvenue, ${firstName.isEmpty ? "sur Atlart" : firstName} !',
                  textAlign: TextAlign.center,
                  style: AtlartType.welcomeTitle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AtlartType.welcomeSubtitle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 41),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AtlartLayout.pageHPadding,
            ),
            child: _StepsCard(
              title: _needsVerification
                  ? 'PROCHAINE ÉTAPE'
                  : 'POUR BIEN COMMENCER',
              steps: _needsVerification
                  ? const [
                      _Step(
                        'Choisir la méthode',
                        'Document officiel ou portfolio',
                        _StepState.current,
                      ),
                      _Step(
                        'Envoyer vos justificatifs',
                        'Environ 2 minutes',
                        _StepState.upcoming,
                      ),
                      _Step(
                        'Décision sous 48 h',
                        'Vous serez notifié(e)',
                        _StepState.upcoming,
                      ),
                    ]
                  : const [
                      _Step(
                        'Compte créé',
                        'Vous êtes connecté(e)',
                        _StepState.done,
                      ),
                      _Step(
                        'Explorez les œuvres et les événements',
                        'Filtrez par pays, type ou disponibilité',
                        _StepState.current,
                      ),
                      _Step(
                        'Suivez vos artistes préférés',
                        'Et faites vos premières offres',
                        _StepState.upcoming,
                      ),
                    ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AtlartLayout.pageHPadding,
            ),
            child: AtlartGhostButton(
              label: _needsVerification
                  ? 'Explorer d’abord'
                  : 'Devenir artiste ou artisan',
              onPressed: () {
                if (_needsVerification) {
                  _goToExplore(context);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RoleSelectionScreen.forCandidature(),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 23),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AtlartLayout.pageHPadding,
            ),
            child: AtlartButton(
              label: _needsVerification
                  ? 'Vérifier mon profil'
                  : 'Explorer Atlart',
              height: 49,
              onPressed: () {
                if (_needsVerification) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CandidatureMethodScreen(
                        roleLabel: role.label,
                      ),
                    ),
                  );
                } else {
                  _goToExplore(context);
                }
              },
            ),
          ),
          const SizedBox(height: 71),
        ],
      ),
    );
  }
}

/// done = pastille bleue, current = pastille corail avec halo,
/// upcoming = pastille creuse.
enum _StepState { done, current, upcoming }

class _Step {
  const _Step(this.title, this.subtitle, this.state);

  final String title;
  final String subtitle;
  final _StepState state;
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.title, required this.steps});

  final String title;
  final List<_Step> steps;

  static const double _pitch = 50;
  static const double _lastHeight = 34;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [AtlartShadows.field],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AtlartType.stepsLabel),
          const SizedBox(height: 20),
          for (int i = 0; i < steps.length; i++)
            _StepTile(step: steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step, required this.isLast});

  final _Step step;
  final bool isLast;

  static const _coral = Color(0xFFF26565);
  static const _blue = Color(0xFF4F86CF);
  static const _hollowBorder = Color(0xFFCEE0F3);
  static const _line = Color(0xFFD5E4F4);
  static const double _dotCenterY = 8.6;
  static const double _textLeft = 27;

  @override
  Widget build(BuildContext context) {
    final height = isLast ? _StepsCard._lastHeight : _StepsCard._pitch;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!isLast)
            Positioned(
              left: 4.75,
              top: _dotCenterY + 8,
              width: 1.5,
              height: _StepsCard._pitch - 16,
              child: const ColoredBox(color: _line),
            ),
          _dot(),
          Positioned(
            left: _textLeft,
            top: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: AtlartType.stepTitle),
                const SizedBox(height: 1),
                Text(step.subtitle, style: AtlartType.stepSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    switch (step.state) {
      case _StepState.current:
        return Positioned(
          left: -2.5,
          top: _dotCenterY - 8,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0x33F26565),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: _coral,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      case _StepState.done:
        return Positioned(
          left: 0,
          top: _dotCenterY - 5.5,
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: _blue,
              shape: BoxShape.circle,
            ),
          ),
        );
      case _StepState.upcoming:
        return Positioned(
          left: 0,
          top: _dotCenterY - 5.5,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _hollowBorder, width: 1),
            ),
          ),
        );
    }
  }
}