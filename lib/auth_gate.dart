import 'package:flutter/material.dart';

import 'Screens/Login_screen.dart';
import 'Screens/search_screen.dart';
import 'app_session.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AtlartSession.instance.isAuthenticated) {
      return const LoginScreen();
    }
    return homeForRole(AtlartSession.instance.user!.role);
  }
}

Widget homeForRole(String role) {
  switch (role) {
    case 'visiteur':
    case 'artiste':
    case 'artisan':
      return const SearchScreen();
    case 'moderateur':
    case 'admin':
    default:
      return const SearchScreen();
  }
}
