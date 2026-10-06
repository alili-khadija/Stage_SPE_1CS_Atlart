import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';

export 'atlart_search_widgets.dart' show AtlartBottomNav;

class ProfilePalette {
  static const sky = Color(0xFFB9DDF7);
  static const verified = Color(0xFF36B77A);
  static const verifiedBg = Color(0xFFDDF5E9);
}

class ProfileWork {
  const ProfileWork({
    required this.title,
    required this.rating,
    required this.color,
    this.imageAsset,
  });

  final String title;
  final int rating;
  final Color color;
  final String? imageAsset;
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        border: Border.all(color: const Color(0xFFD3E3F2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AtlartPalette.blueText),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AtlartPalette.blueText,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    required this.radius,
    this.gradient,
  });

  final String name;
  final double radius;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEFA578),
      foregroundColor: Colors.white,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 19, color: AtlartPalette.blueText),
        ),
      ),
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.stats});

  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14273A56),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      stats[i].$1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AtlartPalette.navyDark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      stats[i].$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AtlartPalette.blueTextLight,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: filled ? AtlartPalette.coral : Colors.white,
          foregroundColor: filled ? Colors.white : AtlartPalette.navyDark,
          side: BorderSide(
            color: filled ? AtlartPalette.coral : const Color(0xFFD3E3F2),
          ),
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AtlartPalette.navyDark,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class SeeAllLink extends StatelessWidget {
  const SeeAllLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Voir tout',
            style: TextStyle(
              color: AtlartPalette.coral,
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSubPageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const ProfileSubPageHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      backgroundColor: const Color(0xFFEAF2FB),
      foregroundColor: AtlartPalette.navyDark,
      elevation: 0,
      actions: action == null ? null : [action!],
    );
  }
}
