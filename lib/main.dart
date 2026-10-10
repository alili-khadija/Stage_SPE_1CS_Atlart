import 'package:flutter/material.dart';

import 'app_session.dart';
import 'screens/login_screen.dart';
import 'screens/add_article_screen.dart';
import 'screens/artist_profile_screen.dart';
import 'screens/artisan_profile_screen.dart';
import 'screens/events_screen.dart';
import 'screens/favoris_screen.dart';
import 'screens/my_offers_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_result_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'auth_gate.dart';
import 'theme/atlart_ui_theme.dart';
import 'widgets/profile_shared_widgets.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AtlartSession.instance.restore();
  runApp(const AtlartApp());
}

class AtlartApp extends StatefulWidget {
  const AtlartApp({super.key});

  @override
  State<AtlartApp> createState() => _AtlartAppState();
}

class _AtlartAppState extends State<AtlartApp> {
  bool _wasAuthenticated = AtlartSession.instance.isAuthenticated;

  @override
  void initState() {
    super.initState();
    AtlartSession.instance.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    AtlartSession.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final isAuthenticated = AtlartSession.instance.isAuthenticated;
    if (_wasAuthenticated && !isAuthenticated) {
      navigatorKey.currentState?.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (_) => const AuthGate()),
        (_) => false,
      );
    }
    _wasAuthenticated = isAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Atlart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        splashFactory: InkRipple.splashFactory,
        splashColor: AtlartPalette.coral.withValues(alpha: 0.18),
        highlightColor: AtlartPalette.coral.withValues(alpha: 0.08),
        hoverColor: AtlartPalette.blueText.withValues(alpha: 0.12),
        focusColor: AtlartPalette.blueText.withValues(alpha: 0.16),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            overlayColor: AtlartInteractionStyles.overlay,
            animationDuration: AtlartInteractionStyles.duration,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            overlayColor: AtlartInteractionStyles.overlay,
            animationDuration: AtlartInteractionStyles.duration,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            overlayColor: AtlartInteractionStyles.overlay,
            animationDuration: AtlartInteractionStyles.duration,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            overlayColor: AtlartInteractionStyles.overlay,
            animationDuration: AtlartInteractionStyles.duration,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            overlayColor: AtlartInteractionStyles.overlay,
            animationDuration: AtlartInteractionStyles.duration,
          ),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/search': (_) => const SearchScreen(),
        '/events': (_) => const EventsScreen(),
        '/results': (_) => const SearchResultsScreen(),
        '/profile': (_) => _profileForCurrentRole(),
        '/notifications': (_) => const NotificationsPage(),
        '/settings': (_) => const SettingsPage(),
        '/artisan-profile': (_) => const ArtisanProfileScreen(),
        '/add-article': (_) => const AddArticleScreen(),
        '/offers': (_) => const MyOffersScreen(),
        '/favorites': (_) => const FavoritesScreen(),
        '/messages': (_) => const MessagesScreen(),
      },
    );
  }
}

Widget _profileForCurrentRole() {
  switch (AtlartSession.role) {
    case 'artisan':
      return const ArtisanProfileScreen();
    case 'artiste':
      return ArtistProfileScreen(
        name: AtlartSession.firstName.isEmpty
            ? 'Yasmine Bouazizi'
            : AtlartSession.firstName,
        role: 'Artiste',
        city: 'Tunis, TN',
        bio: 'Découvrez mes œuvres et mon parcours artistique.',
        stats: const [
          ('24', 'Œuvres'),
          ('312', 'Abonnés'),
          ('48', 'Abonnements'),
        ],
        tags: const [
          TagChip(label: 'Peinture'),
          TagChip(label: 'Nature'),
        ],
        works: const [
          ProfileWork(
            title: 'Médina, fragments',
            rating: 4,
            color: Color(0xFFE0703C),
          ),
          ProfileWork(
            title: 'Nuit sur Sidi Bou',
            rating: 5,
            color: Color(0xFF1E3553),
          ),
        ],
        careerPreview: 'École des Beaux-Arts de Tunis · 2010–2014',
      );
    default:
      return const ProfileScreen();
  }
}
