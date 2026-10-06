import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Screens/favoris_screen.dart' show FavoritesScreen;
import '../models/offer_status.dart';
import '../theme/atlart_ui_theme.dart' show AtlartAssets;
import 'atlart_search_widgets.dart' show AtlartBottomNav;

// ─────────────────────────────────────────────────────────────────────────
//  Kit UI des écrans « Acheteur » (offres) — une seule source pour les
//  couleurs, polices, fond, en-tête, boutons et cartes de la maquette.
//  Utilisé par : OfferCreateScreen, OfferNegotiationScreen,
//  OfferAcceptedScreen (et réutilisable dans MyOffersScreen).
// ─────────────────────────────────────────────────────────────────────────

/// Adaptez le chemin au logo de votre projet. S'il est introuvable,
/// le texte « ATLART » s'affiche à la place.
const offersLogoAsset = 'assets/images/atlart_logo_horizontal.png';

class OfferColors {
  static const navy = Color(0xFF1F3A5F);
  static const ink = Color(0xFF24394D);
  static const steel = Color(0xFF5B7BA8);
  static const slate = Color(0xFF7088B0);
  static const coral = Color(0xFFFF7478);
  static const cream = Color(0xFFFCEFD9);
  static const brown = Color(0xFF8A5A00);
  static const olive = Color(0xFF8A7A4A);
  static const field = Color(0xFFD5E8FB);
  static const line = Color(0xFFB4C8DF);
  static const muted = Color(0xFF8592A1);
  static const error = Color(0xFFE8574F);
  static const shadow = Color(0x1F273A56);
}

class OfferText {
  static TextStyle poppins(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = OfferColors.ink,
    double? height,
    double? spacing,
  }) => TextStyle(
    fontFamily: 'Poppins',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );

  /// Montants : serif (Playfair Display) comme dans Figma.
  static TextStyle serif(double size, {Color color = OfferColors.navy}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );
}

// ───────────────────────── Montants ─────────────────────────

/// "1500" -> "1 500"
String offerGroupDigits(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write(' ');
    b.write(d[i]);
  }
  return b.toString();
}

/// "1 500 MAD" / "1500" -> 1500 (montants entiers en MAD). null si vide.
int? offerParseAmount(String text) {
  final d = text.replaceAll(RegExp(r'\D'), '');
  return d.isEmpty ? null : int.tryParse(d);
}

String offerFormatMad(int amount) => '${offerGroupDigits('$amount')} MAD';

class OfferThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nw) {
    final t = offerGroupDigits(nw.text);
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

// ───────────────────────── Navigation ─────────────────────────

/// Barre du bas des écrans d'offres (mêmes destinations qu'avant).
void offersHandleNav(BuildContext context, int index) {
  final nav = Navigator.of(context);
  switch (index) {
    case 0:
      nav.pushNamedAndRemoveUntil('/search', (_) => false);
    case 1:
      nav.pushNamed('/messages');
      return;
    case 2:
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
        (_) => false,
      );
    case 3:
      nav.pushNamedAndRemoveUntil('/profile', (_) => false);
  }
}

class AtlartOffersBottomNav extends StatelessWidget {
  const AtlartOffersBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) =>
      AtlartBottomNav(currentIndex: currentIndex, onTap: onTap);
}

// ───────────────────────── Scaffold ─────────────────────────

/// Fond dégradé + en-tête (logo / titre / retour) + barre du bas optionnelle.
class OffersScaffold extends StatelessWidget {
  const OffersScaffold({
    super.key,
    required this.child,
    this.title,
    this.showLogo = true,
    this.showBack = false,
    this.showNav = true,
    this.navIndex = 3,
    this.light = false,
    this.logoAsset = offersLogoAsset,
  });

  final Widget child;
  final String? title;
  final bool showLogo;
  final bool showBack;
  final bool showNav;
  final int navIndex;
  final String logoAsset;

  /// Variante plus claire (écran « Faire une offre »).
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Backdrop(light: light),
          SafeArea(
            bottom: !showNav,
            child: Column(
              children: [
                _OffersHeader(
                  title: title,
                  showLogo: showLogo,
                  showBack: showBack,
                  logoAsset: logoAsset,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: showNav
          ? AtlartOffersBottomNav(
              currentIndex: navIndex,
              onTap: (i) {
                if (i != navIndex) offersHandleNav(context, i);
              },
            )
          : null,
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.light});
  final bool light;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: light
              ? const [
                  Color(0xFFC6DDF4),
                  Color(0xFFF4F9FE),
                  Colors.white,
                  Color(0xFFE9F3FC),
                ]
              : const [
                  Color(0xFF9CC6EE),
                  Color(0xFFD9EAF9),
                  Color(0xFFEDF5FD),
                  Color(0xFFBDD8F2),
                ],
          stops: light
              ? const [0.0, 0.16, 0.6, 1.0]
              : const [0.0, 0.14, 0.28, 1.0],
        ),
      ),
    );
  }
}

class _OffersHeader extends StatelessWidget {
  const _OffersHeader({
    required this.title,
    required this.showLogo,
    required this.showBack,
    required this.logoAsset,
  });

  final String? title;
  final bool showLogo;
  final bool showBack;
  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo)
            SizedBox(
              height: 34,
              child: Image.asset(
                logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    'ATLART',
                    style: OfferText.poppins(
                      16,
                      weight: FontWeight.w700,
                      color: OfferColors.steel,
                      spacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          if (showLogo && title != null) const SizedBox(height: 14),
          if (title != null || showBack)
            SizedBox(
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: OfferText.poppins(
                        13,
                        weight: FontWeight.w600,
                        color: OfferColors.steel,
                      ),
                    ),
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: 'Retour',
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 1.5,
                          shadowColor: OfferColors.shadow,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.chevron_left,
                                size: 20,
                                color: OfferColors.steel,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Cartes ─────────────────────────

Color _shade(Color c, double delta) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0)).toColor();
}

/// Vignette d'œuvre : dégradé dérivé de la couleur de l'offre.
class OfferThumb extends StatelessWidget {
  const OfferThumb({
    super.key,
    required this.color,
    this.size = 40,
    this.radius = 9,
  });

  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_shade(color, 0.12), _shade(color, -0.1)],
        ),
      ),
    );
  }
}

class OfferStatusChip extends StatelessWidget {
  const OfferStatusChip({super.key, required this.status});
  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status.label,
        style: OfferText.poppins(
          8,
          weight: FontWeight.w600,
          color: status.textColor,
        ),
      ),
    );
  }
}

/// Carte « œuvre » à contour bleu marine (création d'offre + négociation).
class OfferSummaryCard extends StatelessWidget {
  const OfferSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.thumbColor,
    this.priceLine,
    this.trailingAmount,
    this.trailingCaption,
    this.status,
  });

  final String title;
  final String subtitle;
  final Color thumbColor;

  /// Ligne en gras sous le sous-titre (« Prix de départ : 1 800 MAD »).
  final String? priceLine;

  /// Montant serif à droite + légende (« Il y a 2h »).
  final String? trailingAmount;
  final String? trailingCaption;

  /// Pastille qui chevauche le bas du cadre.
  final OfferStatus? status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: status == null ? 0 : 9),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(12, 12, 14, status == null ? 12 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OfferColors.steel, width: 1.1),
            ),
            child: Row(
              children: [
                OfferThumb(color: thumbColor, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OfferText.poppins(12, weight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OfferText.poppins(9, color: OfferColors.muted),
                      ),
                      if (priceLine != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          priceLine!,
                          style: OfferText.poppins(
                            9.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingAmount != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        trailingAmount!,
                        softWrap: false,
                        style: OfferText.serif(13),
                      ),
                      if (trailingCaption != null)
                        Text(
                          trailingCaption!,
                          style: OfferText.poppins(8, color: OfferColors.muted),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (status != null)
            Positioned(
              left: 14,
              bottom: -9,
              child: OfferStatusChip(status: status!),
            ),
        ],
      ),
    );
  }
}

/// Encart crème d'information.
class OfferNote extends StatelessWidget {
  const OfferNote({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OfferColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 12, color: OfferColors.brown),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: OfferText.poppins(
                9.5,
                color: OfferColors.brown,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OfferSectionLabel extends StatelessWidget {
  const OfferSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: OfferText.poppins(
      10,
      weight: FontWeight.w700,
      color: OfferColors.navy,
      spacing: 0.4,
    ),
  );
}

// ───────────────────────── Saisie de montant ─────────────────────────

/// Grand champ bleu clair, montant centré en serif (« 1 500 »).
class OfferAmountField extends StatelessWidget {
  const OfferAmountField({
    super.key,
    required this.controller,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: OfferColors.field,
            borderRadius: BorderRadius.circular(16),
            border: errorText == null
                ? null
                : Border.all(color: OfferColors.error.withValues(alpha: 0.7)),
          ),
          child: Semantics(
            label: 'Montant proposé en dirhams',
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [OfferThousandsFormatter()],
              cursorColor: OfferColors.navy,
              style: OfferText.serif(30),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '0',
                hintStyle: OfferText.serif(
                  30,
                  color: OfferColors.navy.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText!,
              textAlign: TextAlign.center,
              style: OfferText.poppins(10, color: OfferColors.error),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Boutons ─────────────────────────

/// Corail plein ; dégradé corail pâle quand désactivé (comme le reste de l'app).
class OfferPrimaryButton extends StatelessWidget {
  const OfferPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.shadow = false,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool shadow;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final solid = enabled || busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: solid ? OfferColors.coral : null,
          gradient: solid
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFFAAAA), Color(0xFFEF9CA3)],
                ),
          boxShadow: enabled && shadow
              ? const [
                  BoxShadow(
                    color: Color(0x40FF7478),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: OfferText.poppins(
                          12.5,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OfferOutlineButton extends StatelessWidget {
  const OfferOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OfferColors.navy, width: 1.1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: Center(
                child: Text(
                  label,
                  style: OfferText.poppins(
                    12,
                    weight: FontWeight.w600,
                    color: OfferColors.navy,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
