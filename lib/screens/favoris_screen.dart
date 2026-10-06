import 'package:flutter/material.dart';

import '../widgets/atlart_search_widgets.dart';
import 'search_screen.dart';

class FavoriteArtwork {
  const FavoriteArtwork({
    required this.title,
    required this.subtitle,
    required this.price,
    this.placeholder = const Color(0xFF2A9D8F),
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String price;
  final Color placeholder;
  final String? imageUrl;
}

final List<FavoriteArtwork> _favoriteArtworks = [
  const FavoriteArtwork(
    title: 'Médina, fragments',
    subtitle: 'Yasmine Bouazizi · Tunis',
    price: '1 800 MAD',
  ),
  const FavoriteArtwork(
    title: 'Zellige bleu',
    subtitle: 'Atelier Zerhouni · Fès',
    price: '650 MAD',
    placeholder: Color(0xFFFF7373),
  ),
  const FavoriteArtwork(
    title: 'Tapis du Moyen Atlas',
    subtitle: 'Atelier Zerhouni · Tlemcen',
    price: '1 800 MAD',
  ),
  const FavoriteArtwork(
    title: 'Poterie berbère',
    subtitle: 'Chaïbia Talal · Rabat',
    price: '420 MAD',
    placeholder: Color(0xFFF4A261),
  ),
  const FavoriteArtwork(
    title: 'Lanterne en cuivre',
    subtitle: 'Atelier Zerhouni · Fès',
    price: '380 MAD',
  ),
  const FavoriteArtwork(
    title: 'Broderie de Nabeul',
    subtitle: 'Yasmine Bouazizi · Tunis',
    price: '540 MAD',
  ),
];

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _tabs = ['Œuvres', 'Artistes', 'Ateliers', 'Évènements'];

  void _openDiscover() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
  }

  void _onNavigationTap(int index) {
    if (index == 0) {
      _openDiscover();
    } else if (index == 3) {
      Navigator.of(context).pushNamed('/profile');
    } else if (index == 1) {
      Navigator.of(context).pushNamed('/messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AtlartTopBar(
                title: 'Favoris',
                leading: IconButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      _openDiscover();
                    }
                  },
                  tooltip: 'Retour',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF16324A),
                  ),
                ),
                trailing: const SizedBox(width: 36, height: 36),
              ),
              TabBar(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                labelPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: Color(0xFFFA7B6B), width: 2),
                ),
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF17344D),
                unselectedLabelColor: const Color(0xFF8494A8),
                labelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
                tabs: [for (final tab in _tabs) Tab(height: 40, text: tab)],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _favoriteArtworks.isEmpty
                        ? _EmptyFavorites(
                            title: "Aucune œuvre favorite pour l'instant",
                            message: 'Touchez le cœur sur une œuvre pour la retrouver ici.',
                            buttonLabel: 'Découvrir des œuvres',
                            onPressed: _openDiscover,
                          )
                        : _ArtworkGrid(
                            items: _favoriteArtworks,
                            onRemove: (artwork) {
                              setState(() => _favoriteArtworks.remove(artwork));
                            },
                          ),
                    _EmptyFavorites(
                      title: "Aucun artiste favori pour l'instant",
                      message:
                          "Touchez le cœur sur le profil d'un artiste pour le "
                          'retrouver ici et suivre ses nouvelles créations.',
                      buttonLabel: 'Découvrir des artistes',
                      onPressed: _openDiscover,
                    ),
                    _EmptyFavorites(
                      title: "Aucun atelier favori pour l'instant",
                      message: 'Touchez le cœur sur un atelier pour le retrouver ici.',
                      buttonLabel: 'Découvrir des ateliers',
                      onPressed: _openDiscover,
                    ),
                    _EmptyFavorites(
                      title: "Aucun évènement favori pour l'instant",
                      message: 'Touchez le cœur sur un évènement pour le retrouver ici.',
                      buttonLabel: 'Découvrir des évènements',
                      onPressed: _openDiscover,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AtlartBottomNav(
          currentIndex: 2,
          onTap: _onNavigationTap,
        ),
      ),
    );
  }
}

class _ArtworkGrid extends StatelessWidget {
  const _ArtworkGrid({required this.items, required this.onRemove});

  final List<FavoriteArtwork> items;
  final ValueChanged<FavoriteArtwork> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 24.0;
        const gap = 14.0;
        final cardWidth =
            (constraints.maxWidth - horizontalPadding * 2 - gap) / 2;
        final imageHeight = cardWidth * 1.05;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: gap,
            mainAxisSpacing: 16,
            mainAxisExtent: imageHeight + 64,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final artwork = items[index];
            return _ArtworkCard(
              artwork: artwork,
              imageHeight: imageHeight,
              onRemove: () => onRemove(artwork),
            );
          },
        );
      },
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({
    required this.artwork,
    required this.imageHeight,
    required this.onRemove,
  });

  final FavoriteArtwork artwork;
  final double imageHeight;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: artwork.imageUrl == null
                    ? ColoredBox(color: artwork.placeholder)
                    : Image.network(
                        artwork.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            ColoredBox(color: artwork.placeholder),
                      ),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 25,
                      height: 25,
                      child: Icon(
                        Icons.favorite,
                        size: 14,
                        color: Color(0xFFFA7B6B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          artwork.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF17344D),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 1),
        Text(
          artwork.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF8494A8),
            fontSize: 8,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          artwork.price,
          style: const TextStyle(
            color: Color(0xFFFA7B6B),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(38, 60, 38, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD9D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 25,
              color: Color(0xFFFA7B6B),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF17344D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 30),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8494A8),
              fontSize: 10,
              height: 1.7,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 26),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA7B6B),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
