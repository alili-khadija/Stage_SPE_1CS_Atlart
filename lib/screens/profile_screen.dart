import 'package:flutter/material.dart';

import '../app_session.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/profile_kit.dart';
import 'edit_profile_screen.dart';
import 'role_selection_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = AtlartSession.firstName.trim().isEmpty
        ? 'Mon compte'
        : AtlartSession.firstName.trim();
    final user = AtlartSession.instance.user;
    final location = [
      user?.ville,
      user?.paysCode,
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');

    return ProfileScaffold(
      name: name,
      subtitle: location.isEmpty
          ? 'Membre Atlart'
          : 'Membre Atlart · $location',
      stats: const [
        ('58', 'Abonnements'),
        ('34', 'Abonnés'),
        ('12', 'Favoris'),
      ],
      children: [
        ProfileActionButton(
          label: 'Modifier le profil',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditProfileScreen(
                initialName: name,
                initialLocation: location,
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        const ProfileSectionHeader('MON ACTIVITÉ'),
        const SizedBox(height: 10),
        const ProfileMenuTile(
          icon: Icons.shopping_bag_outlined,
          label: 'Mes achats',
        ),
        const ProfileMenuTile(
          icon: Icons.event_outlined,
          label: 'Mes réservations',
        ),
        const ProfileMenuTile(
          icon: Icons.local_offer_outlined,
          label: 'Mes offres',
        ),
        ProfileMenuTile(
          icon: Icons.favorite_border_rounded,
          label: 'Favoris',
          onTap: () => Navigator.of(context).pushReplacementNamed('/favorites'),
        ),
        ProfileMenuTile(
          icon: Icons.settings_outlined,
          label: 'Paramètres',
          onTap: () => Navigator.of(context).pushNamed('/settings'),
        ),
        const SizedBox(height: 8),
        _BecomeArtistCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const RoleSelectionScreen.forCandidature(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BecomeArtistCard extends StatelessWidget {
  const _BecomeArtistCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFEDEC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Devenir artiste ou artisan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: AtlartPalette.navyDark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Faites vérifier votre profil pour publier vos œuvres.',
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.5,
                        color: AtlartPalette.navyDark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: AtlartPalette.coral),
            ],
          ),
        ),
      ),
    );
  }
}
