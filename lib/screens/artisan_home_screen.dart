import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_step_header.dart';
import 'add_article_screen.dart';
import 'artisan_profile_screen.dart';
import 'favoris_screen.dart';
import '../widgets/offers_ui.dart' show AtlartOffersBottomNav;

class AtlartGalleryCard {
  const AtlartGalleryCard({
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.color,
  });

  final String title;
  final String subtitle;
  final String? imageAsset;
  final Color? color;
}

class ArtisanHomeScreen extends StatefulWidget {
  const ArtisanHomeScreen({super.key});

  @override
  State<ArtisanHomeScreen> createState() => _ArtisanHomeScreenState();
}

class _ArtisanHomeScreenState extends State<ArtisanHomeScreen> {
  int _navIndex = 0;

  static const _brands = <AtlartGalleryCard>[
    AtlartGalleryCard(
      title: 'Ghamza Brand : Algérie',
      subtitle: 'DORRA',
      color: Color(0xFF3B2A2E),
    ),
    AtlartGalleryCard(
      title: 'Archi Brand : Tunisie',
      subtitle: 'Leila',
      color: Color(0xFF13294E),
    ),
    AtlartGalleryCard(
      title: 'Atelier traditionnel',
      subtitle: 'Tunis',
      color: Color(0xFF426A91),
    ),
  ];

  static const _products = <AtlartGalleryCard>[
    AtlartGalleryCard(
      title: 'Ghamza Brand : Tunisie',
      subtitle: 'DORRA',
      color: Color(0xFFE0A458),
    ),
    AtlartGalleryCard(
      title: 'Céramique artisanale',
      subtitle: 'Tunis',
      color: Color(0xFF2A5C99),
    ),
  ];

  void _openAddArticle() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddArticleScreen()));
  }

  void _handleNavigationTap(int index) {
    if (index == 0) {
      setState(() => _navIndex = 0);
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ArtisanProfileScreen()),
      );
    } else if (index == 1) {
      Navigator.of(context).pushNamed('/messages');
    } else {
      setState(() => _navIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AtlartStepHeader(
              title: 'Accueil',
              step: 1,
              totalSteps: 4,
              showBrand: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                children: [
                  const _SearchRow(),
                  const SizedBox(height: 18),
                  const _GallerySection(
                    title: 'PHOTOS DES BRANDS',
                    items: _brands,
                  ),
                  const SizedBox(height: 20),
                  const _GallerySection(
                    title: 'PHOTOS DES PRODUITS',
                    items: _products,
                  ),
                  const SizedBox(height: 20),
                  const _CreativeBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openAddArticle,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Ajouter un nouvel article'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtlartPalette.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            AtlartOffersBottomNav(
              currentIndex: _navIndex,
              onTap: _handleNavigationTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [AtlartShadows.field],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AtlartPalette.blueTextLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Artiste, œuvre, artisanat…',
                    style: AtlartType.fieldHint,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AtlartPalette.skyHeader,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.tune_rounded,
            size: 18,
            color: AtlartPalette.navy,
          ),
        ),
      ],
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.title, required this.items});

  final String title;
  final List<AtlartGalleryCard> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AtlartType.stepsLabel),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _GalleryCard(item: items[index]),
          ),
        ),
      ],
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.item});

  final AtlartGalleryCard item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: item.imageAsset != null
                  ? Image.asset(
                      item.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: item.color ?? AtlartPalette.cardFill,
                      ),
                    )
                  : Container(
                      color: item.color ?? AtlartPalette.cardFill,
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: AtlartType.cardTitle.copyWith(fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.subtitle.isNotEmpty)
            Text(
              item.subtitle,
              style: AtlartType.cardDesc.copyWith(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _CreativeBanner extends StatelessWidget {
  const _CreativeBanner();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Entre la créativité de l’âme et la précision de la main.',
          style: TextStyle(
            color: AtlartPalette.navyDark,
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: Image.asset(
              'assets/images/artisanat_banner.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AtlartPalette.cardFill,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.brush_outlined,
                  size: 36,
                  color: AtlartPalette.blueText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
