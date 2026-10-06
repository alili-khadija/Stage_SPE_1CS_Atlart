import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';

/// Bandeau haut réutilisable (logo, notifications, menu, titre de page).
class AtlartTopBar extends StatelessWidget {
  const AtlartTopBar({
    super.key,
    required this.title,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onMenuTap,
    this.leading,
    this.trailing,
  });

  final String title;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AtlartPalette.skyHeader, Colors.white],
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child:
                      leading ??
                      _RoundIconButton(
                        icon: Icons.notifications_none_rounded,
                        badgeCount: notificationCount,
                        onTap: onNotificationTap,
                      ),
                ),
                Image.asset(
                  AtlartAssets.logoHorizontal,
                  height: 22,
                  errorBuilder: (_, _, _) => const Text(
                    'ATLART',
                    style: TextStyle(
                      color: AtlartPalette.blueText,
                      fontSize: 14,
                      letterSpacing: 0.8,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child:
                      trailing ??
                      _RoundIconButton(
                        icon: Icons.menu_rounded,
                        onTap: onMenuTap,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: AtlartType.title),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.badgeCount = 0, this.onTap});

  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: icon == Icons.notifications_none_rounded
          ? 'Notifications'
          : 'Ouvrir le menu',
      child: Container(
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
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const SizedBox(width: 36, height: 36),
                Positioned.fill(
                  child: Icon(icon, size: 18, color: AtlartPalette.navy),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: AtlartPalette.coral,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre de recherche blanche + bouton filtre corail.
/// Si [controller] est null, affiche un simple placeholder statique
/// (pratique quand le champ n'est pas encore éditable sur cet écran).
class AtlartSearchField extends StatelessWidget {
  const AtlartSearchField({
    super.key,
    this.controller,
    this.hint = "Artiste, Œuvre, artisanat...",
    this.onTap,
    this.onFilterTap,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [AtlartShadows.field],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller == null ? onTap : null,
                borderRadius: BorderRadius.circular(22),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 18,
                      color: AtlartPalette.blueTextLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: controller == null
                          ? Text(hint, style: AtlartType.fieldHint)
                          : TextField(
                              controller: controller,
                              autofocus: autofocus,
                              style: AtlartType.fieldValue,
                              cursorColor: AtlartPalette.blueText,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: hint,
                                hintStyle: AtlartType.fieldHint,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AtlartPalette.coral,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onFilterTap,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.tune_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ligne de chips horizontale générique (catégories, pays, etc.).
class AtlartChipsRow extends StatelessWidget {
  const AtlartChipsRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 34,
    this.selectedColor = AtlartPalette.navyDark,
    this.fontSize = 11.5,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;
  final Color selectedColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected ? selectedColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: selected ? null : const [AtlartShadows.field],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AtlartPalette.blueTextSoft,
                        fontSize: fontSize,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AtlartNavItem {
  const AtlartNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Barre de navigation basse réutilisable (Découvrir/Messagerie/Favoris/Profil).
class AtlartBottomNav extends StatelessWidget {
  const AtlartBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = <AtlartNavItem>[
    AtlartNavItem(Icons.search_rounded, "Découvrir"),
    AtlartNavItem(Icons.chat_bubble_outline_rounded, "Messagerie"),
    AtlartNavItem(Icons.favorite_border_rounded, "Favoris"),
    AtlartNavItem(Icons.person_outline_rounded, "Profil"),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEDF2F7))),
        ),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 42,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[i].icon,
                            size: 20,
                            color: i == currentIndex
                                ? AtlartPalette.coral
                                : AtlartPalette.blueTextLight,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i].label,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: i == currentIndex
                                  ? AtlartPalette.coral
                                  : AtlartPalette.blueTextLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
