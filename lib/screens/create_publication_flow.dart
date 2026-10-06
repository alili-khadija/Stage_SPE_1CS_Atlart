import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../app_session.dart';

// ─────────────────────────────────────────────────────────────────────────
//  Parcours « Publier une œuvre » (Figma : « artiste qui publie »)
//
//  1/4 Photos  →  2/4 Information  →  3/4 Prix  →  4/4 Vérification
//  puis écran Confirmation (sans en-tête de progression).
//
//  Remplace l'ancien fichier : même classe `CreatePublicationFlow`, même
//  garde « artistes uniquement ». Dépendances : image_picker, google_fonts
//  (Cinzel + Playfair Display pour les titres serif de la maquette).
// ─────────────────────────────────────────────────────────────────────────

enum _Step { photos, details, sale, review, done }

enum _Availability { exhibition, open, sold }

enum _Pricing { fixed, negotiable }

class _P {
  static const coral = Color(0xFFFF7478);
  static const coralSoftA = Color(0xFFFFAAAA);
  static const coralSoftB = Color(0xFFEF9CA3);
  static const navy = Color(0xFF1F3A5F);
  static const ink = Color(0xFF1B3550);
  static const steel = Color(0xFF4F6D9A);
  static const steelPlaceholder = Color(0xFF5B77A6);
  static const grey = Color(0xFF8E97A6);
  static const cream = Color(0xFFFCEBCB);
  static const brown = Color(0xFF8A5A00);
  static const olive = Color(0xFF8A7A4A);
  static const shadow = Color(0x14273A56);
}

class _T {
  static TextStyle poppins(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = _P.ink,
    double? height,
    double? spacing,
  }) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      );

  static TextStyle cinzel(double size, {Color color = Colors.white}) =>
      GoogleFonts.cinzel(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.2,
      );

  static TextStyle playfair(double size, {Color color = _P.navy}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );
}

/// "1800" -> "1 800"
String _group(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write(' ');
    b.write(d[i]);
  }
  return b.toString();
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nw) {
    final t = _group(nw.text);
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

// ───────────────────────────── Flow ─────────────────────────────

class CreatePublicationFlow extends StatefulWidget {
  const CreatePublicationFlow({
    super.key,
    this.artistLocation = 'Tunis, Tunisie',
    this.onViewArtwork,
  });

  /// Affiché dans la vérification et la confirmation (« Tunis, Tunisie »).
  final String artistLocation;

  /// Bouton « Voir mon œuvre » de la confirmation. Par défaut : ferme le flux.
  final VoidCallback? onViewArtwork;

  @override
  State<CreatePublicationFlow> createState() => _CreatePublicationFlowState();
}

class _CreatePublicationFlowState extends State<CreatePublicationFlow> {
  static const _maxPhotos = 6;
  static const _currency = 'MAD';
  // Maquette : « Suivant ». Mettez « Publier mon œuvre » si vous préférez.
  static const _reviewButtonLabel = 'Suivant';

  final _picker = ImagePicker();
  final List<String> _photos = []; // index 0 = photo principale

  final _title = TextEditingController();
  final _technique = TextEditingController();
  final _length = TextEditingController();
  final _height = TextEditingController();
  final _tags = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();

  late final bool _isArtist;
  final int _year = DateTime.now().year;

  _Step _step = _Step.photos;
  _Availability? _availability; // null = rien choisi (maquette)
  _Pricing _pricing = _Pricing.negotiable;
  bool _certified = false;
  bool _publishing = false;

  List<TextEditingController> get _controllers =>
      [_title, _technique, _length, _height, _tags, _description, _price];

  @override
  void initState() {
    super.initState();
    _isArtist = (AtlartSession.role ?? '').toLowerCase() == 'artiste';
    for (final c in _controllers) {
      c.addListener(_refresh);
    }
    if (!_isArtist) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content:
                  Text('La publication d’œuvres est réservée aux artistes.'),
            ),
          );
        Navigator.of(context).maybePop();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  // ── Données dérivées ──

  String get _priceDigits => _price.text.replaceAll(RegExp(r'\D'), '');
  int get _priceValue => int.tryParse(_priceDigits) ?? 0;

  String get _availabilityText {
    switch (_availability) {
      case _Availability.exhibition:
        return 'Exposition seule';
      case _Availability.open:
        final p = _group(_priceDigits);
        return _pricing == _Pricing.fixed
            ? 'Prix fixe · $p $_currency'
            : 'Ouverte aux propositions · à partir de $p $_currency';
      case _Availability.sold:
        return 'Déjà vendue';
      case null:
        return '';
    }
  }

  List<String> get _tagList => _tags.text
      .split(RegExp(r'[,\s]+'))
      .map((t) => t.replaceAll('#', '').trim())
      .where((t) => t.isNotEmpty)
      .map((t) => t[0].toUpperCase() + t.substring(1))
      .toList();

  bool get _canContinue {
    switch (_step) {
      case _Step.photos:
        return _photos.isNotEmpty;
      case _Step.details:
        return _title.text.trim().isNotEmpty &&
            _technique.text.trim().isNotEmpty &&
            _length.text.trim().isNotEmpty &&
            _height.text.trim().isNotEmpty;
      case _Step.sale:
        return _availability != null &&
            (_availability != _Availability.open || _priceValue > 0);
      case _Step.review:
        return _certified && !_publishing;
      case _Step.done:
        return false;
    }
  }

  // ── Actions ──

  void _showMessage(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 1800,
        imageQuality: 85,
      );
      if (!mounted || files.isEmpty) return;
      setState(() => _photos.addAll(files.take(remaining).map((f) => f.path)));
    } on PlatformException {
      if (!mounted) return;
      _showMessage('Impossible d’ouvrir la galerie. Réessayez.');
    }
  }

  void _makeMain(int i) {
    if (i == 0) return;
    setState(() => _photos.insert(0, _photos.removeAt(i)));
  }

  void _next() {
    switch (_step) {
      case _Step.photos:
        setState(() => _step = _Step.details);
      case _Step.details:
        setState(() => _step = _Step.sale);
      case _Step.sale:
        setState(() => _step = _Step.review);
      case _Step.review:
        _publish();
      case _Step.done:
        break;
    }
  }

  void _back() {
    switch (_step) {
      case _Step.photos:
      case _Step.done:
        Navigator.of(context).maybePop();
      case _Step.details:
        setState(() => _step = _Step.photos);
      case _Step.sale:
        setState(() => _step = _Step.details);
      case _Step.review:
        setState(() => _step = _Step.sale);
    }
  }

  Future<void> _publish() async {
    if (!_certified || _publishing) return;
    setState(() => _publishing = true);

    // TODO : remplacer ce délai par l'appel à votre API de publication
    // (envoyer _photos, titre, technique, dimensions, tags, description,
    // disponibilité / prix).
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _publishing = false;
      _step = _Step.done;
    });
  }

  void _saveDraft() {
    // TODO : enregistrer le brouillon côté API / stockage local.
    _showMessage('Votre œuvre a été enregistrée comme brouillon.');
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (!_isArtist) return const SizedBox.shrink();

    return PopScope(
      canPop: _step == _Step.photos || _step == _Step.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _step == _Step.done ? _buildConfirmation() : _buildStep(context),
    );
  }

  Widget _buildStep(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pad = (width * 0.1).clamp(22.0, 44.0);

    final stepNumber = switch (_step) {
      _Step.photos => 1,
      _Step.details => 2,
      _Step.sale => 3,
      _ => 4,
    };
    final title = switch (_step) {
      _Step.photos => 'Photos',
      _Step.review => 'VÉRIFICATION',
      _ => 'INFORMATION',
    };

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Backdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(pad - 6, 14, pad - 6, 0),
                  child: _Header(
                    title: title,
                    serif: _step != _Step.photos,
                    step: stepNumber,
                    onBack: _back,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(pad, 26, pad, 16),
                    child: switch (_step) {
                      _Step.photos => _buildPhotos(),
                      _Step.details => _buildDetails(),
                      _Step.sale => _buildSale(),
                      _ => _buildReview(),
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_step == _Step.review) ...[
                        _OutlineButton(
                          label: 'Enregistrer comme brouillon',
                          onPressed: _publishing ? null : _saveDraft,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _PrimaryButton(
                        label: _step == _Step.review
                            ? _reviewButtonLabel
                            : 'Suivant',
                        busy: _publishing,
                        onPressed: _canContinue ? _next : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1/4 Photos ──

  Widget _buildPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('PHOTOS DE L’ŒUVRE'),
        const SizedBox(height: 34),
        LayoutBuilder(
          builder: (context, c) {
            const gap = 12.0;
            final size = (c.maxWidth - gap * 2) / 3;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  _PhotoTile(
                    size: size,
                    path: _photos[i],
                    isMain: i == 0,
                    onTap: () => _makeMain(i),
                    onRemove: () => setState(() => _photos.removeAt(i)),
                  ),
                if (_photos.length < _maxPhotos)
                  GestureDetector(
                    onTap: _pickPhotos,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: _Dashed(
                        color: const Color(0xFF9CC3EA),
                        fill: Colors.white.withValues(alpha: 0.7),
                        radius: 14,
                        child: const Center(
                          child: Icon(Icons.add,
                              color: Color(0xFF9CC3EA), size: 22),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: _pickPhotos,
          child: SizedBox(
            height: 132,
            width: double.infinity,
            child: _Dashed(
              color: const Color(0xFFE6C46A),
              fill: Colors.white,
              radius: 18,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.file_upload_outlined,
                      color: Color(0xFFD9A08A), size: 24),
                  const SizedBox(height: 8),
                  Text('Ajouter des photos',
                      style: _T.poppins(12.5, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('JPEG, PNG — glissez ou appuyez',
                      style: _T.poppins(9.5, color: _P.grey)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _P.cream,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.info_outline, size: 12, color: _P.brown),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Choisissez une photo principale nette et bien éclairée — '
                  'c’est elle qui apparaîtra dans les résultats de recherche.',
                  style: _T.poppins(10, color: _P.brown, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 2/4 Information ──

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('DÉTAILS DE L’ŒUVRE'),
        const SizedBox(height: 34),
        _Field(
          label: 'Titre',
          controller: _title,
          hint: 'Ex : Médina, fragments',
          capitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 8),
        _Field(
          label: 'Technique',
          controller: _technique,
          hint: 'Ex : Techniques mixtes, poterie...',
          capitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Field(
                label: 'Longueur',
                controller: _length,
                hint: 'L cm',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Field(
                label: 'Hauteur',
                controller: _height,
                hint: 'H cm',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Field(
          label: 'Tags',
          controller: _tags,
          hint: 'Ex  #peinture, #moderne',
          minLines: 3,
        ),
        const SizedBox(height: 22),
        _Field(
          label: 'Description (caption)',
          controller: _description,
          hint: 'Le contexte ou l’histoire derrière cette création...',
          minLines: 5,
          capitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  // ── 3/4 Information (disponibilité & prix) ──

  Widget _buildSale() {
    final sel = _availability;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('DÉTAILS DE L’ŒUVRE'),
        const SizedBox(height: 34),
        _OptionCard(
          icon: Icons.menu_book_outlined,
          iconBg: const Color(0xFFEADFBE),
          iconFg: const Color(0xFF55688A),
          title: 'Exposition seule',
          subtitle: 'Non destinée à la vente',
          selected: sel == _Availability.exhibition,
          dimmed: sel != null && sel != _Availability.exhibition,
          onTap: () => setState(() => _availability = _Availability.exhibition),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          icon: Icons.add,
          iconBg: const Color(0xFFFDEFD9),
          iconFg: const Color(0xFFE8A06A),
          title: 'Ouverte aux propositions',
          subtitle: 'Prix fixe ou négociable',
          selected: sel == _Availability.open,
          dimmed: sel != null && sel != _Availability.open,
          onTap: () => setState(() => _availability = _Availability.open),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          icon: Icons.check,
          iconBg: const Color(0xFFFBE3E0),
          iconFg: _P.coral,
          title: 'Déjà vendue',
          subtitle: 'Visible mais non disponible',
          selected: sel == _Availability.sold,
          dimmed: sel != null && sel != _Availability.sold,
          onTap: () => setState(() => _availability = _Availability.sold),
        ),
        const SizedBox(height: 30),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: sel == _Availability.open
              ? _buildOfferPanel()
              : _InfoCard(
                  text: sel == _Availability.sold
                      ? 'Aucun prix à renseigner — cette œuvre est déjà '
                          'vendue et sera marquée comme non disponible.'
                      : 'Aucun prix à renseigner — cette œuvre n’est pas '
                          'mise en vente.',
                ),
        ),
      ],
    );
  }

  Widget _buildOfferPanel() {
    final negotiable = _pricing == _Pricing.negotiable;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29273A56),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _PricingToggle(
                  title: 'Prix fixe',
                  subtitle: 'Pas de négociation',
                  selected: !negotiable,
                  onTap: () => setState(() => _pricing = _Pricing.fixed),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PricingToggle(
                  title: 'Négociable',
                  subtitle: 'Les visiteurs proposent',
                  selected: negotiable,
                  onTap: () => setState(() => _pricing = _Pricing.negotiable),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF4ECD8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsFormatter()],
                    cursorColor: _P.navy,
                    style: _T.playfair(19),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Prix de départ',
                      hintStyle: _T.poppins(12, color: _P.grey),
                    ),
                  ),
                ),
                Text('MAD', style: _T.poppins(9.5, color: _P.grey)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            negotiable
                ? 'C’est votre prix de départ. Les visiteurs pourront vous '
                    'faire des propositions ; vous restez libre d’accepter, '
                    'refuser ou contre-proposer.'
                : 'C’est votre prix définitif. Les visiteurs ne pourront pas '
                    'faire de proposition.',
            style: _T.poppins(9, color: _P.olive, height: 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFC9DAF3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline,
                      size: 12, color: Color(0xFF3F5F8F)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    negotiable
                        ? 'Le bouton "Faire une offre" apparaîtra sur votre '
                            'fiche œuvre.'
                        : 'Le prix affiché sur votre fiche œuvre sera '
                            'définitif.',
                    style: _T.poppins(9, color: const Color(0xFF3F5F8F),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4/4 Vérification ──

  Widget _buildReview() {
    final tags = _tagList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('DÉTAILS DE L’ŒUVRE'),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: _P.shadow, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 104,
                  width: double.infinity,
                  child: _CoverImage(
                    path: _photos.isEmpty ? null : _photos.first,
                    placeholder: _P.steelPlaceholder,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _title.text.trim(),
                style: _T.poppins(13, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              for (final line in [
                '${_technique.text.trim()} · $_year',
                widget.artistLocation,
                _availabilityText,
              ])
                if (line.trim().isNotEmpty)
                  Text(line, style: _T.poppins(9.5, height: 1.6)),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _P.cream,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          t,
                          style: _T.poppins(8.5,
                              weight: FontWeight.w500, color: _P.brown),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _certified = !_certified),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: _P.shadow, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _Checkbox(checked: _certified),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'J’atteste être l’auteur de cette œuvre',
                        style: _T.poppins(10.5, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Je certifie sur l’honneur que cette création est '
                        'originale et m’appartient. Une fausse déclaration '
                        'peut entraîner la suspension du compte.',
                        style: _T.poppins(9, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Confirmation ──

  Widget _buildConfirmation() {
    final width = MediaQuery.sizeOf(context).width;
    final pad = (width * 0.12).clamp(24.0, 52.0);
    final line1 = [
      '${_technique.text.trim()} · $_year',
      widget.artistLocation,
    ].where((s) => s.trim().isNotEmpty).join(' · ');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8CA7D2), Color(0xFFC9DEF4), Colors.white],
            stops: [0.0, 0.3, 0.62],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text('CONFIRMATION', style: _T.cinzel(15)),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x2E273A56),
                                blurRadius: 14,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: _P.coral, size: 30),
                        ),
                        const SizedBox(height: 18),
                        Text('Œuvre publiée !', style: _T.playfair(20)),
                        const SizedBox(height: 8),
                        Text(
                          'Votre œuvre est visible immédiatement. Une '
                          'vérification rapide suit sous 24h.',
                          textAlign: TextAlign.center,
                          style: _T.poppins(10, color: _P.grey, height: 1.55),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26578BC8),
                                blurRadius: 14,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 112,
                                width: double.infinity,
                                child: _CoverImage(
                                  path:
                                      _photos.isEmpty ? null : _photos.first,
                                  placeholder: const Color(0xFF22395A),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 12, 14, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_title.text.trim(),
                                        style: _T.playfair(13)),
                                    const SizedBox(height: 4),
                                    Text(line1,
                                        style: _T.poppins(9,
                                            color: _P.grey, height: 1.5)),
                                    Text(_availabilityText,
                                        style: _T.poppins(9,
                                            color: _P.grey, height: 1.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(pad - 8, 8, pad - 8, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OutlineButton(
                      label: 'Retour à mon profil',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 12),
                    _PrimaryButton(
                      label: 'Voir mon œuvre',
                      onPressed: widget.onViewArtwork ??
                          () => Navigator.of(context).maybePop(),
                    ),
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

// ───────────────────────── Décor & en-tête ─────────────────────────

/// Fond de la maquette : bandeau bleu acier en haut, nuages bleus flous.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8EA8D2),
                Color(0xFFBFD8F2),
                Color(0xFFE3EFFB),
                Color(0xFFF4F9FE),
                Color(0xFFD9E9F9),
              ],
              stops: [0.0, 0.14, 0.32, 0.62, 1.0],
            ),
          ),
        ),
        Positioned(left: -130, top: 200, child: _Blob(300, Color(0xFFA9CBEF))),
        Positioned(
            right: -150, bottom: -70, child: _Blob(380, Color(0xFFA9CBEF))),
        Positioned(
            right: -80, top: 250, child: _Blob(220, Color(0xFFFFFFFF))),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.serif,
    required this.step,
    required this.onBack,
  });

  final String title;
  final bool serif;
  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Retour',
              onPressed: onBack,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: serif
                  ? _T.cinzel(15)
                  : _T.poppins(20,
                      weight: FontWeight.w600, color: Colors.white),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$step / 4',
                  style: _T.poppins(10.5,
                      weight: FontWeight.w500, color: _P.grey)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: Colors.white.withValues(alpha: 0.7)),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    alignment: Alignment.centerLeft,
                    widthFactor: step / 4,
                    child: const ColoredBox(color: _P.steel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: _T.poppins(10.5,
            weight: FontWeight.w700, color: _P.steel, spacing: 0.3),
      );
}

// ───────────────────────── Champs & cartes ─────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    final multi = minLines > 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(color: _P.shadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: _T.poppins(8.5,
                weight: FontWeight.w500, color: _P.grey, spacing: 0.3),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: multi ? null : 1,
            keyboardType:
                keyboardType ?? (multi ? TextInputType.multiline : null),
            textCapitalization: capitalization,
            cursorColor: _P.navy,
            style: _T.poppins(13, weight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 3, bottom: 2),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: _T.poppins(12.5, weight: FontWeight.w500, color: _P.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: dimmed ? 0.5 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: dimmed
                  ? null
                  : const [
                      BoxShadow(
                          color: _P.shadow,
                          blurRadius: 12,
                          offset: Offset(0, 4)),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconFg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: _T.poppins(11.5, weight: FontWeight.w600)),
                      const SizedBox(height: 1),
                      Text(subtitle,
                          style: _T.poppins(8.5, color: _P.olive)),
                    ],
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _P.steel, width: 1.5),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: _P.steel,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PricingToggle extends StatelessWidget {
  const _PricingToggle({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected ? null : Colors.white,
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A7FAF), Color(0xFF6B8DB8)],
                )
              : null,
          border: selected
              ? null
              : Border.all(color: const Color(0xFFE9D9A8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: _T.poppins(10.5,
                  weight: FontWeight.w700,
                  color: selected ? Colors.white : _P.ink),
            ),
            Text(
              subtitle,
              style: _T.poppins(7.5,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : _P.olive),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: _P.shadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: _T.poppins(9.5, color: _P.olive, height: 1.55),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: checked ? const Color(0xFF4A7FAF) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: checked ? const Color(0xFF4A7FAF) : _P.navy,
          width: 1.6,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}

// ───────────────────────── Photos ─────────────────────────

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.size,
    required this.path,
    required this.isMain,
    required this.onTap,
    required this.onRemove,
  });

  final double size;
  final String path;
  final bool isMain;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: _P.steelPlaceholder),
              ),
            ),
            if (isMain)
              Positioned(
                left: 5,
                top: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('★ Principale',
                      style: _T.poppins(7.5,
                          weight: FontWeight.w600, color: _P.coral)),
                ),
              ),
            Positioned(
              right: 5,
              top: 5,
              child: Tooltip(
                message: 'Retirer la photo',
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E3B4E),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, size: 11, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.path, required this.placeholder});
  final String? path;
  final Color placeholder;

  @override
  Widget build(BuildContext context) {
    if (path == null) return ColoredBox(color: placeholder);
    return Image.file(
      File(path!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(color: placeholder),
    );
  }
}

/// Rectangle arrondi à bordure pointillée.
class _Dashed extends StatelessWidget {
  const _Dashed({
    required this.child,
    required this.color,
    required this.radius,
    this.fill,
  });

  final Widget child;
  final Color color;
  final double radius;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedPainter(color: color, radius: radius),
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 3), paint);
        d += 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) =>
      old.color != color || old.radius != radius;
}

// ───────────────────────── Boutons ─────────────────────────

/// Corail plein quand actif, dégradé corail pâle quand désactivé (maquette).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: enabled || busy ? _P.coral : null,
          gradient: enabled || busy
              ? null
              : const LinearGradient(
                  colors: [_P.coralSoftA, _P.coralSoftB],
                ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(label,
                        style: _T.poppins(14,
                            weight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _P.navy, width: 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onPressed,
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: Center(
              child: Text(label,
                  style: _T.poppins(12, weight: FontWeight.w600, color: _P.navy)),
            ),
          ),
        ),
      ),
    );
  }
}