import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_nav.dart';
import '../widgets/atlart_ui_widgets.dart';
import 'candidature_documents_screen.dart';

enum CandidatureMethod {
  documentOfficiel,
  portfolio,
}

extension CandidatureMethodX on CandidatureMethod {
  String get label {
    switch (this) {
      case CandidatureMethod.documentOfficiel:
        return 'Document officiel';
      case CandidatureMethod.portfolio:
        return 'Portfolio';
    }
  }

  String get description {
    switch (this) {
      case CandidatureMethod.documentOfficiel:
        return 'Diplôme, carte d\u2019artisan,\nregistre de commerce / patente';
      case CandidatureMethod.portfolio:
        return 'Montrez 3 à 5 œuvres existantes\npour prouver votre pratique';
    }
  }

  IconData get icon {
    switch (this) {
      case CandidatureMethod.documentOfficiel:
        return Icons.description_outlined;
      case CandidatureMethod.portfolio:
        return Icons.collections_outlined;
    }
  }
}

const _kCardBorder = Color(0xFFBBD7F1);
const _kCardBorderSelected = Color(0xFF8DB8E6);
const _kCardFillSelected = Color(0xFFD3E7FA);
const _kIconSelected = Color(0xFF8FA8C6);
const _kBody = Color(0xFF55606B);

class CandidatureMethodScreen extends StatefulWidget {
  const CandidatureMethodScreen({
    super.key,
    required this.roleLabel,
  });

  final String roleLabel;

  @override
  State<CandidatureMethodScreen> createState() =>
      _CandidatureMethodScreenState();
}

class _CandidatureMethodScreenState extends State<CandidatureMethodScreen> {
  CandidatureMethod? _selected;

  void _continue() {
    final method = _selected;
    if (method == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CandidatureDocumentsScreen(
          roleLabel: widget.roleLabel,
          method: method,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profil = widget.roleLabel == 'Artiste' ? 'd’artiste' : 'd’artisan';

    return AtlartCandidatureScaffold(
      step: 1,
      child: AtlartCandidatureBody(
        footer: AtlartButton(
          label: 'Continuer',
          onPressed: _selected == null ? null : _continue,
        ),
        children: [
          const Text(
            'Comment souhaitez-vous\nêtre vérifié(e) ?',
            textAlign: TextAlign.center,
            style: AtlartCandidatureType.title,
          ),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                'Choisissez la méthode adaptée à votre profil $profil. '
                'Vous pourrez joindre vos justificatifs à l\u2019étape suivante.',
                textAlign: TextAlign.center,
                style: AtlartCandidatureType.subtitle,
              ),
            ),
          ),
          const SizedBox(height: 40),
          for (final method in CandidatureMethod.values) ...[
            _MethodCard(
              method: method,
              selected: _selected == method,
              onTap: () => setState(() => _selected = method),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final CandidatureMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: method.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? _kCardFillSelected : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kCardBorderSelected : _kCardBorder,
            width: 1.5,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1F5975A2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? _kIconSelected : AtlartPalette.navyDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(method.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.label,
                          style: const TextStyle(
                            color: AtlartPalette.navyDark,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method.description,
                          style: const TextStyle(
                            color: _kBody,
                            fontSize: 10.5,
                            height: 1.6,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
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
        ),
      ),
    );
  }
}

/// Pastille de sélection du Figma : cercle clair, coche quand choisi.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selected ? AtlartPalette.blueText : const Color(0xFFA9CBEA),
          width: 1.4,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: AtlartPalette.blueText)
          : null,
    );
  }
}