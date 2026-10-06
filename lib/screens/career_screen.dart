import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/profile_shared_widgets.dart';
class CareerStep {
  CareerStep({
    required this.title,
    required this.years,
    this.description,
    this.verified = false,
  });

  String title;
  String years;
  String? description;
  bool verified;
}

/// "Parcours & formation" : étapes affichées sur le profil public d'un
/// artiste ou artisan (résidences, écoles, diplômes...).
class CareerScreen extends StatefulWidget {
  const CareerScreen({super.key, this.initialSteps});

  final List<CareerStep>? initialSteps;

  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
  late final List<CareerStep> _steps = widget.initialSteps ??
      [
        CareerStep(
          title: 'Atelier Dar Ben Gacem',
          years: '2021 — aujourd\'hui',
          description: 'Résidence artistique, peinture murale et techniques mixtes.',
        ),
        CareerStep(
          title: 'École des Beaux-Arts de Tunis',
          years: '2010 — 2014',
          verified: true,
        ),
        CareerStep(title: 'Lycée Pierre de Coubertin', years: '2007 — 2010'),
      ];

  bool _saving = false;

  void _addStep() {
    setState(() {
      _steps.insert(
        0,
        CareerStep(title: 'Nouvelle étape', years: 'Modifiez les dates'),
      );
    });
    // TODO: ouvrir un formulaire (établissement, dates, justificatif) au
    // lieu d'insérer une étape à compléter sur place.
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parcours enregistré.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      appBar: ProfileSubPageHeader(
        title: 'Parcours & formation',
        action: RoundIconButton(icon: Icons.add_rounded, onTap: _addStep),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                children: [
                  const Text(
                    'Ces étapes s\'affichent sur votre profil public.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AtlartPalette.blueTextLight,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final step in _steps) _StepCard(step: step),
                  _AddStepCard(onTap: _addStep),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PillButton(label: 'Enregistrer', loading: _saving, onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});
  final CareerStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x14273A56), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AtlartPalette.navy,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 1),
          Text(
            step.years,
            style: const TextStyle(
              fontSize: 11,
              color: AtlartPalette.blueTextLight,
              fontFamily: 'Poppins',
            ),
          ),
          if (step.description != null) ...[
            const SizedBox(height: 6),
            Text(
              step.description!,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: AtlartPalette.navy,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          if (step.verified) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: ProfilePalette.verifiedBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 12, color: ProfilePalette.verified),
                  SizedBox(width: 4),
                  Text(
                    'Diplôme joint · vérifié',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ProfilePalette.verified,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddStepCard extends StatelessWidget {
  const _AddStepCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFD3E6FA).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AtlartPalette.blueText, width: 1.4),
          // Remarque : Flutter n'a pas de bordure pointillée native. Pour un
          // vrai tracé en tirets comme sur la maquette, ajoute le paquet
          // `dotted_border` et remplace ce Container par un DottedBorder.
        ),
        child: Column(
          children: const [
            Icon(Icons.add_rounded, color: AtlartPalette.blueText),
            SizedBox(height: 2),
            Text(
              'Ajouter une étape',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AtlartPalette.blueText,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              'Établissement, dates, justificatif',
              style: TextStyle(
                fontSize: 11,
                color: AtlartPalette.blueTextLight,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}