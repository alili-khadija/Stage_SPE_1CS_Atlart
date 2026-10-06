import 'dart:io';

import 'package:flutter/material.dart';

import '../models/event_detail.dart';
import '../theme/atlart_ui_theme.dart';
import 'offers_ui.dart' show OfferColors, OfferText;

class EventColors {
  static const hero = Color(0xFFA9D0F2);
  static const chip = Color(0xFFDCEBFA);
  static const accent = Color(0xFF6C9BD8);
  static const body = Color(0xFF55606B);
  static const line = Color(0xFFE3ECF5);
  static const coral = Color(0xFFFF7478);
  static const navy = Color(0xFF1F3A5F);
}

class EventHeroImage extends StatelessWidget {
  const EventHeroImage({super.key, required this.event});

  final EventDetail event;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(color: EventColors.hero);
    if (event.imagePath != null) {
      return Image.file(
        File(event.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (event.imageAsset != null) {
      return Image.asset(
        event.imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (event.imageUrl != null) {
      return Image.network(
        event.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
  }
}

class EventPageHeader extends StatelessWidget {
  const EventPageHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 6, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DB6E1), Color(0xFFC3DAF2), Colors.white],
          stops: [0, 0.7, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            child: Image.asset(
              AtlartAssets.logoHorizontal,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Text(
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
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                tooltip: 'Retour',
                onPressed: onBack,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: OfferText.poppins(
                  16,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
