import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/atlart_search_widgets.dart' show AtlartBottomNav;

class AppNotification {
  AppNotification({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.time,
    this.isNew = false,
  });

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

  late final List<AppNotification> _items = [
    AppNotification(
      icon: Icons.chat_bubble_outline,
      iconColor: _green,
      iconBackground: _greenBackground,
      title: 'Yasmine Bouazizi vous a envoyé un message',
      time: 'Il y a 12 min',
      isNew: true,
    ),
    AppNotification(
      icon: Icons.add,
      iconColor: _orange,
      iconBackground: _orangeBackground,
      title: 'Votre offre sur Médina, fragments a été acceptée',
      time: 'Il y a 1 h',
      isNew: true,
    ),
    AppNotification(
      icon: Icons.access_time,
      iconColor: _orange,
      iconBackground: _orangeBackground,
      title: 'Votre réservation expire dans 2 h',
      time: 'Il y a 3 h',
      isNew: true,
    ),
    AppNotification(
      icon: Icons.person_add_alt,
      iconColor: _green,
      iconBackground: _greenBackground,
      title: 'Karim T. a commencé à vous suivre',
      time: 'Lundi',
    ),
    AppNotification(
      icon: Icons.check,
      iconColor: Colors.white,
      iconBackground: _ink,
      title: 'Votre candidature artiste a été acceptée 🎉',
      time: 'Lundi',
    ),
    AppNotification(
      icon: Icons.event_outlined,
      iconColor: _orange,
      iconBackground: _orangeBackground,
      title: "Un abonné s'est inscrit à votre événement",
      time: 'Dimanche',
    ),
    AppNotification(
      icon: Icons.star_border,
      iconColor: _green,
      iconBackground: _greenBackground,
      title: 'Nouvel avis 5★ sur Tapis du Moyen Atlas',
      time: 'Samedi',
    ),
  ];

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
        onTap: () {
          if (item.isNew) {
            setState(() => item.isNew = false);
          }
        },
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
