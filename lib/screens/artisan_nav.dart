import 'package:flutter/material.dart';

import 'favoris_screen.dart';
import 'search_screen.dart';

void handleArtisanNavTap(
  BuildContext context, {
  required int index,
  required int current,
}) {
  if (index == current) {
    Navigator.of(context).maybePop();
    return;
  }

  switch (index) {
    case 0:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
      );
      return;
    case 1:
      Navigator.of(context).pushNamed('/messages');
      return;
    case 2:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
      );
      return;
    case 3:
      Navigator.of(context).pushReplacementNamed('/profile');
      return;
  }
}
