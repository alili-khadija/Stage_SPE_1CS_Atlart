// filepath: c:\src\atlart\lib\Screens\Item_detail_screen.dart
import 'package:flutter/material.dart';

import '../app_session.dart';
import '../models/messaging.dart';
import '../services/auth_api.dart';
import '../services/favorite_api.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_ui_widgets.dart';
import 'new_message_screen.dart';
import 'offer_create_screen.dart';

class ItemDetailTag {
  const ItemDetailTag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

/// Données d'une pièce affichée en détail.
class AtlartItemDetail {
  const AtlartItemDetail({
    required this.title,
    required this.priceFrom,
    required this.negotiable,
    required this.location,
    required this.workshopName,
    required this.workshopVerified,
    required this.specs,
    required this.tags,
    required this.story,
    this.rating = 0,
    this.imageAsset,
    this.offerable = true,
    this.favoriteId,
  });

  final String title;
  final String priceFrom;
  final bool negotiable;
  final String location;
  final String workshopName;
  final bool workshopVerified;
  final Map<String, String> specs;

  // dynamic accepts existing tag objects from other screens without importing
  // their screen just for its tag class.
  final List<dynamic> tags;

  final String story;
  final int rating;
  final String? imageAsset;
  final bool offerable;
  final String? favoriteId;
}

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final AtlartItemDetail item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _following = false;
  bool _storyExpanded = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final id = widget.item.favoriteId;
    final token = AtlartSession.instance.token;
    if (id == null || token == null || !AuthApi.useBackend) return;
    try {
      final favorites = await FavoriteApi.list(token);
      if (!mounted) return;
      setState(() => _isFavorite = favorites.any(
        (row) => row['entite_type'] == 'OEUVRE' && row['entite_id'] == id,
      ));
    } on FavoriteApiException catch (error) {
      debugPrint('Could not load item favorite state: $error');
    }
  }

  Future<void> _toggleFavorite() async {
    final id = widget.item.favoriteId;
    final token = AtlartSession.instance.token;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette œuvre de démonstration n’est pas reliée au catalogue.'),
        ),
      );
      return;
    }
    if (token == null || !AuthApi.useBackend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour enregistrer ce favori.')),
      );
      return;
    }
    try {
      if (_isFavorite) {
        await FavoriteApi.remove(token, 'OEUVRE', id);
      } else {
        await FavoriteApi.add(token, 'OEUVRE', id);
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } on FavoriteApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  static const _heroHeight = 300.0;

  void _startOffer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfferCreateScreen(
          title: widget.item.title,
          artisanName: widget.item.workshopName,
          suggestedAmount: _amountForOffer(widget.item.priceFrom),
          startingPrice: widget.item.priceFrom,
          artisanCity: _cityFromLocation(widget.item.location),
        ),
      ),
    );
  }

  String _cityFromLocation(String location) => location.split(',').first.trim();

  String _messageId(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  void _contactArtist() {
    final item = widget.item;
    openContact(
      context,
      recipient: ChatParticipant(
        id: 'creator-${_messageId(item.workshopName)}',
        name: item.workshopName,
        role: 'Artiste',
        location: _cityFromLocation(item.location),
        verified: item.workshopVerified,
      ),
      about: ChatContext(
        id: 'work-${_messageId(item.title)}',
        kind: ChatContextKind.work,
        title: item.title,
        subtitle: item.priceFrom,
        imageAsset: item.imageAsset,
      ),
    );
  }

  String _amountForOffer(String price) {
    final digits = price.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? '1500' : digits;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _Hero(
                item: item,
                height: _heroHeight,
                isFavorite: _isFavorite,
                onFavorite: _toggleFavorite,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(item.title, style: AtlartType.title),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'à partir de ${item.priceFrom}',
                                style: const TextStyle(
                                  color: AtlartPalette.navyDark,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (item.negotiable)
                                const Text(
                                  'négociable',
                                  style: TextStyle(
                                    color: AtlartPalette.blueTextLight,
                                    fontSize: 9.5,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AtlartPalette.blueTextLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location,
                              style: AtlartType.subtitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _WorkshopRow(
                        name: item.workshopName,
                        verified: item.workshopVerified,
                        following: _following,
                        onToggleFollow: () {
                          setState(() => _following = !_following);
                        },
                      ),
                      const SizedBox(height: 20),
                      _SpecsGrid(specs: item.specs),
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in item.tags) _Tag(tag: tag),
                          ],
                        ),
                      ],
                      const SizedBox(height: 22),
                      const Text(
                        "L'HISTOIRE DE CETTE CRÉATION",
                        style: TextStyle(
                          color: AtlartPalette.navyDark,
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.story,
                        maxLines: _storyExpanded ? null : 4,
                        overflow: _storyExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: AtlartType.subtitle.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() => _storyExpanded = !_storyExpanded);
                        },
                        child: Text(
                          _storyExpanded ? 'Voir moins' : 'Voir plus',
                          style: const TextStyle(
                            color: AtlartPalette.blueText,
                            fontSize: 10.5,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(
              onMessage: _contactArtist,
              onOffer: item.offerable ? _startOffer : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.item,
    required this.height,
    required this.isFavorite,
    required this.onFavorite,
  });

  final AtlartItemDetail item;
  final double height;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.imageAsset != null)
            Image.asset(
              item.imageAsset!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: AtlartPalette.skyHeader),
            )
          else
            Container(color: AtlartPalette.skyHeader),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x99000000)],
                stops: [0.6, 1],
              ),
            ),
          ),
          Positioned(top: topInset + 8, left: 16, child: const AtlartBack()),
          Positioned(
            top: topInset + 8,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onFavorite,
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: AtlartPalette.coral,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const _MoreMenuButton(),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < item.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
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

class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33,
      height: 33,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [AtlartShadows.back],
      ),
      child: const Icon(
        Icons.more_horiz_rounded,
        size: 18,
        color: AtlartPalette.navy,
      ),
    );
  }
}

class _WorkshopRow extends StatelessWidget {
  const _WorkshopRow({
    required this.name,
    required this.verified,
    required this.following,
    required this.onToggleFollow,
  });

  final String name;
  final bool verified;
  final bool following;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AtlartPalette.navyDark,
            shape: BoxShape.circle,
          ),
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AtlartType.cardTitle.copyWith(fontSize: 12)),
              if (verified)
                const Text(
                  'Artisan vérifié',
                  style: TextStyle(
                    color: AtlartPalette.success,
                    fontSize: 9.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 30,
          child: OutlinedButton(
            onPressed: onToggleFollow,
            style: OutlinedButton.styleFrom(
              backgroundColor: following
                  ? AtlartPalette.navyDark
                  : Colors.white,
              side: const BorderSide(color: AtlartPalette.navyDark),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              following ? 'Suivi' : 'Suivre',
              style: TextStyle(
                color: following ? Colors.white : AtlartPalette.navyDark,
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.specs});

  final Map<String, String> specs;

  @override
  Widget build(BuildContext context) {
    final entries = specs.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 16,
        childAspectRatio: 3.4,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: const TextStyle(
                color: AtlartPalette.blueTextLight,
                fontSize: 9.5,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              entry.value,
              style: const TextStyle(
                color: AtlartPalette.navyDark,
                fontSize: 11.5,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.tag});

  final dynamic tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tag.background as Color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tag.label.toString(),
        style: TextStyle(
          color: tag.foreground as Color,
          fontSize: 9.5,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.onMessage, required this.onOffer});

  final VoidCallback onMessage;
  final VoidCallback? onOffer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: onMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AtlartPalette.navyDark),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: AtlartPalette.navyDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AtlartButton(label: 'Faire une offre', onPressed: onOffer),
            ),
          ],
        ),
      ),
    );
  }
}
