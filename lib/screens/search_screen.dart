import 'package:flutter/material.dart';

import 'search_result_screen.dart';

/// L'accueil ouvre directement la découverte complète.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchResultsScreen(
      title: 'Accueil',
      artworks: [
        SearchResultItem(
          title: 'Médina, fragments',
          subtitle: 'Yasmine Bouzidi · Tunis',
          imageAsset: 'assets/images/evt_regards_medina.png',
          country: 'Tunisie',
          tags: ['Peinture', 'Patrimoine'],
          priceFrom: '1 800 MAD',
        ),
        SearchResultItem(
          title: 'Zellige bleu',
          subtitle: 'Atelier Zerhouni · Fès',
          imageAsset: 'assets/images/zellige_bleu.png',
          country: 'Maroc',
          tags: ['Céramique', 'Patrimoine'],
          priceFrom: '650 MAD',
        ),
      ],
      artisanat: [
        SearchResultItem(
          title: 'Tapis du Moyen Atlas',
          subtitle: 'Atelier Zerhouni · Tlemcen',
          imageAsset: 'assets/images/tapis_moyen_atlas.png',
          country: 'Algérie',
          tags: ['Tissage', 'Patrimoine'],
          priceFrom: '1 800 MAD',
          featured: true,
          rating: 3,
          purchaseable: true,
        ),
        SearchResultItem(
          title: 'Poterie berbère',
          subtitle: 'Chaïbia Talal · Rabat',
          country: 'Maroc',
          tags: ['Céramique', 'Artisanat'],
          priceFrom: '420 MAD',
          purchaseable: true,
        ),
        SearchResultItem(
          title: 'Tapis Beni Ourain',
          subtitle: 'Coopérative Tafsut · Algérie',
          imageAsset: 'assets/images/tapis_beni_ourain.png',
          country: 'Algérie',
          tags: ['Tissage', 'Patrimoine'],
          priceFrom: '2 400 MAD',
          purchaseable: true,
        ),
      ],
      events: [
        SearchResultItem(
          title: 'Regards sur la Médina',
          subtitle: 'Exposition · Galerie El Marsa, Tunis',
          imageAsset: 'assets/images/evt_regards_medina.png',
          dateLabel: '12 – 20 oct.',
          country: 'Tunisie',
          tags: ['Exposition', 'Présentiel'],
          offerable: false,
        ),
        SearchResultItem(
          title: 'Initiation à l’aquarelle',
          subtitle: 'Atelier · En ligne',
          dateLabel: '14 oct. · 18:30',
          country: 'Maroc',
          tags: ['Atelier', 'Virtuel'],
          offerable: false,
        ),
        SearchResultItem(
          title: 'Résidence Sahara',
          subtitle: 'Résidence · Tozeur',
          dateLabel: '1 – 15 nov.',
          country: 'Tunisie',
          tags: ['Résidence'],
          offerable: false,
        ),
        SearchResultItem(
          title: 'Atelier calligraphie',
          subtitle: 'Atelier · Médina, Fès',
          imageAsset: 'assets/images/evt_calligraphie.png',
          dateLabel: '18 oct.',
          country: 'Maroc',
          tags: ['Atelier', 'Présentiel'],
          eventTab: 1,
          offerable: false,
        ),
      ],
      artists: [
        SearchArtist(
          name: 'Yasmine Bouzidi',
          specialty: 'Peintre',
          city: 'Tunis',
          country: 'Tunisie',
          verified: true,
          rating: 3,
          reviews: 24,
          following: true,
        ),
        SearchArtist(
          name: 'Chaïbia Talal',
          specialty: 'Peintre',
          city: 'Rabat',
          country: 'Maroc',
          rating: 5,
          reviews: 58,
        ),
        SearchArtist(
          name: 'Yassine Belbrouj',
          specialty: 'Céramiste',
          city: 'Fès',
          country: 'Maroc',
          verified: true,
          rating: 4,
          reviews: 17,
        ),
      ],
    );
  }
}
