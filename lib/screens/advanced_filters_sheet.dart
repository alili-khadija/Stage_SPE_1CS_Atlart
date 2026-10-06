import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';

class AdvancedSearchFilters {
  AdvancedSearchFilters({
    this.country = 'Tout le Maghreb',
    Set<String>? categories,
    Set<String>? tags,
  })  : categories = categories ?? <String>{},
        tags = tags ?? <String>{};

  final String country;
  final Set<String> categories;
  final Set<String> tags;

  AdvancedSearchFilters copy() => AdvancedSearchFilters(
        country: country,
        categories: Set<String>.from(categories),
        tags: Set<String>.from(tags),
      );
}

class AdvancedFiltersSheet extends StatefulWidget {
  const AdvancedFiltersSheet({
    super.key,
    this.initialFilters,
    this.resultCount = 24,
  });

  final AdvancedSearchFilters? initialFilters;
  final int resultCount;

  static Future<AdvancedSearchFilters?> show(
    BuildContext context, {
    AdvancedSearchFilters? initialFilters,
    int resultCount = 24,
  }) {
    return showModalBottomSheet<AdvancedSearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdvancedFiltersSheet(
        initialFilters: initialFilters,
        resultCount: resultCount,
      ),
    );
  }

  @override
  State<AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<AdvancedFiltersSheet> {
  static const _countries = [
    'Tout le Maghreb',
    'Tunisie',
    'Algérie',
    'Maroc',
  ];

  static const _categories = [
    'Artisanat',
    'Événements',
    'Artistes',
    'Œuvres',
  ];

  static const _tagGroups = <String, List<String>>{
    'ŒUVRES': ['Peinture', 'Sculpture'],
    'ARTISANAT': ['Poterie', 'Tissage', 'Cuivre', 'Bijoux'],
    'THÈME': ['Patrimoine', 'Abstrait', 'Calligraphie'],
  };

  late String _country;
  late Set<String> _selectedCategories;
  late Set<String> _tags;

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters;
    _country = filters?.country ?? _countries.first;
    _selectedCategories =
        Set<String>.from(filters?.categories ?? <String>{});
    _tags = Set<String>.from(filters?.tags ?? <String>{});
  }

  void _toggle(Set<String> selected, String value) {
    setState(() {
      if (!selected.add(value)) selected.remove(value);
    });
  }

  void _reset() {
    setState(() {
      _country = _countries.first;
      _selectedCategories.clear();
      _tags.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      AdvancedSearchFilters(
        country: _country,
        categories: Set<String>.from(_selectedCategories),
        tags: Set<String>.from(_tags),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        height: screenHeight * 0.72,
        decoration: const BoxDecoration(
          color: Color(0xFFD1EAF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 9),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF66899B),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 14, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtres avancés',
                      style: AtlartType.welcomeTitle,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  const _FilterTitle('PAYS'),
                  const SizedBox(height: 8),
                  _FilterChips(
                    options: _countries,
                    selected: (value) => value == _country,
                    onTap: (value) => setState(() => _country = value),
                  ),
                  const SizedBox(height: 17),
                  const _FilterTitle('CATÉGORIE'),
                  const SizedBox(height: 8),
                  _FilterChips(
                    options: _categories,
                    selected: _selectedCategories.contains,
                    onTap: (value) => _toggle(_selectedCategories, value),
                  ),
                  for (final group in _tagGroups.entries) ...[
                    const SizedBox(height: 16),
                    _FilterTitle(group.key),
                    const SizedBox(height: 8),
                    _FilterChips(
                      options: group.value,
                      selected: _tags.contains,
                      onTap: (value) => _toggle(_tags, value),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
              color: const Color(0xFFD1EAF9),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _reset,
                    child: const Text(
                      'Réinitialiser',
                      style: TextStyle(
                        color: AtlartPalette.navy,
                        decoration: TextDecoration.underline,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF244956),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'Voir les résultats (${widget.resultCount})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AtlartPalette.blueText,
        fontSize: 9,
        letterSpacing: 1,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  final List<String> options;
  final bool Function(String) selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 7,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option),
            selected: selected(option),
            onSelected: (_) => onTap(option),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFB8D5EC),
            side: BorderSide(
              color: selected(option)
                  ? AtlartPalette.blueText
                  : const Color(0xFFE3EAF0),
            ),
            labelStyle: TextStyle(
              color: AtlartPalette.navy,
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight:
                  selected(option) ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
      ],
    );
  }
}