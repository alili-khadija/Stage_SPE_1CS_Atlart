import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_session.dart';
import '../services/auth_api.dart';
import '../services/notification_api.dart';
import '../widgets/atlart_search_widgets.dart' show AtlartBottomNav;

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.time,
    this.isNew = false,
  });

  final String id;
  final String type;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String time;
  bool isNew;
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.onTabSelected});

  final ValueChanged<int>? onTabSelected;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _green = Color(0xFF2DBE8B);
  static const _greenBackground = Color(0xFFD5F5EA);
  static const _orange = Color(0xFFF4A261);
  static const _orangeBackground = Color(0xFFFDE8D3);
  static const _ink = Color(0xFF1F2F46);

  final List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final token = AtlartSession.instance.token;
    if (!AuthApi.useBackend || token == null) {
      setState(() {
        _items.clear();
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await NotificationApi.list(token);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(rows.map(_fromJson));
        _loading = false;
      });
    } on NotificationApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  AppNotification _fromJson(Map<String, dynamic> row) {
    final type = '${row['type'] ?? ''}';
    final style = switch (type) {
      'NOUVEAU_MESSAGE' => (Icons.chat_bubble_outline, _green, _greenBackground),
      'NOUVEL_ABONNE' => (Icons.person_add_alt, _green, _greenBackground),
      'ABONNE_INSCRIT_EVENEMENT' || 'NOUVELLE_PUBLICATION' =>
        (Icons.event_outlined, _orange, _orangeBackground),
      'EVENEMENT_MODERE' => (Icons.event_available_outlined, _green, _greenBackground),
      'INSCRIPTION_EVENEMENT_VALIDEE' =>
        (Icons.event_available_outlined, _green, _greenBackground),
      'INSCRIPTION_EVENEMENT_REFUSEE' =>
        (Icons.event_busy, _orange, _orangeBackground),
      'COMMANDE_ACCEPTEE' =>
        (Icons.shopping_bag_outlined, _green, _greenBackground),
      'COMMANDE_REFUSEE' =>
        (Icons.shopping_bag_outlined, _orange, _orangeBackground),
      'NOUVELLE_OFFRE' || 'OFFRE_ACCEPTEE' || 'OFFRE_REFUSEE' || 'CONTRE_PROPOSITION' =>
        (Icons.local_offer_outlined, _orange, _orangeBackground),
      _ => (Icons.check, Colors.white, _ink),
    };
    final date = DateTime.tryParse('${row['date'] ?? ''}')?.toLocal();
    final title = row['message'] ?? row['titre'] ?? row['contenu'] ?? _titleFor(type);
    final lu = row['lu'];
    return AppNotification(
      id: '${row['id'] ?? ''}',
      type: type,
      icon: style.$1,
      iconColor: style.$2,
      iconBackground: style.$3,
      title: '$title',
      time: date == null ? '' : _relativeTime(date),
      isNew: lu != true && lu != 1 && lu != '1',
    );
  }

  String _titleFor(String type) => switch (type) {
        'NOUVEAU_MESSAGE' => 'Vous avez reçu un nouveau message.',
        'NOUVEL_ABONNE' => 'Une personne a commencé à vous suivre.',
        'NOUVELLE_PUBLICATION' => 'Une nouvelle publication est disponible.',
        'CANDIDATURE_TRAITEE' => 'Votre candidature a été traitée.',
        'OEUVRE_MODEREE' => 'Le statut de votre œuvre a été mis à jour.',
        'EVENEMENT_MODERE' => 'Le statut de votre événement a été mis à jour.',
        'INSCRIPTION_EVENEMENT_VALIDEE' => 'Votre inscription à un événement a été acceptée.',
        'INSCRIPTION_EVENEMENT_REFUSEE' => 'Votre inscription à un événement a été refusée.',
        'COMMANDE_ACCEPTEE' => 'Votre commande a été acceptée par l’artisan.',
        'COMMANDE_REFUSEE' => 'Votre commande a été refusée par l’artisan.',
        'ABONNE_INSCRIT_EVENEMENT' => 'Une personne s’est inscrite à votre événement.',
        'NOUVELLE_OFFRE' => 'Vous avez reçu une nouvelle offre.',
        'OFFRE_ACCEPTEE' => 'Votre offre a été acceptée.',
        'OFFRE_REFUSEE' => 'Votre offre a été refusée.',
        'CONTRE_PROPOSITION' => 'Vous avez reçu une contre-proposition.',
        _ => 'Vous avez une nouvelle notification.',
      };

  String _relativeTime(DateTime date) {
    final age = DateTime.now().difference(date);
    if (age.inMinutes < 1) return 'À l’instant';
    if (age.inMinutes < 60) return 'Il y a ${age.inMinutes} min';
    if (age.inHours < 24) return 'Il y a ${age.inHours} h';
    if (age.inDays == 1) return 'Hier';
    if (age.inDays < 7) return 'Il y a ${age.inDays} jours';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _markAsRead(AppNotification item) async {
    if (!item.isNew) return;
    setState(() => item.isNew = false);
    final token = AtlartSession.instance.token;
    if (!AuthApi.useBackend || token == null || item.id.isEmpty) return;
    try {
      await NotificationApi.markAsRead(token, item.id);
    } on NotificationApiException catch (error) {
      if (!mounted) return;
      setState(() => item.isNew = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
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
    final newItems = _items.where((item) => item.isNew).toList();
    final olderItems = _items.where((item) => !item.isNew).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _NotificationsBottomNav(
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
              const _NotificationsHeader(title: 'Notifications'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!_loading && _error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: _loadNotifications,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    if (!_loading && _error == null && _items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 56),
                        child: Center(child: Text('Aucune notification pour le moment.')),
                      ),
                    if (newItems.isNotEmpty) ...[
                      const _NotificationsSectionTitle('Nouvelles'),
                      for (final item in newItems) _notificationTile(item),
                    ],
                    if (olderItems.isNotEmpty) ...[
                      const _NotificationsSectionTitle('Cette semaine'),
                      for (final item in olderItems) _notificationTile(item),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationTile(AppNotification item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _NotificationTile(
        item: item,
        onTap: () => _markAsRead(item),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back,
              size: 20,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A6FA5),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSectionTitle extends StatelessWidget {
  const _NotificationsSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.isNew ? const Color(0xFFD8E9FB) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: item.isNew
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF3B5B8C).withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: item.iconBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.icon, size: 16, color: item.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: const Color(0xFF1F2F46),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.time,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: const Color(0xFF8A94A6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: item.isNew
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF87171),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(child: card),
        ],
      ),
    );
  }
}

class _NotificationsBottomNav extends StatelessWidget {
  const _NotificationsBottomNav({required this.currentIndex, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return AtlartBottomNav(
      currentIndex: currentIndex,
      onTap: (index) => onTap?.call(index),
    );
  }
}
