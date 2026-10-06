import 'package:flutter/material.dart';

/// Chemins des images à exporter depuis Figma (voir instructions).
class AtlartAssets {
  AtlartAssets._();

  /// L'oiseau / papillon en traits fins (écran login).
  static const logo = 'assets/images/logo_atlart.png';

  /// Logo horizontal (oiseau + "ATLART") du bandeau haut des écrans rôle.
  static const logoHorizontal = 'assets/images/atlart_logo_horizontal.png';

  /// Montagnes estompées derrière le titre et les champs du login.
  static const mountains = 'assets/images/atlart_mountains.png';
}

/// Couleurs mesurées directement sur les maquettes Figma.
class AtlartPalette {
  AtlartPalette._();

  // Fonds / dégradés
  static const skyLight = Color(0xFFC2DFF7);
  static const skyHeader = Color(0xFFA6D0F3);
  static const skyBottom = Color(0xFFC4E0F7);
  static const formTop = Color(0xFFF7FBFE);

  // Champs et cartes
  static const inputFill = Color(0xFFD5ECFF);
  static const cardFill = Color(
    0xFFEBF5FD,
  ); // opaque : sinon l'ombre transparaît
  static const infoBox = Color(0xFFC9DCF3);
  static const tileBeige = Color(0xFFEDE9DA);

  // Textes
  static const navy = Color(0xFF16324A);
  static const navyDark = Color(0xFF1F3D5C);
  static const blueText = Color(0xFF5975A2);
  static const blueTextSoft = Color(0xFF4A6685);
  static const blueTextLight = Color(0xFF8496AE);
  static const hint = Color(0xFF9A998F);

  // Bouton
  static const coral = Color(0xFFFF7A7A); // actif
  static const coralSoft = Color(0xFFFFA2A2); // désactivé
  static const onCoral = Color(0xFFF2EDDD);

  // Erreur
  static const error = Color(0xFFE86B69);
  static const errorBorder = Color(0xFFF28B8B);
  static const errorBg = Color(0xFFFDECEB);

  static const success = Color(0xFF2A9D8F);

  // Dégradés de fond
  /// Login : bleu ciel en haut → blanc vers le bas.
  static const loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyLight, skyLight, Colors.white],
    stops: [0.0, 0.12, 0.62],
  );

  /// Choix du rôle : fine bande bleue en haut, blanc, puis bleu clair en bas.
  static const roleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyHeader, Colors.white, Colors.white, skyLight],
    stops: [0.0, 0.07, 0.21, 1.0],
  );

  /// Bienvenue / nouveau mot de passe : bande bleue en haut, puis
  /// quasi blanc -> bleu clair de façon linéaire.
  static const welcomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyHeader, Color(0xFFE0EFFB), Color(0xFFF4F9FD), skyLight],
    stops: [0.0, 0.05, 0.10, 1.0],
  );

  /// Inscription / mot de passe oublié : quasi blanc → bleu clair.
  static const formGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [formTop, skyBottom],
  );
}

class AtlartShadows {
  AtlartShadows._();

  static const field = BoxShadow(
    color: Color(0x267FA8D8),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
  static const loginFocus = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
  static const button = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 6,
    offset: Offset(0, 4),
  );
  static const card = BoxShadow(
    color: Color(0x2E000000),
    blurRadius: 8,
    offset: Offset(3, 4),
  );
  static const tile = BoxShadow(
    color: Color(0x407FA8D8),
    blurRadius: 6,
    offset: Offset(0, 3),
  );
  static const back = BoxShadow(
    color: Color(0x337FA8D8),
    blurRadius: 8,
    offset: Offset(0, 3),
  );
}

class AtlartInteractionStyles {
  AtlartInteractionStyles._();

  static WidgetStateProperty<Color?> get overlay =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        if (states.contains(WidgetState.pressed)) {
          return AtlartPalette.coral.withValues(alpha: 0.18);
        }
        if (states.contains(WidgetState.focused)) {
          return AtlartPalette.blueText.withValues(alpha: 0.16);
        }
        if (states.contains(WidgetState.hovered)) {
          return AtlartPalette.blueText.withValues(alpha: 0.12);
        }
        return null;
      });

  static const duration = Duration(milliseconds: 140);
}

class AtlartType {
  AtlartType._();

  // ---- Login
  static const logo = TextStyle(
    color: AtlartPalette.blueText,
    fontSize: 36,
    height: 1.2,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
  );

  static const tagline = TextStyle(
    color: AtlartPalette.blueText,
    fontSize: 19,
    height: 1.4,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w300,
  );

  // ---- Titres
  static const title = TextStyle(
    color: AtlartPalette.navy,
    fontSize: 22,
    height: 1.5,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
  );

  static const roleTitle = TextStyle(
    color: AtlartPalette.navyDark,
    fontSize: 16,
    height: 1.5,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
  );

  static const roleSubtitle = TextStyle(
    color: AtlartPalette.blueTextSoft,
    fontSize: 11.5,
    height: 1.4,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w300,
  );

  static const subtitle = TextStyle(
    color: AtlartPalette.blueTextSoft,
    fontSize: 11,
    height: 1.5,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
  );

  /// Sous-titre foncé (écran nouveau mot de passe).
  static const subtitleStrong = TextStyle(
    color: AtlartPalette.navyDark,
    fontSize: 11.5,
    height: 1.5,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
  );

  // ---- Champs
  static const fieldLabel = TextStyle(
    color: AtlartPalette.blueTextLight,
    fontSize: 9,
    height: 1.2,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
  );

  static const fieldValue = TextStyle(
    color: AtlartPalette.navy,
    fontSize: 13,
    height: 1.25,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
  );

  static const fieldHint = TextStyle(
    color: Color(0xFF7E93B0),
    fontSize: 12,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
  );

  /// Placeholder en majuscules des champs du login ("USERNAME").
  static const placeholder = TextStyle(
    color: AtlartPalette.hint,
    fontSize: 9.5,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
  );

  // ---- Cartes de rôle
  static const cardTitle = TextStyle(
    color: AtlartPalette.navyDark,
    fontSize: 11,
    height: 1.4,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
  );

  static const cardDesc = TextStyle(
    color: Color(0xFF768CAB),
    fontSize: 9,
    height: 1.4,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w300,
  );

  static const infoText = TextStyle(
    color: AtlartPalette.blueTextSoft,
    fontSize: 8.5,
    height: 1.5,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
  );

  // ---- Boutons / messages
  static const buttonLabel = TextStyle(
    color: AtlartPalette.onCoral,
    fontSize: 12,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
  );

  // ---- Bienvenue
  static const welcomeTitle = TextStyle(
    color: AtlartPalette.navyDark,
    fontSize: 20,
    height: 1.5,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
  );

  static const welcomeSubtitle = TextStyle(
    color: AtlartPalette.blueTextSoft,
    fontSize: 11,
    height: 1.65,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w300,
  );

  static const stepsLabel = TextStyle(
    color: AtlartPalette.navyDark,
    fontSize: 11,
    height: 1.5,
    letterSpacing: 1,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
  );

  static const stepTitle = TextStyle(
    color: AtlartPalette.navyDark,
    fontSize: 11.5,
    height: 1.5,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
  );

  static const stepSubtitle = TextStyle(
    color: Color(0xFF6F84A0),
    fontSize: 10.5,
    height: 1.5,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
  );

  static const errorText = TextStyle(
    color: AtlartPalette.error,
    fontSize: 10,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
  );

  static const link = TextStyle(
    color: AtlartPalette.navyDark,
    fontSize: 11,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
  );
}

/// Conteneur commun : colonne de 390 px max (largeur des maquettes Figma),
/// pleine hauteur d'écran, dégradé de fond, contenu scrollable si l'écran
/// est trop petit (ou quand le clavier s'ouvre).
class AtlartPage extends StatelessWidget {
  const AtlartPage({
    super.key,
    required this.child,
    this.gradient = AtlartPalette.formGradient,
    this.showBack = false,
  });

  final Widget child;
  final Gradient gradient;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final backTop = topInset + 8 > 34 ? topInset + 8 : 34.0;

    return Scaffold(
      backgroundColor: AtlartPalette.skyLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: gradient),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, c) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: c.maxHeight),
                          child: IntrinsicHeight(child: child),
                        ),
                      ),
                    ),
                  ),
                  if (showBack)
                    Positioned(
                      top: backTop,
                      left: 31,
                      child: const AtlartBack(),
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

/// Pastille ronde blanche avec chevron (haut gauche des écrans formulaire).
class AtlartBack extends StatelessWidget {
  const AtlartBack({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [AtlartShadows.back],
      ),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 33,
            height: 33,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 11,
              color: AtlartPalette.navy,
            ),
          ),
        ),
      ),
    );
  }
}
