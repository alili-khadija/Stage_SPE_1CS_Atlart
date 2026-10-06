import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_session.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onTabSelected});

  final ValueChanged<int>? onTabSelected;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String get _name {
    final name = AtlartSession.firstName.trim();
    return name.isEmpty ? 'Mon compte' : name;
  }

  String get _subtitle {
    final user = AtlartSession.instance.user;
    if (user == null) return 'Compte Atlart';

    final role = switch (user.role) {
      'artisan' => 'Artisan',
      'artiste' => 'Artiste',
      'visiteur' => 'Visiteur',
      _ => user.role,
    };
    final location = [
      user.ville,
      user.paysCode,
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    return location.isEmpty ? role : '$role · $location';
  }

  bool _push = true;
  bool _email = false;
  bool _sms = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
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
      if (mounted) _showMessage('La déconnexion locale a échoué. Réessayez.');
    }
  }

  void _handleTabSelected(int index) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/search');
        return;
      case 1:
        Navigator.of(context).pushNamed('/messages');
        return;
      case 2:
        Navigator.of(context).pushReplacementNamed('/favorites');
        return;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _SettingsBottomNav(
        currentIndex: 3,
        onTap: _handleTabSelected,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB4D2F3), Colors.white, Colors.white],
            stops: [0, 0.2, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _SettingsHeader(title: 'Paramètres'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                  children: [
                    _ProfileCard(
                      name: _name,
                      subtitle: _subtitle,
                      onEdit: () => _showMessage('Modification du profil'),
                    ),
                    const _SectionTitle('Compte'),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          label: 'Modifier le profil',
                          onTap: () => _showMessage('Modification du profil'),
                        ),
                        _SettingsTile(
                          label: 'Changer le mot de passe',
                          onTap: () =>
                              _showMessage('Changement du mot de passe'),
                        ),
                        _SettingsTile(
                          label: "Vérification d'identité",
                          trailing: const _VerifiedBadge(),
                          onTap: () => _showMessage("Vérification d'identité"),
                        ),
                        _SettingsTile(
                          label: 'Méthodes de paiement',
                          onTap: () => _showMessage('Méthodes de paiement'),
                        ),
                        _SettingsTile(
                          label: 'Utilisateurs bloqués',
                          onTap: () => _showMessage('Utilisateurs bloqués'),
                        ),
                      ],
                    ),
                    const _SectionTitle('Notifications'),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          label: 'Notifications push',
                          trailing: _CoralSwitch(
                            value: _push,
                            onChanged: (value) {
                              setState(() => _push = value);
                            },
                          ),
                        ),
                        _SettingsTile(
                          label: 'Notifications par e-mail',
                          trailing: _CoralSwitch(
                            value: _email,
                            onChanged: (value) {
                              setState(() => _email = value);
                            },
                          ),
                        ),
                        _SettingsTile(
                          label: 'Notifications SMS',
                          trailing: _CoralSwitch(
                            value: _sms,
                            onChanged: (value) {
                              setState(() => _sms = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const _SectionTitle('Confidentialité'),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          label: 'Qui peut me contacter',
                          value: 'Tout le monde',
                          onTap: () => _showMessage('Qui peut me contacter'),
                        ),
                        _SettingsTile(
                          label: 'Visibilité du profil',
                          value: 'Public',
                          onTap: () => _showMessage('Visibilité du profil'),
                        ),
                        _SettingsTile(
                          label: 'Langue',
                          value: 'Français',
                          onTap: () => _showMessage('Choix de la langue'),
                        ),
                      ],
                    ),
                    const _SectionTitle('Assistance'),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          label: "Centre d'aide",
                          onTap: () => _showMessage("Centre d'aide"),
                        ),
                      ],
                    ),
                    const _SectionTitle('Session'),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(label: 'Se déconnecter', onTap: _logout),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left, color: Color(0xFF4A6FA5)),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A6FA5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.onEdit,
  });

  final String name;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _settingsCardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFFF87171),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF8A94A6),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Modifier',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: const Color(0xFF8FA0BA),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _settingsCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 14,
                  endIndent: 14,
                  color: Color(0xFFF0F3F8),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final endWidget =
        trailing ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Text(
                value!,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF8A94A6),
                ),
              ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF8A94A6)),
          ],
        );

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2F46),
                  ),
                ),
              ),
              endWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD9F5E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Vérifié',
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2E9E6B),
        ),
      ),
    );
  }
}

class _CoralSwitch extends StatelessWidget {
  const _CoralSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.78,
      child: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFFF87171),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFE3E8F0),
      ),
    );
  }
}

BoxDecoration _settingsCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF3B5B8C).withValues(alpha: 0.10),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _SettingsBottomNav extends StatelessWidget {
  const _SettingsBottomNav({required this.currentIndex, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  static const _icons = [
    Icons.search,
    Icons.explore_outlined,
    Icons.favorite_border,
    Icons.person_outline,
  ];

  static const _labels = ['Découvrir', 'Messagerie', 'Favoris', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < _labels.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap?.call(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _icons[i],
                          size: 20,
                          color: i == currentIndex
                              ? const Color(0xFFF87171)
                              : const Color(0xFF5B7DB1),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _labels[i],
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: i == currentIndex
                                ? const Color(0xFFF87171)
                                : const Color(0xFF5B7DB1),
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
