import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/atlart_layout.dart';
import '../theme/atlart_ui_theme.dart';
import 'atlart_navigation.dart';

const _kWavesAsset = 'assets/images/candidature_waves.png';

/// Si les vagues ne tombent pas comme sur le Figma, ajuste ces deux lignes.
const BoxFit _kWavesFit = BoxFit.cover;
const Alignment _kWavesAlignment = Alignment.center;

const _kStepOn = Color(0xFF7088AA);
const _kStepOff = Color(0xFFD9E5F1);
const _kNavLine = Color(0xFFE6EDF5);

/// Textes communs aux 3 écrans de candidature (cohérence garantie).
class AtlartCandidatureType {
  AtlartCandidatureType._();

  static const title = TextStyle(
    color: Color(0xFF16324A),
    fontSize: 19,
    height: 1.35,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
  );

  static const subtitle = TextStyle(
    color: Color(0xFF55606B),
    fontSize: 11,
    height: 1.7,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
  );
}

/// Cadre commun des écrans de candidature : en-tête bleu (logo, titre, menu,
/// stepper), vagues en fond, contenu, barre de navigation du bas.
///
/// Plein écran (plus de fond gris ni de zone limitée à 390 x 844).
class AtlartCandidatureScaffold extends StatelessWidget {
  const AtlartCandidatureScaffold({
    super.key,
    required this.step,
    required this.child,
    this.onDestinationSelected,
    this.selectedIndex = 3,
    this.onMenuTap,
  });

  /// 1, 2 ou 3 : nombre de segments allumés dans le stepper.
  final int step;
  final Widget child;
  final ValueChanged<int>? onDestinationSelected;
  final int selectedIndex;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _Header(
            step: step,
            onMenuTap: onMenuTap ?? () => _comingSoon(context),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      _kWavesAsset,
                      fit: _kWavesFit,
                      alignment: _kWavesAlignment,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                Positioned.fill(child: child),
              ],
            ),
          ),
          _BottomNavigation(
            selectedIndex: selectedIndex,
            onTap: onDestinationSelected,
          ),
        ],
      ),
    );
  }

  static void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Le menu sera bientôt disponible.')),
      );
  }
}

/// Corps standard : contenu en haut, action principale ancrée en bas
/// (comme le Figma), défilement automatique sur les petits écrans.
class AtlartCandidatureBody extends StatelessWidget {
  const AtlartCandidatureBody({
    super.key,
    required this.children,
    required this.footer,
  });

  final List<Widget> children;
  final Widget footer;

  static const double _bottomPadding = 20;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AtlartLayout.pageHPadding,
          0,
          AtlartLayout.pageHPadding,
          _bottomPadding,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, c.maxHeight - _bottomPadding),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 34),
                ...children,
                const Spacer(),
                const SizedBox(height: 24),
                footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.onMenuTap});

  final int step;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    // Le dégradé passe sous la barre d'état (plus de bande grise en haut).
    final top = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB4D5F2), Color(0xFFE6F1FB), Colors.white],
          stops: [0.0, 0.65, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, top + 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 28,
              child: Image.asset(
                AtlartAssets.logoHorizontal,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(
                  'ATLART',
                  style: TextStyle(
                    color: AtlartPalette.blueText,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Candidature',
                    style: TextStyle(
                      color: AtlartPalette.blueText,
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      shadowColor: const Color(0x33000000),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onMenuTap,
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            Icons.menu,
                            size: 20,
                            color: AtlartPalette.blueText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 1; i <= 3; i++) ...[
                  if (i > 1) const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: i <= step ? _kStepOn : _kStepOff,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int>? onTap;

  static const items = [
    (Icons.search_outlined, 'Découvrir'),
    (Icons.chat_bubble_outline, 'Messagerie'),
    (Icons.favorite_border, 'Favoris'),
    (Icons.person_outline, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kNavLine)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      // Pleine largeur ; SafeArea garde les icônes au-dessus de la barre système.
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (int index = 0; index < items.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (onTap != null) {
                        onTap!(index);
                      } else {
                        navigateToTab(context, index);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[index].$1,
                          size: 22,
                          color: index == selectedIndex
                              ? AtlartPalette.coral
                              : AtlartPalette.blueText,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[index].$2,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: index == selectedIndex
                                ? AtlartPalette.coral
                                : AtlartPalette.blueText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}