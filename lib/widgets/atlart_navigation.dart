import 'package:flutter/material.dart';

import '../screens/artisan_profile_screen.dart';
import '../screens/my_offers_screen.dart';
import '../screens/search_screen.dart';

void navigateToTab(BuildContext context, int index) {
  final Widget page;

  switch (index) {
    case 0:
      page = const SearchScreen();
      break;
    case 1:
    case 2:
      page = const MyOffersScreen();
      break;
    case 3:
      page = const ArtisanProfileScreen();
      break;
    default:
      return;
  }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => page),
  );
}