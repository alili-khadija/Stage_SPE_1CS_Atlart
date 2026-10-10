import 'package:flutter/material.dart';

import '../app_session.dart';
import '../services/auth_api.dart';
import '../services/follow_api.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/profile_kit.dart';
import '../widgets/profile_shared_widgets.dart';
import 'blocked_accounts_screen.dart';
import 'career_screen.dart';
import 'create_publication_flow.dart';
import 'edit_profile_screen.dart';
import 'published_works_screen.dart';
import '../widgets/favorite_action_button.dart';

/// Page "Profile" pour un artiste ou artisan.
/// [isMe] indique si le profil appartient à la personne connectée.
class ArtistProfileScreen extends StatelessWidget {
  const ArtistProfileScreen({
    super.key,
    required this.name,
    required this.role,
    required this.city,
    required this.bio,
    required this.stats,
    required this.tags,
    required this.works,
    this.careerPreview,
    this.isMe = true,
    this.isVerified = true,
    this.isFollowing = false,
    this.favoriteId,
  });

  final String name;
  final String role;
  final String city;
  final String bio;
  final List<(String, String)> stats;
  final List<TagChip> tags;
  final List<ProfileWork> works;
  final String? careerPreview;
  final bool isMe;
  final bool isVerified;
  final bool isFollowing;
  final String? favoriteId;

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileMenuSheet(
        onLogout: () => _logout(context),
        onBlocked: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BlockedAccountsScreen(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez vous reconnecter pour accéder à votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AtlartSession.instance.logout();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'logout',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La déconnexion locale a échoué.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      name: name,
      subtitle: '$role · $city',
      verified: isVerified,
      onMenuTap: isMe ? () => _openMenu(context) : null,
      trailing: isMe
          ? null
          : FavoriteActionButton(
              entityType: 'UTILISATEUR',
              entityId: favoriteId,
            ),
      stats: stats,
      children: [
        ProfileBio(bio),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: tags),
        if (isMe && role.toLowerCase() == 'artiste') ...[
          const SizedBox(height: 18),
          ProfileActionButton(
            label: 'Publier une œuvre',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CreatePublicationFlow(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (isMe)
          ProfileActionButton(
            label: 'Modifier le profil',
            onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditProfileScreen(
                      initialName: name,
                      initialBio: bio,
                      initialLocation: city,
                    ),
                  ),
                ),
          )
        else
          _FollowProfileActionButton(
            userId: favoriteId,
            initialFollowing: isFollowing,
          ),
        const SizedBox(height: 26),
        ProfileSectionHeader(
          'ŒUVRES PUBLIÉES',
          actionLabel: 'Voir tout',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PublishedWorksScreen(works: works),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _WorksGrid(works: works.take(6).toList()),
        if (careerPreview != null) ...[
          const SizedBox(height: 22),
          const ProfileSectionHeader('PARCOURS'),
          const SizedBox(height: 8),
          ProfileMenuTile(
            icon: Icons.work_history_outlined,
            label: careerPreview!,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CareerScreen()),
            ),
          ),
        ],
      ],
    );
  }
}

class _FollowProfileActionButton extends StatefulWidget {
  const _FollowProfileActionButton({
    required this.userId,
    required this.initialFollowing,
  });

  final String? userId;
  final bool initialFollowing;

  @override
  State<_FollowProfileActionButton> createState() =>
      _FollowProfileActionButtonState();
}

class _FollowProfileActionButtonState extends State<_FollowProfileActionButton> {
  late bool _following = widget.initialFollowing;
  bool _busy = false;

  Future<void> _toggle() async {
    final userId = widget.userId;
    if (userId == null) {
      _showMessage('Ce profil de démonstration n’est pas relié au catalogue.');
      return;
    }
    final token = AtlartSession.instance.token;
    if (!AuthApi.useBackend || token == null) {
      _showMessage('Connectez-vous pour suivre ce profil.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final following = await FollowApi.setFollowing(
        token: token,
        userId: userId,
        follow: !_following,
      );
      if (mounted) setState(() => _following = following);
    } on FollowApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => ProfileActionButton(
        label: _busy ? 'Patientez…' : (_following ? 'Suivi(e)' : 'Suivre'),
        icon: _following ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
        filled: !_following,
        onPressed: _busy ? null : _toggle,
      );
}

class _WorksGrid extends StatefulWidget {
  const _WorksGrid({required this.works});

  final List<ProfileWork> works;

  @override
  State<_WorksGrid> createState() => _WorksGridState();
}

class _WorksGridState extends State<_WorksGrid> {
  final Set<int> _favs = {};

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.works.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, i) {
        final work = widget.works[i];
        final isFavorite = _favs.contains(i);

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              work.imageAsset == null
                  ? Container(color: work.color)
                  : Image.asset(
                      work.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: work.color),
                    ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.white70,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() {
                        if (isFavorite) {
                          _favs.remove(i);
                        } else {
                          _favs.add(i);
                        }
                      });
                    },
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 12,
                        color: AtlartPalette.coral,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(7, 14, 7, 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xBF0F1928)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        work.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (star) => Icon(
                            star < work.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 8,
                            color: const Color(0xFFF0C53C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet({required this.onBlocked, required this.onLogout});

  final VoidCallback onBlocked;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.school_rounded,
                color: AtlartPalette.blueText,
              ),
              title: const Text(
                'Parcours & formation',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CareerScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.block_rounded,
                color: AtlartPalette.blueText,
              ),
              title: const Text(
                'Comptes bloqués',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onBlocked();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
