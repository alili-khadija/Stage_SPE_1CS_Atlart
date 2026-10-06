import 'dart:io';

import 'package:flutter/material.dart';

import '../screens/favoris_screen.dart' show FavoritesScreen;
import '../screens/messages_screen.dart' show MessagesScreen;
import '../screens/search_screen.dart' show SearchScreen;
import '../theme/atlart_ui_theme.dart';
import 'offers_ui.dart' show offersLogoAsset;
import 'profile_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────
//  Kit commun des profils : membre (ProfileScreen), artiste / artisan vu par
//  les autres (ArtistProfileScreen) et profil artisan (ArtisanProfileScreen)
//  partagent EXACTEMENT la même structure :
//
//    en-tête dégradé (retour · « Profil » · action)
//      └ avatar + nom + sous-titre
//      └ carte de statistiques blanche
//    corps blanc : bio → pastilles → boutons → sections (grille / liste)
//    barre du bas
// ─────────────────────────────────────────────────────────────────────────

const _kLine = Color(0xFFD3E3F2);
const _kSoft = Color(0xFFF4F8FC);
const _kShadow = BoxShadow(
  color: Color(0x14273A56),
  blurRadius: 10,
  offset: Offset(0, 3),
);

/// Barre du bas des profils (même comportement partout).
void profileHandleNav(BuildContext context, int index, int current) {
  if (index == current) {
    // Onglet déjà actif : sur un profil consulté, on revient en arrière.
    if (current != 3) Navigator.of(context).maybePop();
    return;
  }
  switch (index) {
    case 0:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
      );
    case 1:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MessagesScreen()),
      );
    case 2:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
      );
    case 3:
      Navigator.of(context).pushNamed('/profile');
  }
}

// ───────────────────────── Structure ─────────────────────────

class ProfileScaffold extends StatelessWidget {
  const ProfileScaffold({
    super.key,
    required this.name,
    required this.subtitle,
    required this.stats,
    required this.children,
    this.verified = false,
    this.trailing,
    this.onMenuTap,
    this.navIndex = 3,
    this.onNavTap,
  });

  final String name;
  final String subtitle;
  final List<(String, String)> stats;
  final bool verified;

  /// Bouton rond à droite du logo (remplace le menu « ••• »).
  final Widget? trailing;

  /// Raccourci : affiche le bouton « ••• » et appelle ce callback.
  final VoidCallback? onMenuTap;

  /// Contenu du corps (sous la carte de statistiques).
  final List<Widget> children;

  final int navIndex;
  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _ProfileHeader(
            name: name,
            subtitle: subtitle,
            stats: stats,
            verified: verified,
            trailing: trailing ??
                (onMenuTap == null
                    ? null
                    : ProfileRoundButton(
                        icon: Icons.more_horiz,
                        tooltip: 'Menu du profil',
                        onTap: onMenuTap!,
                      )),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: children,
            ),
          ),
        ],
      ),
      bottomNavigationBar: AtlartBottomNav(
        currentIndex: navIndex,
        onTap: onNavTap ?? (i) => profileHandleNav(context, i, navIndex),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.subtitle,
    required this.stats,
    required this.verified,
    required this.trailing,
  });

  final String name;
  final String subtitle;
  final List<(String, String)> stats;
  final bool verified;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final canBack = Navigator.of(context).canPop();

    return Container(
      padding: EdgeInsets.fromLTRB(18, top + 8, 18, 16),
      // Même dégradé bleu que Accueil, Favoris et les écrans d'offres.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9CC6EE), Color(0xFFD9EAF9), Color(0xFFEEF5FD)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Logo centré, retour à gauche, menu à droite (comme Accueil).
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 32,
                  child: Image.asset(
                    offersLogoAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        'ATLART',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 3,
                          color: Color(0xFF5B7BA8),
                        ),
                      ),
                    ),
                  ),
                ),
                if (canBack)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ProfileRoundButton(
                      icon: Icons.chevron_left,
                      tooltip: 'Retour',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                if (trailing != null)
                  Align(alignment: Alignment.centerRight, child: trailing),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Profil',
            style: TextStyle(
              color: Color(0xFF5B7BA8),
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              InitialsAvatar(name: name, radius: 32),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: AtlartPalette.navy,
                            ),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified,
                            size: 15,
                            color: ProfilePalette.verified,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AtlartPalette.blueText,
                        fontFamily: 'Poppins',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [_kShadow],
            ),
            child: Row(
              children: [
                for (final (value, label) in stats)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            color: AtlartPalette.navyDark,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AtlartPalette.blueTextLight,
                            fontFamily: 'Poppins',
                            fontSize: 8.5,
                          ),
                        ),
                      ],
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

// ───────────────────────── Boutons ─────────────────────────

class ProfileRoundButton extends StatelessWidget {
  const ProfileRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 19, color: AtlartPalette.blueText),
          ),
        ),
      ),
    );
  }
}

/// Bouton pleine largeur : corail plein (`filled`) ou contour bleu clair.
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 6)],
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AtlartPalette.coral,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AtlartPalette.coral.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: content,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AtlartPalette.navyDark,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _kLine),
                shape: const StadiumBorder(),
              ),
              child: content,
            ),
    );
  }
}

class ProfileSocialButton extends StatelessWidget {
  const ProfileSocialButton({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 15, color: AtlartPalette.blueText),
        ),
      ),
    );
  }
}

// ───────────────────────── Texte & pastilles ─────────────────────────

class ProfileBio extends StatelessWidget {
  const ProfileBio(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AtlartPalette.navy,
          fontFamily: 'Poppins',
          fontSize: 11.5,
          height: 1.6,
        ),
      );
}

class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.label,
    this.icon = Icons.circle,
    this.verified = false,
  });

  final String label;
  final IconData icon;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? const Color(0xFF2A9D70) : AtlartPalette.blueText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: verified ? const Color(0xFFE3F6EB) : _kSoft,
        border: Border.all(
          color: verified ? const Color(0xFFC8EBD6) : _kLine,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontFamily: 'Poppins',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Sections ─────────────────────────

/// Titre de section + action optionnelle en pastille corail.
class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AtlartPalette.navyDark,
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (onAction != null && actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AtlartPalette.coral,
              backgroundColor: const Color(0xFFFFF2F1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
            ),
            icon: Icon(actionIcon ?? Icons.arrow_forward_rounded, size: 14),
            label: Text(
              actionLabel!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class ProfileEmptyHint extends StatelessWidget {
  const ProfileEmptyHint(this.text, {super.key, this.icon = Icons.image_outlined});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: _kSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: AtlartPalette.blueTextLight),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AtlartPalette.blueTextLight,
              fontFamily: 'Poppins',
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de menu (« Mes achats », « Paramètres »…).
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [_kShadow],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _kSoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 16, color: AtlartPalette.blueText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AtlartPalette.navyDark,
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AtlartPalette.blueTextLight,
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

// ───────────────────────── Grille d'articles / œuvres ─────────────────────────

/// Deux colonnes, mêmes marges pour les œuvres et les articles.
class ProfileGrid extends StatelessWidget {
  const ProfileGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = (c.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 16,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Tuile unique pour une œuvre OU un article : visuel carré + cœur, titre,
/// étoiles, et (si fournis) prix et mention de stock.
class ProfileItemTile extends StatelessWidget {
  const ProfileItemTile({
    super.key,
    required this.title,
    required this.liked,
    required this.onLike,
    this.color = const Color(0xFFDCEBF9),
    this.icon = Icons.image_outlined,
    this.imageAsset,
    this.imagePath,
    this.rating,
    this.price,
    this.caption,
    this.onTap,
  });

  final String title;
  final bool liked;
  final VoidCallback onLike;
  final Color color;
  final IconData icon;
  final String? imageAsset;
  final String? imagePath;
  final double? rating;
  final String? price;
  final String? caption;
  final VoidCallback? onTap;

  Widget _placeholder() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.55), color],
          ),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.75), size: 34),
      );

  Widget _visual() {
    if (imagePath != null) {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (imageAsset != null) {
      return Image.asset(
        imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  @override
  Widget build(BuildContext context) {
    final r = rating;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [_kShadow],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _visual(),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Tooltip(
                        message: liked
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onLike,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Icon(
                                liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 13,
                                color: AtlartPalette.coral,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AtlartPalette.navyDark,
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (r != null && r > 0) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Icon(
                    r >= i + 1
                        ? Icons.star_rounded
                        : (r >= i + 0.5
                            ? Icons.star_half_rounded
                            : Icons.star_border_rounded),
                    size: 11,
                    color: const Color(0xFFE3B34C),
                  ),
              ],
            ),
          ],
          if (price != null) ...[
            const SizedBox(height: 4),
            Text(
              price!,
              style: const TextStyle(
                color: AtlartPalette.coral,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 11,
                  color: AtlartPalette.blueTextLight,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AtlartPalette.blueTextLight,
                      fontFamily: 'Poppins',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}