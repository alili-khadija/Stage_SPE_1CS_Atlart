import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_ui_widgets.dart';
import 'candidature_method_screen.dart';
import 'signup_screen.dart';

enum AtlartRole { visiteur, artiste, artisan }

extension AtlartRoleX on AtlartRole {
  String get label {
    switch (this) {
      case AtlartRole.visiteur:
        return 'Visiteur';
      case AtlartRole.artiste:
        return 'Artiste';
      case AtlartRole.artisan:
        return 'Artisan';
    }
  }

  String get description {
    switch (this) {
      case AtlartRole.visiteur:
        return 'Découvrir, suivre, faire des offres.';
      case AtlartRole.artiste:
        return 'Publier vos œuvres et recevoir des offres.';
      case AtlartRole.artisan:
        return 'Présenter vos créations et articles.';
    }
  }

  IconData get icon {
    switch (this) {
      case AtlartRole.visiteur:
        return Icons.remove_red_eye_outlined;
      case AtlartRole.artiste:
        return Icons.image_outlined;
      case AtlartRole.artisan:
        return Icons.build_outlined;
    }
  }

  bool get requiresVerification =>
      this == AtlartRole.artiste || this == AtlartRole.artisan;
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key}) : _forCandidature = false;

  const RoleSelectionScreen.forCandidature({super.key})
      : _forCandidature = true;

  final bool _forCandidature;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  AtlartRole? _selected;

  @override
  Widget build(BuildContext context) {
    return AtlartPage(
      gradient: AtlartPalette.roleGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AtlartHeaderLogo(),
          SizedBox(height: AtlartHeaderLogo.gapBefore(context, 78)),
          Center(
            child: Text(
              widget._forCandidature
                  ? 'Devenir artiste ou artisan'
                  : 'Rejoignez Atlart',
              style: AtlartType.roleTitle,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 285,
              child: Text(
                widget._forCandidature
                    ? 'Choisissez le profil pour lequel vous souhaitez envoyer une candidature.'
                    : 'Choisissez comment vous souhaitez utiliser l’application.',
                textAlign: TextAlign.center,
                style: AtlartType.roleSubtitle,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Column(
              children: [
                for (final role in AtlartRole.values)
                  if (!widget._forCandidature || role.requiresVerification) ...[
                    _RoleCard(
                      role: role,
                      selected: _selected == role,
                      dimmed: _selected != null && _selected != role,
                      onTap: () => setState(() => _selected = role),
                    ),
                    const SizedBox(height: 18),
                  ],
                if (!widget._forCandidature) ...[
                  const SizedBox(height: 8),
                  const _InfoBox(),
                ],
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: AtlartButton(
              label: 'Continuer',
              onPressed: _selected == null
                  ? null
                  : () {
                      if (widget._forCandidature) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CandidatureMethodScreen(
                              roleLabel: _selected!.label,
                            ),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SignupScreen(role: _selected!),
                          ),
                        );
                      }
                    },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: AtlartFooter(
              leading: widget._forCandidature
                  ? 'Vous avez changé d’avis ? '
                  : 'Déjà un compte ? ',
              action: widget._forCandidature ? 'Retour' : 'Se connecter',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final AtlartRole role;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: dimmed ? 0.38 : 1,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : AtlartPalette.cardFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AtlartPalette.blueText : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: selected ? const [AtlartShadows.card] : const [AtlartShadows.field],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [AtlartShadows.tile],
                ),
                child: Icon(
                  role.icon,
                  size: 17,
                  color: AtlartPalette.blueTextSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(role.label, style: AtlartType.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: AtlartType.cardDesc,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AtlartPalette.blueText : Colors.white,
        border: Border.all(
          color: selected ? AtlartPalette.blueText : AtlartPalette.blueTextSoft,
          width: 1.4,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AtlartPalette.infoBox,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.shield_outlined,
              size: 14,
              color: AtlartPalette.blueText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Artiste et artisan passent par une courte vérification (candidature). Vous pouvez commencer en visiteur.',
              style: AtlartType.infoText,
            ),
          ),
        ],
      ),
    );
  }
}