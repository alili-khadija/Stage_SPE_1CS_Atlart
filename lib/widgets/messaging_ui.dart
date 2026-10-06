import 'package:flutter/material.dart';

import '../models/messaging.dart';
import 'offers_ui.dart' show OfferColors, OfferText, OfferThumb;

const _avatarColors = [
  Color(0xFFE9A15B),
  Color(0xFF5B86C6),
  Color(0xFF3FA56B),
  Color(0xFFB47B69),
  Color(0xFF7088B0),
];

String chatInitials(String name) {
  final value = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();
  return value.isEmpty ? '?' : value;
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.name, this.radius = 22});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColors[name.hashCode.abs() % _avatarColors.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        chatInitials(name),
        style: OfferText.poppins(
          radius * 0.55,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String _two(int value) => value.toString().padLeft(2, '0');

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String chatListTime(DateTime date) {
  final now = DateTime.now();
  if (_sameDay(date, now)) return '${_two(date.hour)}:${_two(date.minute)}';
  if (_sameDay(date, now.subtract(const Duration(days: 1)))) return 'Hier';
  return '${date.day} ${_months[date.month - 1]}';
}

String chatDayLabel(DateTime date) {
  final now = DateTime.now();
  if (_sameDay(date, now)) return 'Aujourd’hui';
  if (_sameDay(date, now.subtract(const Duration(days: 1)))) return 'Hier';
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String chatClock(DateTime date) => '${_two(date.hour)}:${_two(date.minute)}';

class ThreadStatusPill extends StatelessWidget {
  const ThreadStatusPill({super.key, required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final (String, Color, Color)? spec = switch (thread.status) {
      ThreadStatus.inReview => (
        'En vérification',
        const Color(0xFFFCEFD9),
        OfferColors.brown,
      ),
      ThreadStatus.delivered =>
        thread.incoming
            ? ('Nouvelle demande', const Color(0xFFFF9B9B), Colors.white)
            : ('Transmis', const Color(0xFFDCEBFA), OfferColors.steel),
      ThreadStatus.rejected => (
        'Non approuvé',
        const Color(0xFFFFE3E3),
        OfferColors.error,
      ),
      ThreadStatus.open => null,
    };
    if (spec == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: spec.$2,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        spec.$1,
        style: OfferText.poppins(8, weight: FontWeight.w600, color: spec.$3),
      ),
    );
  }
}

class ChatContextCard extends StatelessWidget {
  const ChatContextCard({super.key, required this.about, this.onTap});

  final ChatContext about;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OfferColors.steel, width: 1),
          ),
          child: Row(
            children: [
              OfferThumb(color: about.thumbColor, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      about.kindLabel.toUpperCase(),
                      style: OfferText.poppins(
                        7.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF6C9BD8),
                        spacing: 0.4,
                      ),
                    ),
                    Text(
                      about.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OfferText.poppins(11.5, weight: FontWeight.w700),
                    ),
                    if (about.subtitle.isNotEmpty)
                      Text(
                        about.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OfferText.poppins(9, color: OfferColors.muted),
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
