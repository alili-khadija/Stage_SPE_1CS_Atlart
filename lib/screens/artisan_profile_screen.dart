import 'package:flutter/material.dart';

import '../app_session.dart';
import '../models/artisan_product.dart';
import '../widgets/profile_kit.dart';
import 'artisan_order_screens.dart';
import 'add_article_screen.dart' show AddArticleScreen, ArtisanArticle;
import 'edit_profile_screen.dart';

typedef _EditedArtisanProfile = ({
  String name,
  String bio,
  String location,
  String phone,
  String instagram,
  String linkedin,
  String pinterest,
});

class ArtisanProfileScreen extends StatefulWidget {
  const ArtisanProfileScreen({super.key});

  @override
  State<ArtisanProfileScreen> createState() => _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends State<ArtisanProfileScreen> {
  static const _baseArticleCount = 41;

  late String _name = AtlartSession.firstName.trim().isEmpty
      ? 'Mohamed Karray'
      : AtlartSession.firstName.trim();
  String _bio =
      'Artisan céramiste depuis 2015, pièces façonnées et cuites à Nabeul, '
      'entre tradition berbère et formes contemporaines.';
  String _location = 'Tunis, TN';
  String _phone = '+216 55 018 814';
  String _instagram = 'https://www.instagram.com/';
  String _linkedin = '';
  String _pinterest = '';
  int _addedArticles = 0;
  final Set<int> _likedArticles = {};

  final List<_ArticlePreview> _articles = [
    const _ArticlePreview(
      title: 'Vase en argile',
      color: Color(0xFFE5B47A),
      icon: Icons.local_florist_outlined,
      price: '45 DT',
      quantity: 12,
      category: 'Poterie',
      description: 'Vase en argile façonné et décoré à la main.',
    ),
    const _ArticlePreview(
      title: 'Bol berbère',
      color: Color(0xFFC9784E),
      icon: Icons.local_cafe_outlined,
      price: '28 DT',
      quantity: 6,
      category: 'Poterie',
      description: 'Bol berbère façonné selon un savoir-faire artisanal.',
    ),
  ];

  Future<void> _editProfile() async {
    final profile = await Navigator.of(context).push<_EditedArtisanProfile>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _name,
          initialBio: _bio,
          initialLocation: _location,
          initialPhone: _phone,
          initialInstagram: _instagram,
          initialLinkedin: _linkedin,
          initialPinterest: _pinterest,
        ),
      ),
    );
    if (!mounted || profile == null) return;
    setState(() {
      _name = profile.name;
      _bio = profile.bio;
      _location = profile.location;
      _phone = profile.phone;
      _instagram = profile.instagram;
      _linkedin = profile.linkedin;
      _pinterest = profile.pinterest;
    });
  }

  Future<void> _addArticle() async {
    final article = await Navigator.of(context).push<ArtisanArticle>(
      MaterialPageRoute(builder: (_) => const AddArticleScreen()),
    );
    if (!mounted || article == null) return;
    setState(() {
      _addedArticles++;
      final shiftedLikes = _likedArticles.map((index) => index + 1).toSet();
      _likedArticles
        ..clear()
        ..addAll(shiftedLikes);
      _articles.insert(
        0,
        _ArticlePreview(
          title: article.name,
          color: _articleColor(article.category),
          icon: _articleIcon(article.category),
          price: '${_formatPrice(article.price)} ${article.currency}',
          quantity: article.quantity,
          category: article.category,
          description: article.description,
          photoPath: article.photoPath,
        ),
      );
    });
  }

  void _openArticle(_ArticlePreview article) {
    final amount = int.tryParse(article.price.replaceAll(RegExp(r'\D'), ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prix de cet article est invalide.')),
      );
      return;
    }
    final currencyMatch = RegExp(r'[A-Z]{2,3}')
        .firstMatch(article.price.toUpperCase());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArtisanProductDetailScreen(
          product: Product(
            id: _productId(article.title),
            title: article.title,
            price: amount,
            currency: currencyMatch?.group(0) ?? 'DZD',
            category: article.category,
            description: article.description,
            stock: article.quantity,
            artisanName: _name,
            artisanLocation: _location,
            isMine: true,
            imagePath: article.photoPath,
            thumbColor: article.color,
          ),
        ),
      ),
    );
  }

  Color _articleColor(String category) => switch (category) {
    'Art' => const Color(0xFF5975A2),
    'Décoration' => const Color(0xFFB47B69),
    _ => const Color(0xFFD49A58),
  };

  IconData _articleIcon(String category) => switch (category) {
    'Art' => Icons.palette_outlined,
    'Décoration' => Icons.chair_outlined,
    _ => Icons.local_florist_outlined,
  };

  String _formatPrice(double price) =>
      price == price.roundToDouble() ? price.toStringAsFixed(0) : '$price';

  String _productId(String title) => title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  void _openSettingsMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushNamed('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Se déconnecter'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez vous reconnecter pour accéder à votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AtlartSession.instance.logout();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'artisan profile logout',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La déconnexion a échoué. Réessayez.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      name: _name,
      subtitle: 'Artisan céramiste · $_location',
      verified: true,
      onMenuTap: _openSettingsMenu,
      stats: [
        ('${_baseArticleCount + _addedArticles}', 'Articles'),
        ('198', 'Abonnés'),
        ('22', 'Abonnements'),
      ],
      children: [
        ProfileActionButton(
          label: 'Modifier le profil',
          onPressed: _editProfile,
        ),
        const SizedBox(height: 16),
        ProfileBio(_bio),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ProfileChip(label: 'Poterie'),
            ProfileChip(label: 'Céramique'),
            ProfileChip(
              label: 'Artisan vérifié',
              icon: Icons.verified_rounded,
              verified: true,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            ProfileSocialButton(icon: Icons.camera_alt_outlined),
            SizedBox(width: 8),
            ProfileSocialButton(icon: Icons.facebook),
            SizedBox(width: 8),
            ProfileSocialButton(icon: Icons.public),
          ],
        ),
        const SizedBox(height: 22),
        ProfileSectionHeader(
          'ARTICLES',
          actionLabel: 'Ajouter un article',
          actionIcon: Icons.add_rounded,
          onAction: _addArticle,
        ),
        const SizedBox(height: 12),
        ProfileGrid(
          children: [
            for (var index = 0; index < _articles.length; index++)
              ProfileItemTile(
                title: _articles[index].title,
                color: _articles[index].color,
                icon: _articles[index].icon,
                imagePath: _articles[index].photoPath,
                rating: 4.5,
                price: _articles[index].price,
                caption: '${_articles[index].quantity} disponibles',
                liked: _likedArticles.contains(index),
                onTap: () => _openArticle(_articles[index]),
                onLike: () => setState(() {
                  if (!_likedArticles.add(index)) _likedArticles.remove(index);
                }),
              ),
          ],
        ),
      ],
    );
  }
}

class _ArticlePreview {
  const _ArticlePreview({
    required this.title,
    required this.color,
    required this.icon,
    required this.price,
    required this.quantity,
    this.category = 'Artisanat',
    this.description = '',
    this.photoPath,
  });

  final String title;
  final Color color;
  final IconData icon;
  final String price;
  final int quantity;
  final String category;
  final String description;
  final String? photoPath;
}
