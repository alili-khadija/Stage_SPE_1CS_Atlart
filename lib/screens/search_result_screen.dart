import 'dart:io';

import 'package:flutter/material.dart';

import '../app_session.dart';
import '../models/artisan_product.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_search_widgets.dart';
import '../widgets/profile_shared_widgets.dart';
import '../models/event_detail.dart';
import '../models/event_registration.dart';
import 'advanced_filters_sheet.dart';
import 'favoris_screen.dart';
import 'Item_detail_screen.dart';
import 'artist_profile_screen.dart';
import 'event_draft.dart';
import 'event_detail_page.dart';
import 'new_event_screen.dart';
import 'artisan_order_screens.dart';

// ---------------------------------------------------------------------------
// Modèles (anciens champs conservés ; les nouveaux sont optionnels)
// ---------------------------------------------------------------------------

class SearchResultItem {
  const SearchResultItem({
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.imagePath,
    this.badgeIcon,
    this.country = '',
    this.tags = const [],
    this.priceFrom = '1 500 MAD',
    this.offerable = true,
    this.purchaseable = false,
    this.featured = false,
    this.rating = 0,
    this.dateLabel,
    this.eventTab = 0,
    this.eventDetail,
    this.registrationStatus,
  });

  final String title;
  final String subtitle;
  final String? imageAsset;
  final String? imagePath;
  final IconData? badgeIcon;
  final String country;
  final List<String> tags;
  final String priceFrom;
  final bool offerable;
  final bool purchaseable;

  /// Affiché dans le carrousel « À la une » de l'accueil.
  final bool featured;

  /// 0 = pas de note affichée.
  final double rating;

  /// Événements : « 12 – 20 oct. ».
  final String? dateLabel;

  /// Événements : 0 = À venir, 1 = Mes inscriptions, 2 = Organisés.
  final int eventTab;
  final EventDetail? eventDetail;
  final EventRegistrationStatus? registrationStatus;
}

class SearchArtist {
  const SearchArtist({
    required this.name,
    required this.specialty,
    required this.city,
    this.country = '',
    this.verified = false,
    this.rating = 0,
    this.reviews = 0,
    this.following = false,
  });

  final String name;
  final String specialty;
  final String city;
  final String country;
  final bool verified;
  final double rating;
  final int reviews;
  final bool following;
}

// ---------------------------------------------------------------------------
// Constantes
// ---------------------------------------------------------------------------

class _Category {
  const _Category(this.key, this.label);

  /// Clé commune avec la feuille de filtres avancés.
  final String key;
  final String label;
}

const _kCategories = [
  _Category('Artisanat', 'Artisanat'),
  _Category('Événements', 'Événements'),
  _Category('Artistes', 'Artistes'),
  _Category('Œuvres', 'Œuvre'),
];

const _kAllCountries = 'Tout le Maghreb';
const _kCountries = [_kAllCountries, 'Algérie', 'Maroc', 'Tunisie'];

const _kFlags = {
  'Algérie': '🇩🇿',
  'Maroc': '🇲🇦',
  'Tunisie': '🇹🇳',
  'Libye': '🇱🇾',
  'Mauritanie': '🇲🇷',
};

const double _kHPad = 18;

const _kSoftBlue = Color(0xFFDCEBF9);
const _kLine = Color(0xFFE3ECF5);
const _kBody = Color(0xFF55606B);
const _kStar = Color(0xFFF5B942);
const _kShadow = BoxShadow(
  color: Color(0x140F3554),
  blurRadius: 12,
  offset: Offset(0, 4),
);

const _kTints = [
  Color(0xFFDCEBF9),
  Color(0xFFFBE0E0),
  Color(0xFFDDF1E8),
  Color(0xFFFFEFD6),
];

const _kDeepTints = [
  [Color(0xFF8FB5E0), Color(0xFF5975A2)],
  [Color(0xFFFFA2A2), Color(0xFFE86B69)],
  [Color(0xFF9ED8C8), Color(0xFF4F9C8B)],
];

const _kBanners = [Color(0xFFFFC9C9), Color(0xFFCFE3F8), Color(0xFFD3EFE4)];
const _kAvatars = [Color(0xFFE9A15B), Color(0xFF5B86C6), Color(0xFF3FA56B)];

// ---------------------------------------------------------------------------
// Écran
// ---------------------------------------------------------------------------

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    this.title = 'Découvrir',
    this.artworks = const [],
    this.artisanat = const [],
    this.events = const [],
    this.artists = const [],
    this.initialCategory,
    this.initialCountry = 0,
    this.initialQuery = '',
    this.initialFilters,
  });

  final String title;
  final List<SearchResultItem> artworks;
  final List<SearchResultItem> artisanat;
  final List<SearchResultItem> events;
  final List<SearchArtist> artists;
  final int? initialCategory;
  final int initialCountry;
  final String initialQuery;
  final AdvancedSearchFilters? initialFilters;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  late AdvancedSearchFilters _filters;

  // Démo locale : à brancher sur l'historique réel plus tard.
  final List<String> _recent = [
    'Céramique Fès',
    'Tapis berbère',
    'Art contemporain marocain',
  ];

  // Démo locale : à brancher sur la table `abonnement`.
  final Set<String> _following = {};
  final List<EventDraft> _createdEvents = [];

  int _eventTab = 0;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focus.addListener(() {
      if (mounted) setState(() {});
    });

    _filters =
        widget.initialFilters?.copy() ??
        AdvancedSearchFilters(
          country:
              _kCountries[widget.initialCountry.clamp(
                0,
                _kCountries.length - 1,
              )],
        );

    final c = widget.initialCategory;
    if (c != null && c >= 0 && c < _kCategories.length) {
      _filters.categories
        ..clear()
        ..add(_kCategories[c].key);
    }

    for (final artist in widget.artists) {
      if (artist.following) _following.add(artist.name);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // --- État dérivé ---------------------------------------------------------

  String get _query => _controller.text.trim().toLowerCase();

  Set<String> get _cats => _filters.categories;

  bool _catActive(String key) => _cats.isEmpty || _cats.contains(key);

  String? get _singleCategory => _cats.length == 1 ? _cats.first : null;

  bool get _hasAdvancedFilters =>
      _filters.country != _kAllCountries || _filters.tags.isNotEmpty;

  bool get _filtering =>
      _query.isNotEmpty || _cats.isNotEmpty || _hasAdvancedFilters;

  int get _advancedCount =>
      (_filters.country != _kAllCountries ? 1 : 0) + _filters.tags.length;

  String get _title {
    if (_query.isNotEmpty) return _controller.text.trim();
    final single = _singleCategory;
    if (single != null) {
      return _kCategories.firstWhere((c) => c.key == single).label;
    }
    return widget.title;
  }

  String get _modeKey => _singleCategory ?? (_filtering ? 'results' : 'home');

  bool _matchesQuery(String text) =>
      _query.isEmpty || text.toLowerCase().contains(_query);

  bool _matchesCountry(String country) =>
      _filters.country == _kAllCountries || country == _filters.country;

  bool _matchesTags(List<String> tags) =>
      _filters.tags.isEmpty || tags.any(_filters.tags.contains);

  List<SearchResultItem> _filterItems(List<SearchResultItem> items) {
    return items.where((item) {
      return _matchesQuery('${item.title} ${item.subtitle}') &&
          _matchesCountry(item.country) &&
          _matchesTags(item.tags);
    }).toList();
  }

  List<SearchArtist> get _filteredArtists => widget.artists.where((artist) {
    return _matchesQuery('${artist.name} ${artist.specialty} ${artist.city}') &&
        _matchesCountry(artist.country);
  }).toList();

  List<SearchResultItem> get _allEvents => [
    ...widget.events,
    for (final registration in EventRegistrationStore.instance.registrations)
      _searchItemForRegistration(registration),
    for (final draft in _createdEvents) _searchItemFor(draft),
  ];

  SearchResultItem _searchItemFor(EventDraft draft) {
    final event = draft.toEventDetail();
    return SearchResultItem(
      title: event.title,
      subtitle: '${event.category} · ${event.locationLabel}',
      imagePath: event.imagePath,
      country: _countryFromLocation(event.location),
      dateLabel: event.dateLabel,
      offerable: false,
      eventTab: 2,
      eventDetail: event,
    );
  }

  SearchResultItem _searchItemForRegistration(EventRegistration registration) {
    final event = registration.event;
    return SearchResultItem(
      title: event.title,
      subtitle: '${event.category} · ${event.locationLabel}',
      imageAsset: event.imageAsset,
      imagePath: event.imagePath,
      country: _countryFromLocation(event.location),
      dateLabel: event.dateLabel,
      offerable: false,
      eventTab: 1,
      eventDetail: event,
      registrationStatus: registration.status,
    );
  }

  String _countryFromLocation(String location) {
    for (final country in _kCountries.skip(1)) {
      if (location.contains(country)) return country;
    }
    return '';
  }

  void _openEvent(SearchResultItem item) {
    final event =
        item.eventDetail ??
        EventDetail(
          id: EventDetail.idFromTitle(item.title),
          title: item.title,
          category: item.subtitle.split('·').first.trim(),
          dateLabel: item.dateLabel ?? '',
          location: item.subtitle.split('·').skip(1).join('·').trim(),
          placesLeft: null,
          requiresValidation: true,
          imageAsset: item.imageAsset,
          imagePath: item.imagePath,
        );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailPage(
          event: event,
          onViewRegistrations: _showEventRegistrations,
        ),
      ),
    );
  }

  void _showEventRegistrations() {
    _controller.clear();
    _focus.unfocus();
    setState(() {
      _filters = AdvancedSearchFilters()..categories.add('Événements');
      _eventTab = 1;
    });
  }

  List<SearchResultItem> get _featured {
    final all = [...widget.artworks, ...widget.artisanat];
    final flagged = all.where((i) => i.featured).toList();
    return flagged.isNotEmpty ? flagged : all.take(3).toList();
  }

  int get _resultCount {
    var n = 0;
    if (_catActive('Œuvres')) n += _filterItems(widget.artworks).length;
    if (_catActive('Artisanat')) n += _filterItems(widget.artisanat).length;
    if (_catActive('Événements')) n += _filterItems(_allEvents).length;
    if (_catActive('Artistes')) n += _filteredArtists.length;
    return n;
  }

  // --- Actions -------------------------------------------------------------

  Future<void> _createEvent() async {
    _focus.unfocus();
    final draft = await Navigator.of(context).push<EventDraft>(
      MaterialPageRoute<EventDraft>(builder: (_) => const NewEventScreen()),
    );
    if (!mounted || draft == null) return;
    setState(() {
      _createdEvents.insert(0, draft);
      _eventTab = 2;
    });
  }

  void _submit(String value) {
    final text = value.trim();
    if (text.isNotEmpty) {
      _recent.removeWhere((s) => s.toLowerCase() == text.toLowerCase());
      _recent.insert(0, text);
      if (_recent.length > 6) _recent.removeLast();
    }
    _focus.unfocus();
    setState(() {});
  }

  void _selectRecent(String search) {
    _controller.text = search;
    _controller.selection = TextSelection.collapsed(offset: search.length);
    _submit(search);
  }

  void _toggleCategory(String key) {
    setState(() {
      final already = _cats.length == 1 && _cats.contains(key);
      _filters.categories
        ..clear()
        ..addAll(already ? <String>[] : [key]);
      _eventTab = 0;
    });
  }

  void _selectCountry(String country) {
    setState(() {
      _filters = AdvancedSearchFilters(
        country: country,
        categories: Set<String>.from(_filters.categories),
        tags: Set<String>.from(_filters.tags),
      );
    });
  }

  void _resetAll() {
    _controller.clear();
    _focus.unfocus();
    setState(() {
      _filters = AdvancedSearchFilters();
      _eventTab = 0;
    });
  }

  Future<void> _openAdvancedFilters() async {
    _focus.unfocus();

    final result = await AdvancedFiltersSheet.show(
      context,
      initialFilters: _filters,
      resultCount: _resultCount,
    );

    if (!mounted || result == null) return;
    setState(() => _filters = result);
  }

  void _toggleFollow(SearchArtist artist) {
    setState(() {
      if (!_following.add(artist.name)) _following.remove(artist.name);
    });
  }

  void _showNotAvailable() {
    Navigator.of(context).pushNamed('/messages');
  }

  void _handleNavigationTap(int index) {
    if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()));
      return;
    }

    if (index == 3) {
      Navigator.of(context).pushNamed('/profile');
      return;
    }

    if (index == 1) {
      _showNotAvailable();
      return;
    }

    setState(() => _navIndex = 0);
  }

  // --- Contenu -------------------------------------------------------------

  Widget _content() {
    final artworks = _catActive('Œuvres')
        ? _filterItems(widget.artworks)
        : <SearchResultItem>[];
    final crafts = _catActive('Artisanat')
        ? _filterItems(widget.artisanat)
        : <SearchResultItem>[];
    final events = _catActive('Événements')
        ? _filterItems(_allEvents)
        : <SearchResultItem>[];
    final artists = _catActive('Artistes')
        ? _filteredArtists
        : <SearchArtist>[];

    final empty = _EmptyResults(filtering: _filtering, onReset: _resetAll);

    switch (_singleCategory) {
      case 'Événements':
        return ListenableBuilder(
          listenable: EventRegistrationStore.instance,
          builder: (context, _) => _EventsView(
            events: _filterItems(_allEvents),
            tab: _eventTab,
            canOrganizeEvents:
                AtlartSession.role == 'artiste' ||
                AtlartSession.role == 'artisan',
            onTab: (i) => setState(() => _eventTab = i),
            onCreateEvent: _createEvent,
            onOpenEvent: _openEvent,
          ),
        );
      case 'Artistes':
        if (artists.isEmpty) return empty;
        return _ArtistsList(
          artists: artists,
          following: _following,
          onToggleFollow: _toggleFollow,
        );
      case 'Œuvres':
        return artworks.isEmpty ? empty : _ItemGrid(items: artworks);
      case 'Artisanat':
        return crafts.isEmpty ? empty : _ItemGrid(items: crafts);
      default:
        break;
    }

    if (artworks.isEmpty &&
        crafts.isEmpty &&
        events.isEmpty &&
        artists.isEmpty) {
      return empty;
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 6, bottom: 24),
      children: [
        if (!_filtering) _FeaturedCarousel(items: _featured),
        if (artworks.isNotEmpty)
          _ItemSection(
            title: 'ŒUVRES',
            items: artworks,
            onSeeAll: () => _toggleCategory('Œuvres'),
          ),
        if (crafts.isNotEmpty)
          _ItemSection(
            title: 'ARTISANAT',
            items: crafts,
            onSeeAll: () => _toggleCategory('Artisanat'),
          ),
        if (artists.isNotEmpty)
          _ArtistSection(
            artists: artists,
            onSeeAll: () => _toggleCategory('Artistes'),
          ),
        if (events.isNotEmpty)
          _EventSection(
            events: events.take(2).toList(),
            onSeeAll: () => _toggleCategory('Événements'),
            onOpenEvent: _openEvent,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCountry =
        _query.isNotEmpty ||
        _cats.isNotEmpty ||
        _filters.country != _kAllCountries ||
        _filters.tags.isNotEmpty;

    final recents = _query.isEmpty
        ? _recent
        : _recent.where((s) => s.toLowerCase().contains(_query)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(child: _WavesBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AtlartTopBar(
                  title: _title,
                  notificationCount: 3,
                  onNotificationTap: () =>
                      Navigator.of(context).pushNamed('/notifications'),
                  onMenuTap: () => Navigator.of(context).pushNamed('/settings'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_kHPad, 9, _kHPad, 6),
                  child: _SearchBar(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: _submit,
                    onFilterTap: _openAdvancedFilters,
                    filterCount: _advancedCount,
                  ),
                ),
                _RecentPanel(
                  visible: _focus.hasFocus && recents.isNotEmpty,
                  items: recents,
                  onSelect: _selectRecent,
                  onRemove: (s) => setState(() => _recent.remove(s)),
                  onClear: () => setState(_recent.clear),
                ),
                _CategoryChips(selected: _cats, onTap: _toggleCategory),
                _CountryPills(
                  visible: showCountry,
                  selected: _filters.country,
                  onTap: _selectCountry,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(_modeKey),
                      child: _content(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AtlartBottomNav(
        currentIndex: _navIndex,
        onTap: _handleNavigationTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fond
// ---------------------------------------------------------------------------

/// Ton fichier s'appelle `atlart_waves.png.png` (double extension) dans
/// assets/images : les deux noms sont essayés. Renomme-le en `atlart_waves.png`.
class _WavesBackground extends StatelessWidget {
  const _WavesBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.5,
        child: Image.asset(
          'assets/images/atlart_waves.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Image.asset(
            'assets/images/atlart_waves.png.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recherche, historique, filtres
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onFilterTap,
    required this.filterCount,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [_kShadow],
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
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    onTapOutside: (_) => focusNode.unfocus(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Artiste, œuvre, artisanat...',
                      hintStyle: TextStyle(
                        color: AtlartPalette.blueTextLight,
                        fontSize: 10.5,
                        fontFamily: 'Poppins',
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      color: AtlartPalette.navy,
                      fontSize: 11.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AtlartPalette.blueTextLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 9),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: AtlartPalette.coral,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onFilterTap,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (filterCount > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 17,
                  height: 17,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [_kShadow],
                  ),
                  child: Text(
                    '$filterCount',
                    style: const TextStyle(
                      color: AtlartPalette.coral,
                      fontSize: 9,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Historique : visible seulement quand la barre de recherche a le focus.
class _RecentPanel extends StatelessWidget {
  const _RecentPanel({
    required this.visible,
    required this.items,
    required this.onSelect,
    required this.onRemove,
    required this.onClear,
  });

  final bool visible;
  final List<String> items;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : TextFieldTapRegion(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(_kHPad, 2, _kHPad, 8),
                padding: const EdgeInsets.fromLTRB(16, 8, 6, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [_kShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'RECHERCHES RÉCENTES',
                            style: TextStyle(
                              color: AtlartPalette.blueTextLight,
                              fontSize: 9,
                              letterSpacing: 0.5,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onClear,
                          child: const Text(
                            'Effacer',
                            style: TextStyle(
                              color: AtlartPalette.coral,
                              fontSize: 10,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (int i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: _kLine),
                      InkWell(
                        onTap: () => onSelect(items[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 17,
                                color: AtlartPalette.blueTextLight,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  items[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AtlartPalette.navy,
                                    fontSize: 11.5,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Supprimer',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => onRemove(items[i]),
                                icon: const Icon(Icons.close_rounded, size: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onTap});

  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(_kHPad, 6, _kHPad, 6),
        children: [
          for (final category in _kCategories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: category.label,
                selected: selected.contains(category.key),
                onTap: () => onTap(category.key),
              ),
            ),
        ],
      ),
    );
  }
}

/// Deuxième rangée : n'apparaît (avec une animation) qu'une fois la
/// recherche affinée par une catégorie, un mot-clé ou un filtre.
class _CountryPills extends StatelessWidget {
  const _CountryPills({
    required this.visible,
    required this.selected,
    required this.onTap,
  });

  final bool visible;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(_kHPad, 2, _kHPad, 4),
                children: [
                  for (final country in _kCountries)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: _Chip(
                        label: country,
                        compact: true,
                        selected: selected == country,
                        onTap: () => onTap(country),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color text;
    BoxBorder? border;

    if (compact) {
      fill = Colors.white;
      text = selected ? AtlartPalette.navy : AtlartPalette.blueText;
      border = Border.all(
        color: selected ? AtlartPalette.navy : const Color(0xFFD5E4F4),
        width: selected ? 1.4 : 1,
      );
    } else {
      fill = selected ? AtlartPalette.blueText : _kSoftBlue;
      text = selected ? Colors.white : AtlartPalette.blueText;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
        border: border,
        boxShadow: (!compact && selected)
            ? const [
                BoxShadow(
                  color: Color(0x335975A2),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 17,
              vertical: compact ? 6 : 8,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: compact ? 9.5 : 10.5,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// À la une (accueil)
// ---------------------------------------------------------------------------

class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.items});

  final List<SearchResultItem> items;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(_kHPad, 4, _kHPad, 8),
            child: Text('À LA UNE', style: AtlartType.stepsLabel),
          ),
          SizedBox(
            height: 196,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _FeaturedCard(item: widget.items[index], index: index),
              ),
            ),
          ),
          if (widget.items.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < widget.items.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AtlartPalette.blueText
                            : const Color(0xFFCFDDEB),
                        borderRadius: BorderRadius.circular(3),
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

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.index});

  final SearchResultItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final deep = _kDeepTints[index % _kDeepTints.length];
    final flag = _kFlags[item.country];

    return GestureDetector(
      onTap: item.offerable ? () => _openItemDetails(context, item) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [_kShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.imageAsset != null)
                Image.asset(
                  item.imageAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _DeepFallback(colors: deep),
                )
              else
                _DeepFallback(colors: deep),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              if (flag != null)
                Positioned(top: 10, left: 10, child: _FlagPill(flag: flag)),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 9.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (item.rating > 0) ...[
                      const SizedBox(height: 5),
                      _Stars(item.rating, size: 13, empty: Colors.white54),
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
}

class _DeepFallback extends StatelessWidget {
  const _DeepFallback({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 34, color: Color(0x80FFFFFF)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Œuvres / artisanat
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kHPad, 0, _kHPad - 8, 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AtlartType.stepsLabel),
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'Voir tout →',
              style: TextStyle(
                color: AtlartPalette.coral,
                fontSize: 10,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSection extends StatelessWidget {
  const _ItemSection({
    required this.title,
    required this.items,
    required this.onSeeAll,
  });

  final String title;
  final List<SearchResultItem> items;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, onSeeAll: onSeeAll),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _kHPad),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _ItemCard(item: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items});

  final List<SearchResultItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(_kHPad, 8, _kHPad, 24),
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final width = (box.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 18,
              children: [
                for (final item in items)
                  _ItemCard(
                    item: item,
                    width: width,
                    imageHeight: width * 0.85,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    this.width = 128,
    this.imageHeight = 104,
  });

  final SearchResultItem item;
  final double width;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final flag = _kFlags[item.country];

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: item.offerable ? () => _openItemDetails(context, item) : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: imageHeight,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [_kShadow],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.imageAsset != null)
                      Image.asset(
                        item.imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _SoftPlaceholder(seed: item.title),
                      )
                    else
                      _SoftPlaceholder(seed: item.title),
                    if (flag != null)
                      Positioned(top: 6, left: 6, child: _FlagPill(flag: flag)),
                    if (item.badgeIcon != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: AtlartPalette.coral,
                          child: Icon(
                            item.badgeIcon,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtlartType.cardTitle.copyWith(fontSize: 10),
            ),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtlartType.cardDesc.copyWith(fontSize: 8.5),
            ),
            if (item.offerable)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Voir le détail · Faire une offre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AtlartPalette.coral,
                    fontSize: 7.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (item.purchaseable)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Voir le détail · Commander',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AtlartPalette.coral,
                    fontSize: 7.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FlagPill extends StatelessWidget {
  const _FlagPill({required this.flag});

  final String flag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(flag, style: const TextStyle(fontSize: 10)),
    );
  }
}

class _SoftPlaceholder extends StatelessWidget {
  const _SoftPlaceholder({
    required this.seed,
    this.icon = Icons.image_outlined,
  });

  final String seed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tint = _kTints[seed.hashCode.abs() % _kTints.length];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint, Color.lerp(tint, Colors.white, 0.55)!],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 26, color: AtlartPalette.blueTextLight),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(
    this.rating, {
    this.size = 12,
    this.empty = const Color(0xFFD9DEE6),
  });

  final double rating;
  final double size;
  final Color empty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            rating >= i + 1
                ? Icons.star_rounded
                : (rating >= i + 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: size,
            color: rating >= i + 0.5 ? _kStar : empty,
          ),
      ],
    );
  }
}

void _openItemDetails(BuildContext context, SearchResultItem item) {
  final workshop = item.subtitle.split('·').first.trim();
  final location = item.subtitle.contains('·')
      ? item.subtitle.split('·').last.trim()
      : item.country;

  if (item.purchaseable) {
    final amount = int.tryParse(item.priceFrom.replaceAll(RegExp(r'\D'), ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prix de cet article est invalide.')),
      );
      return;
    }
    final currencyMatch = RegExp(r'[A-Z]{3}')
        .firstMatch(item.priceFrom.toUpperCase());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArtisanProductDetailScreen(
          product: Product(
            id: EventDetail.idFromTitle(item.title),
            title: item.title,
            price: amount,
            currency: currencyMatch?.group(0) ?? 'DZD',
            category: item.tags.isEmpty ? 'Artisanat' : item.tags.first,
            description:
                'Article artisanal réalisé par ${workshop.isEmpty ? 'un atelier local' : workshop}. '
                'Chaque pièce met en valeur un savoir-faire traditionnel.',
            stock: 12,
            artisanName: workshop,
            artisanLocation: location,
            deliveryFee: 600,
            imageAsset: item.imageAsset,
            imagePath: item.imagePath,
          ),
        ),
      ),
    );
    return;
  }

  final tags = item.tags.map((label) {
    return ItemDetailTag(
      label: label,
      background: const Color(0xFFDCEAF8),
      foreground: AtlartPalette.blueText,
    );
  }).toList();

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ItemDetailScreen(
        item: AtlartItemDetail(
          title: item.title,
          priceFrom: item.priceFrom,
          negotiable: true,
          location: location,
          workshopName: workshop,
          workshopVerified: true,
          specs: const {'Catégorie': 'Artisanat', 'Disponibilité': 'En stock'},
          tags: tags,
          story:
              'Cette création met en valeur le savoir-faire et les techniques '
              'artisanales transmis au sein de l’atelier.',
          imageAsset: item.imageAsset,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Artistes
// ---------------------------------------------------------------------------

String _initials(String name) {
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

void _openArtist(BuildContext context, SearchArtist artist) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ArtistProfileScreen(
        name: artist.name,
        role: artist.specialty,
        city: artist.city,
        bio: 'Découvrez les œuvres et le parcours de ${artist.name}.',
        stats: const [
          ('24', 'Œuvres'),
          ('312', 'Abonnés'),
          ('48', 'Abonnements'),
        ],
        tags: const [TagChip(label: 'Artiste')],
        works: const <ProfileWork>[],
        isMe: false,
      ),
    ),
  );
}

/// Accueil : bande horizontale d'artistes.
class _ArtistSection extends StatelessWidget {
  const _ArtistSection({required this.artists, required this.onSeeAll});

  final List<SearchArtist> artists;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'ARTISTES', onSeeAll: onSeeAll),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _kHPad),
              itemCount: artists.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final artist = artists[index];
                return SizedBox(
                  width: 104,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [_kShadow],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openArtist(context, artist),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 23,
                                backgroundColor:
                                    _kAvatars[index % _kAvatars.length],
                                child: Text(
                                  _initials(artist.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                artist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AtlartType.cardTitle.copyWith(
                                  fontSize: 9,
                                ),
                              ),
                              Text(
                                '${artist.specialty} · ${artist.city}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AtlartType.cardDesc.copyWith(
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Rubrique Artistes : cartes verticales (bandeau, avatar, note, Suivre).
class _ArtistsList extends StatelessWidget {
  const _ArtistsList({
    required this.artists,
    required this.following,
    required this.onToggleFollow,
  });

  final List<SearchArtist> artists;
  final Set<String> following;
  final ValueChanged<SearchArtist> onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(_kHPad, 10, _kHPad, 24),
      itemCount: artists.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return _ArtistCard(
          artist: artist,
          index: index,
          following: following.contains(artist.name),
          onToggleFollow: () => onToggleFollow(artist),
          onOpen: () => _openArtist(context, artist),
        );
      },
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({
    required this.artist,
    required this.index,
    required this.following,
    required this.onToggleFollow,
    required this.onOpen,
  });

  final SearchArtist artist;
  final int index;
  final bool following;
  final VoidCallback onToggleFollow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final banner = _kBanners[index % _kBanners.length];
    final avatar = _kAvatars[index % _kAvatars.length];
    final place = artist.country.isEmpty
        ? artist.city
        : '${artist.city}, ${artist.country}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kShadow],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 46, color: banner),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      artist.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AtlartPalette.navy,
                                        fontSize: 12.5,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (artist.verified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: Color(0xFF3FA56B),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${artist.specialty} · $place',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _kBody,
                                  fontSize: 9.5,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              if (artist.rating > 0) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    _Stars(artist.rating, size: 12),
                                    const SizedBox(width: 5),
                                    Text(
                                      '(${artist.reviews})',
                                      style: const TextStyle(
                                        color: _kBody,
                                        fontSize: 9,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _FollowButton(
                          following: following,
                          onTap: onToggleFollow,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 24,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: avatar,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Text(
                _initials(artist.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: following ? Colors.white : AtlartPalette.coral,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: following ? AtlartPalette.navy : AtlartPalette.coral,
          ),
        ),
        child: Text(
          following ? 'Abonné' : 'Suivre',
          style: TextStyle(
            color: following ? AtlartPalette.navy : Colors.white,
            fontSize: 10,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Événements
// ---------------------------------------------------------------------------

/// Rubrique Événements : onglets + cartes (la première est mise en avant).
class _EventsView extends StatelessWidget {
  const _EventsView({
    required this.events,
    required this.tab,
    required this.canOrganizeEvents,
    required this.onTab,
    required this.onCreateEvent,
    required this.onOpenEvent,
  });

  final List<SearchResultItem> events;
  final int tab;
  final bool canOrganizeEvents;
  final ValueChanged<int> onTab;
  final VoidCallback onCreateEvent;
  final ValueChanged<SearchResultItem> onOpenEvent;

  static const _labels = ['À venir', 'Mes inscriptions', 'Organisés'];
  static const _emptyMessages = [
    'Aucun événement à venir pour le moment.',
    'Vous n’êtes inscrit(e) à aucun événement.',
    'Vous n’avez organisé aucun événement.',
  ];

  @override
  Widget build(BuildContext context) {
    final shown = events.where((e) => e.eventTab == tab).toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(_kHPad, 8, _kHPad, 24),
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _kLine)),
          ),
          child: Row(
            children: [
              for (int i = 0; i < _labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 22),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTab(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: i == tab
                                ? AtlartPalette.coral
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _labels[i],
                        style: TextStyle(
                          color: i == tab
                              ? AtlartPalette.coral
                              : AtlartPalette.blueTextLight,
                          fontSize: 10.5,
                          fontFamily: 'Poppins',
                          fontWeight: i == tab
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (tab == 2 && canOrganizeEvents) ...[
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AtlartPalette.coral, Color(0xFFF28B70)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AtlartPalette.coral.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onCreateEvent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.event_available_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organiser un événement',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Partagez votre prochain atelier ou exposition',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (shown.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: tab == 2 ? 22 : 40),
            child: Column(
              children: [
                const Icon(
                  Icons.event_busy_outlined,
                  size: 34,
                  color: AtlartPalette.blueTextLight,
                ),
                const SizedBox(height: 10),
                Text(
                  tab == 2 && !canOrganizeEvents
                      ? 'La création d’événements est réservée aux profils artiste et artisan.'
                      : _emptyMessages[tab],
                  textAlign: TextAlign.center,
                  style: AtlartType.subtitle,
                ),
              ],
            ),
          )
        else
          for (int i = 0; i < shown.length; i++) ...[
            _EventCard(
              item: shown[i],
              hero: i == 0,
              onTap: () => onOpenEvent(shown[i]),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

/// Accueil : aperçu des prochains événements.
class _EventSection extends StatelessWidget {
  const _EventSection({
    required this.events,
    required this.onSeeAll,
    required this.onOpenEvent,
  });

  final List<SearchResultItem> events;
  final VoidCallback onSeeAll;
  final ValueChanged<SearchResultItem> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'ÉVÉNEMENTS', onSeeAll: onSeeAll),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kHPad),
            child: Column(
              children: [
                for (final event in events) ...[
                  _EventCard(
                    item: event,
                    hero: false,
                    onTap: () => onOpenEvent(event),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.item,
    required this.hero,
    required this.onTap,
  });

  final SearchResultItem item;
  final bool hero;
  final VoidCallback onTap;

  String get _meta => [
    item.dateLabel,
    item.subtitle,
  ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');

  @override
  Widget build(BuildContext context) {
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (int i = 0; i < item.tags.length; i++)
                _TagPill(label: item.tags[i], primary: i == 0),
            ],
          ),
        if (item.tags.isNotEmpty) const SizedBox(height: 6),
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AtlartPalette.navy,
            fontSize: 12.5,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _kBody,
            fontSize: 9.5,
            fontFamily: 'Poppins',
          ),
        ),
        if (item.registrationStatus != null) ...[
          const SizedBox(height: 5),
          Text(
            'Inscription · ${item.registrationStatus!.label}',
            style: const TextStyle(
              color: AtlartPalette.coral,
              fontSize: 9,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [_kShadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: hero
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 84,
                        width: double.infinity,
                        child: _EventImage(item: item),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: info,
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _EventImage(item: item),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: info),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    final fallback = _SoftPlaceholder(
      seed: item.title,
      icon: Icons.event_outlined,
    );
    if (item.imagePath != null) {
      return Image.file(
        File(item.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (item.imageAsset == null) return fallback;

    return Image.asset(
      item.imageAsset!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.primary});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: primary ? const Color(0xFFFFE9D2) : const Color(0xFFD9E8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary ? const Color(0xFFC77A2B) : AtlartPalette.blueText,
          fontSize: 8,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Aucun résultat
// ---------------------------------------------------------------------------

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.filtering, required this.onReset});

  final bool filtering;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 38),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [_kShadow],
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 28,
                color: AtlartPalette.blueText,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Aucun résultat', style: AtlartType.welcomeTitle),
            const SizedBox(height: 7),
            const Text(
              'Essayez un autre mot-clé, ou retirez un filtre pour élargir la recherche.',
              textAlign: TextAlign.center,
              style: AtlartType.subtitle,
            ),
            if (filtering) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AtlartPalette.navy,
                  side: const BorderSide(color: AtlartPalette.navy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Réinitialiser les filtres',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
