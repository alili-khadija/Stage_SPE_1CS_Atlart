import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/profile_shared_widgets.dart';
import 'artisan_profile_screen.dart';

enum WorkAvailability { open, expoOnly, sold }

class PublishedWork {
  const PublishedWork({
    required this.title,
    required this.rating,
    required this.availability,
    required this.color,
    this.price,
    this.imageAsset,
  });

  final String title;
  final int rating;
  final WorkAvailability availability;
  final Color color;
  final String? price;
  final String? imageAsset;
}

String _availabilityLabel(WorkAvailability a) => switch (a) {
      WorkAvailability.open => 'Offres ouvertes',
      WorkAvailability.expoOnly => 'Expo seule',
      WorkAvailability.sold => 'Vendue',
    };

class PublishedWorksScreen extends StatefulWidget {
  const PublishedWorksScreen({super.key, this.works});

  final List<ProfileWork>? works;

  static List<PublishedWork> demo() => const [
        PublishedWork(
          title: 'Médina, fragments',
          rating: 4,
          availability: WorkAvailability.open,
          price: '1 800 MAD',
          color: Color(0xFFE0703C),
        ),
        PublishedWork(
          title: 'Nuit sur Sidi Bou',
          rating: 5,
          availability: WorkAvailability.sold,
          color: Color(0xFF1E3553),
        ),
        PublishedWork(
          title: 'Souk des couleurs',
          rating: 4,
          availability: WorkAvailability.open,
          price: '950 MAD',
          color: Color(0xFFE0A53C),
        ),
        PublishedWork(
          title: 'Dunes de Tozeur',
          rating: 3,
          availability: WorkAvailability.expoOnly,
          color: Color(0xFFB7935C),
        ),
        PublishedWork(
          title: 'Rive gauche',
          rating: 4,
          availability: WorkAvailability.open,
          price: '2 200 MAD',
          color: Color(0xFF3A5A8C),
        ),
        PublishedWork(
          title: 'Zellige bleu',
          rating: 5,
          availability: WorkAvailability.sold,
          color: Color(0xFF2F9E6B),
        ),
        PublishedWork(
          title: 'Fils de laine',
          rating: 3,
          availability: WorkAvailability.expoOnly,
          color: Color(0xFF8A6FC9),
        ),
        PublishedWork(
          title: 'Crépuscule',
          rating: 4,
          availability: WorkAvailability.open,
          price: '1 400 MAD',
          color: Color(0xFFE0703C),
        ),
        PublishedWork(
          title: 'Nuit blanche',
          rating: 5,
          availability: WorkAvailability.open,
          price: '3 000 MAD',
          color: Color(0xFF23404F),
        ),
        PublishedWork(
          title: 'Terre de Nabeul',
          rating: 5,
          availability: WorkAvailability.sold,
          color: Color(0xFFE0A53C),
        ),
        PublishedWork(
          title: 'Oasis',
          rating: 3,
          availability: WorkAvailability.open,
          price: '780 MAD',
          color: Color(0xFF2F9E6B),
        ),
        PublishedWork(
          title: 'Horizon',
          rating: 4,
          availability: WorkAvailability.open,
          price: '1 100 MAD',
          color: Color(0xFF3A5A8C),
        ),
      ];

  @override
  State<PublishedWorksScreen> createState() => _PublishedWorksScreenState();
}

class _PublishedWorksScreenState extends State<PublishedWorksScreen> {
  late final List<PublishedWork> _all = widget.works != null
      ? widget.works!
          .map(
            (w) => PublishedWork(
              title: w.title,
              rating: w.rating,
              availability: WorkAvailability.open,
              color: w.color,
              imageAsset: w.imageAsset,
            ),
          )
          .toList()
      : PublishedWorksScreen.demo();

  WorkAvailability? _filter;
  bool _grid = true;
  final Set<int> _favs = {};

  Map<WorkAvailability?, int> get _counts {
    final counts = <WorkAvailability?, int>{null: _all.length};
    for (final availability in WorkAvailability.values) {
      counts[availability] =
          _all.where((work) => work.availability == availability).length;
    }
    return counts;
  }

  List<PublishedWork> get _visible => _filter == null
      ? _all
      : _all.where((work) => work.availability == _filter).toList();

  void _toggleFav(int key) {
    setState(() {
      if (!_favs.add(key)) {
        _favs.remove(key);
      }
    });
  }

  void _handleNavigationTap(int index) {
    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const ArtisanProfileScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      appBar: ProfileSubPageHeader(
        title: 'Œuvres publiées',
        action: RoundIconButton(
          icon: Icons.tune_rounded,
          onTap: () {},
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'Toutes · ${counts[null]}',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final availability in WorkAvailability.values) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label:
                          '${_availabilityLabel(availability)} · ${counts[availability]}',
                      selected: _filter == availability,
                      onTap: () => setState(() => _filter = availability),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Text(
                          'Trier par : Plus récentes',
                          style: TextStyle(
                            color: AtlartPalette.coral,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.swap_vert_rounded,
                          size: 15,
                          color: AtlartPalette.coral,
                        ),
                      ],
                    ),
                  ),
                  _ViewToggle(
                    grid: _grid,
                    onChanged: (grid) => setState(() => _grid = grid),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _visible.isEmpty
                  ? const _EmptyWorks()
                  : _grid
                      ? _WorksGridView(
                          works: _visible,
                          favs: _favs,
                          onFav: _toggleFav,
                        )
                      : _WorksListView(
                          works: _visible,
                          favs: _favs,
                          onFav: _toggleFav,
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AtlartBottomNav(
        currentIndex: 3,
        onTap: _handleNavigationTap,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AtlartPalette.navyDark : Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AtlartPalette.blueTextSoft,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});

  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(IconData icon, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 26,
          decoration: BoxDecoration(
            color: active ? AtlartPalette.navyDark : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 14,
            color: active ? Colors.white : AtlartPalette.blueTextLight,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14273A56),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          segment(Icons.grid_view_rounded, grid, () => onChanged(true)),
          segment(Icons.view_list_rounded, !grid, () => onChanged(false)),
        ],
      ),
    );
  }
}

class _WorksGridView extends StatelessWidget {
  const _WorksGridView({
    required this.works,
    required this.favs,
    required this.onFav,
  });

  final List<PublishedWork> works;
  final Set<int> favs;
  final ValueChanged<int> onFav;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: works.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final work = works[index];
        final isFavorite = favs.contains(index);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14273A56),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    work.imageAsset == null
                        ? Container(color: work.color)
                        : Image.asset(
                            work.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Container(color: work.color),
                          ),
                    const Center(
                      child: Icon(
                        Icons.remove_red_eye_outlined,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: GestureDetector(
                        onTap: () => onFav(index),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 14,
                            color: AtlartPalette.coral,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AtlartPalette.navy,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (star) => Icon(
                              star < work.rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 9,
                              color: const Color(0xFFF0C53C),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            work.price ?? _availabilityLabel(work.availability),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AtlartPalette.blueTextLight,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorksListView extends StatelessWidget {
  const _WorksListView({
    required this.works,
    required this.favs,
    required this.onFav,
  });

  final List<PublishedWork> works;
  final Set<int> favs;
  final ValueChanged<int> onFav;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: works.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final work = works[index];
        final isFavorite = favs.contains(index);
        final rating = [
          ...List.filled(work.rating, '★'),
          ...List.filled(5 - work.rating, '☆'),
        ].join();

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14273A56),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: work.imageAsset == null
                    ? Container(
                        width: 52,
                        height: 52,
                        color: work.color,
                      )
                    : Image.asset(
                        work.imageAsset!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 52,
                          height: 52,
                          color: work.color,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AtlartPalette.navy,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '$rating · ${work.price ?? _availabilityLabel(work.availability)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AtlartPalette.blueTextLight,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onFav(index),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: AtlartPalette.coral,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyWorks extends StatelessWidget {
  const _EmptyWorks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AtlartPalette.cardFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 26,
                color: AtlartPalette.blueTextLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune œuvre dans cette catégorie',
              style: AtlartType.welcomeTitle,
            ),
          ],
        ),
      ),
    );
  }
}