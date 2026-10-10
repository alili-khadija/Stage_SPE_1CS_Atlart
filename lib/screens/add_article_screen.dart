import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_session.dart';
import '../services/auth_api.dart';
import '../services/oeuvre_api.dart';
import '../theme/atlart_layout.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_logo_step_header.dart';
import '../widgets/atlart_ui_widgets.dart';
import '../widgets/offers_ui.dart' show AtlartOffersBottomNav;
import 'artisan_nav.dart';

// ===========================================================================
// MODÈLE (renvoyé au profil artisan via Navigator.pop)
// ===========================================================================

enum ArticleAvailability { inStock, madeToOrder, unique }

enum ReturnPolicy { none, days7, days14 }

/// Un modèle d'un même article (taille, couleur, motif…).
class ArticleVariant {
  ArticleVariant({this.name = '', this.quantity = 1, this.priceExtra = 0});

  String name;
  int quantity;

  /// Supplément de prix par rapport au prix de base (0 = même prix).
  int priceExtra;

  ArticleVariant copy() =>
      ArticleVariant(name: name, quantity: quantity, priceExtra: priceExtra);
}

class ArtisanArticle {
  const ArtisanArticle({
    // --- champs d'origine (le profil artisan les utilise déjà) ---
    required this.name,
    required this.category,
    required this.model,
    required this.quantity,
    required this.price,
    required this.currency,
    required this.description,
    this.photoPath,
    this.contactPhone,
    // --- nouveaux champs métier ---
    this.photoPaths = const [],
    this.materials = const [],
    this.technique = '100 % fait main',
    this.origin,
    this.dimensions,
    this.weightKg,
    this.careInstructions,
    this.customizable = false,
    this.availability = ArticleAvailability.inStock,
    this.leadTimeDays,
    this.variants = const [],
    this.sku,
    this.lowStockAlert = 0,
    this.pickupAtWorkshop = true,
    this.homeDelivery = false,
    this.stopDesk = false,
    this.freeShipping = false,
    this.shippingFee,
    this.shipsAbroad = false,
    this.prepDays = 2,
    this.fragile = false,
    this.cashOnDelivery = false,
    this.returnPolicy = ReturnPolicy.none,
    this.backendId,
  });

  final String name;
  final String category;

  /// Liste des modèles séparés par une virgule (vide s'il n'y en a pas).
  final String model;

  /// Stock total (1 pour une pièce unique, 99 pour « sur commande »).
  final int quantity;
  final double price;
  final String currency;
  final String description;

  /// Photo principale (= première de [photoPaths]).
  final String? photoPath;
  final String? contactPhone;

  final List<String> photoPaths;
  final List<String> materials;
  final String technique;
  final String? origin;
  final String? dimensions;
  final double? weightKg;
  final String? careInstructions;
  final bool customizable;
  final ArticleAvailability availability;
  final int? leadTimeDays;
  final List<ArticleVariant> variants;
  final String? sku;
  final int lowStockAlert;
  final bool pickupAtWorkshop;
  final bool homeDelivery;
  final bool stopDesk;
  final bool freeShipping;
  final int? shippingFee;
  final bool shipsAbroad;
  final int prepDays;
  final bool fragile;
  final bool cashOnDelivery;
  final ReturnPolicy returnPolicy;
  final String? backendId;

  ArtisanArticle withBackendId(String id) => ArtisanArticle(
        name: name,
        category: category,
        model: model,
        quantity: quantity,
        price: price,
        currency: currency,
        description: description,
        photoPath: photoPath,
        contactPhone: contactPhone,
        photoPaths: photoPaths,
        materials: materials,
        technique: technique,
        origin: origin,
        dimensions: dimensions,
        weightKg: weightKg,
        careInstructions: careInstructions,
        customizable: customizable,
        availability: availability,
        leadTimeDays: leadTimeDays,
        variants: variants,
        sku: sku,
        lowStockAlert: lowStockAlert,
        pickupAtWorkshop: pickupAtWorkshop,
        homeDelivery: homeDelivery,
        stopDesk: stopDesk,
        freeShipping: freeShipping,
        shippingFee: shippingFee,
        shipsAbroad: shipsAbroad,
        prepDays: prepDays,
        fragile: fragile,
        cashOnDelivery: cashOnDelivery,
        returnPolicy: returnPolicy,
        backendId: id,
      );

  /// Libellé de stock prêt à afficher sur la carte du profil.
  String get stockLabel => switch (availability) {
    ArticleAvailability.unique => 'Pièce unique',
    ArticleAvailability.madeToOrder => 'Sur commande · ${leadTimeDays ?? 7} j',
    ArticleAvailability.inStock => '$quantity disponibles',
  };
}

// ===========================================================================
// DONNÉES MÉTIER
// ===========================================================================

const _kStepLabels = ['Photos', 'Détails', 'Stock', 'Prix', 'Aperçu'];
const _kStepTitles = [
  'Photos & nom',
  'Détails de l’article',
  'Stock & modèles',
  'Prix & livraison',
  'Aperçu & publication',
];

const _kMaxPhotos = 5;
const int _kMaxPhotoBytes = 8 * 1024 * 1024;
const _kMaxVariants = 8;
const _kMadeToOrderStock = 99;

const _kTechniques = [
  '100 % fait main',
  'Fait main avec outils',
  'Semi-artisanal',
];

/// Catégorie -> matériaux courants (suggestions).
const _kCategoryMaterials = <String, List<String>>{
  'Poterie & céramique': ['Argile', 'Terre cuite', 'Grès', 'Émail', 'Engobe'],
  'Tissage & tapis': ['Laine', 'Coton', 'Soie', 'Teintures naturelles', 'Lin'],
  'Cuivre & métal': ['Cuivre', 'Laiton', 'Fer forgé', 'Argent', 'Étain'],
  'Bois & sculpture': ['Cèdre', 'Olivier', 'Thuya', 'Noyer', 'Pin'],
  'Cuir & maroquinerie': ['Cuir de vachette', 'Cuir de chèvre', 'Peau d’agneau'],
  'Broderie & textile': ['Coton', 'Lin', 'Soie', 'Fil de soie', 'Fil d’or'],
  'Bijoux': ['Argent 925', 'Laiton', 'Perles', 'Corail', 'Pierres naturelles'],
  'Zellige & mosaïque': ['Terre cuite', 'Émail', 'Ciment', 'Pierre'],
  'Verre': ['Verre soufflé', 'Verre recyclé', 'Plomb'],
  'Vannerie': ['Palmier', 'Osier', 'Raphia', 'Jonc', 'Alfa'],
  'Décoration': ['Bois', 'Métal', 'Tissu', 'Pierre'],
  'Autre': ['Bois', 'Métal', 'Tissu', 'Pierre'],
};

/// Catégories fragiles : on propose d'office l'emballage renforcé.
const _kFragileCategories = {
  'Poterie & céramique',
  'Verre',
  'Zellige & mosaïque',
};

const _kLeadTimes = [3, 7, 14, 21, 30];
const _kPrepDays = [1, 2, 3, 5, 7];
const _kMargins = [20, 30, 50];
const _kCurrencies = ['DT', 'MAD', 'DZD'];

class _CountryInfo {
  const _CountryInfo(this.flag, this.dial, this.currency);

  final String flag;
  final String dial;
  final String currency;
}

const _kCountries = {
  'TN': _CountryInfo('🇹🇳', '+216', 'DT'),
  'MA': _CountryInfo('🇲🇦', '+212', 'MAD'),
  'DZ': _CountryInfo('🇩🇿', '+213', 'DZD'),
  'LY': _CountryInfo('🇱🇾', '+218', 'DT'),
  'MR': _CountryInfo('🇲🇷', '+222', 'MAD'),
};

// ---------------------------------------------------------------------------
// Style (Figma)
// ---------------------------------------------------------------------------

const _kFieldFill = Color(0xFFDCEBFB);
const _kLabel = Color(0xFF7A8CA3);
const _kError = Color(0xFFE86B69);
const _kErrorFill = Color(0xFFFDECEB);
const _kErrorBorder = Color(0xFFF28B8B);
const _kOverlayText = Color(0xFF2E5C8A);
const _kLine = Color(0xFFD5E4F4);
const _kTipFill = Color(0xFFEAF3FC);
const _kOk = Color(0xFF2A9D70);

const _labelStyle = TextStyle(
  color: _kLabel,
  fontSize: 9,
  height: 1.2,
  fontFamily: 'Poppins',
);

const _valueStyle = TextStyle(
  color: AtlartPalette.navy,
  fontSize: 12.5,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w600,
);

const _hintStyle = TextStyle(
  color: Color(0xFFA9B4C2),
  fontSize: 12.5,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w400,
);

const _bodyStyle = TextStyle(
  color: AtlartPalette.navyDark,
  fontSize: 11,
  height: 1.5,
  fontFamily: 'Poppins',
);

// ===========================================================================
// ÉTAT DU FORMULAIRE + BROUILLON
// ===========================================================================

class _FormData {
  List<String> photos = [];
  String? category;
  Set<String> materials = {};
  String technique = _kTechniques.first;
  bool customizable = false;

  ArticleAvailability availability = ArticleAvailability.inStock;
  int qty = 1;
  int leadTimeDays = 7;
  bool hasVariants = false;
  List<ArticleVariant> variants = [];
  int lowStock = 0;

  String currency = 'DT';
  bool pickup = true;
  bool home = true;
  bool stopDesk = false;
  bool freeShipping = false;
  bool abroad = false;
  int prepDays = 2;
  bool cod = false;
  bool fragile = false;
  ReturnPolicy returns = ReturnPolicy.none;

  _FormData copy() {
    final c = _FormData();
    c.photos = List.of(photos);
    c.category = category;
    c.materials = Set.of(materials);
    c.technique = technique;
    c.customizable = customizable;
    c.availability = availability;
    c.qty = qty;
    c.leadTimeDays = leadTimeDays;
    c.hasVariants = hasVariants;
    c.variants = variants.map((v) => v.copy()).toList();
    c.lowStock = lowStock;
    c.currency = currency;
    c.pickup = pickup;
    c.home = home;
    c.stopDesk = stopDesk;
    c.freeShipping = freeShipping;
    c.abroad = abroad;
    c.prepDays = prepDays;
    c.cod = cod;
    c.fragile = fragile;
    c.returns = returns;
    return c;
  }
}

class _Draft {
  _Draft({required this.texts, required this.data, required this.step});

  final Map<String, String> texts;
  final _FormData data;
  final int step;
}

/// Brouillon gardé en mémoire pendant la session.
/// À remplacer plus tard par shared_preferences ou par `oeuvre.brouillon` côté API.
class _DraftStore {
  static _Draft? current;
}

enum _FormResult { none, success, error }

enum _Leave { save, discard, stay }

// ===========================================================================
// ÉCRAN
// ===========================================================================

class AddArticleScreen extends StatefulWidget {
  const AddArticleScreen({
    super.key,
    this.navIndex = 3,
    this.step = 2,
    this.totalSteps = 4,
  });

  final int navIndex;

  /// Conservés pour compatibilité : l'assistant gère maintenant ses 5 étapes.
  final int step;
  final int totalSteps;

  @override
  State<AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<AddArticleScreen> {
  static const _textKeys = [
    'name',
    'origin',
    'description',
    'care',
    'dimL',
    'dimW',
    'dimH',
    'weight',
    'sku',
    'price',
    'fee',
    'phone',
    'material',
  ];

  /// Ordre des champs par étape (pour défiler jusqu'à la première erreur).
  static const _errorOrder = [
    ['photos', 'name'],
    ['category', 'materials', 'description'],
    ['variants'],
    ['price', 'delivery', 'weight', 'fee', 'phone'],
    <String>[],
  ];

  final Map<String, TextEditingController> _t = {
    for (final k in _textKeys) k: TextEditingController(),
  };
  final Map<String, GlobalKey> _keys = {};
  final _picker = ImagePicker();

  var _d = _FormData();
  int _step = 0;
  int _maxStep = 0;
  final Map<String, String> _err = {};
  bool _saving = false;
  _FormResult _result = _FormResult.none;
  ArtisanArticle? _created;

  _CountryInfo get _country =>
      _kCountries[AtlartSession.instance.user?.paysCode?.toUpperCase()] ??
      _kCountries['TN']!;

  GlobalKey _key(String id) => _keys.putIfAbsent(id, () => GlobalKey());

  bool get _dirty =>
      _d.photos.isNotEmpty ||
      _d.category != null ||
      _d.materials.isNotEmpty ||
      ['name', 'description', 'price'].any((k) => _t[k]!.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    final country = _country;
    _d.currency = _kCurrencies.contains(country.currency)
        ? country.currency
        : _kCurrencies.first;
    // Le paiement à la livraison est la norme en Algérie.
    _d.cod = AtlartSession.instance.user?.paysCode?.toUpperCase() == 'DZ';

    final ville = AtlartSession.instance.user?.ville;
    if (ville != null && ville.trim().isNotEmpty) {
      _t['origin']!.text = ville.trim();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraft());
  }

  @override
  void dispose() {
    for (final c in _t.values) {
      c.dispose();
    }
    super.dispose();
  }

  // --- Outils --------------------------------------------------------------

  String _text(String key) => _t[key]!.text.trim();

  void _msg(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearErr(String key) {
    if (_err.containsKey(key)) setState(() => _err.remove(key));
  }

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      if (step > _maxStep) _maxStep = step;
      _err.clear();
    });
  }

  // --- Brouillon -----------------------------------------------------------

  void _saveDraft({bool announce = true}) {
    _DraftStore.current = _Draft(
      texts: {for (final e in _t.entries) e.key: e.value.text},
      data: _d.copy(),
      step: _step,
    );
    if (announce) _msg('Brouillon enregistré.');
  }

  void _restoreDraft(_Draft draft) {
    for (final e in draft.texts.entries) {
      _t[e.key]?.text = e.value;
    }
    setState(() {
      _d = draft.data.copy();
      _step = draft.step;
      _maxStep = draft.step;
    });
  }

  Future<void> _offerDraft() async {
    final draft = _DraftStore.current;
    if (draft == null || !mounted) return;
    final name = draft.texts['name']?.trim() ?? '';
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Reprendre votre brouillon ?'),
        content: Text(
          name.isEmpty
              ? 'Vous avez un article en cours de création.'
              : 'Vous avez un article en cours : « $name ».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nouvel article'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reprendre'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      _restoreDraft(draft);
    } else {
      _DraftStore.current = null;
    }
  }

  // --- Photos --------------------------------------------------------------

  Future<void> _addPhotos() async {
    final room = _kMaxPhotos - _d.photos.length;
    if (room <= 0) {
      _msg('$_kMaxPhotos photos maximum.');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final List<XFile> files;
      if (source == ImageSource.gallery) {
        files = await _picker.pickMultiImage(maxWidth: 1800, imageQuality: 85);
      } else {
        final shot = await _picker.pickImage(
          source: source,
          maxWidth: 1800,
          imageQuality: 85,
        );
        files = shot == null ? <XFile>[] : [shot];
      }

      var tooBig = false;
      final added = <String>[];
      for (final file in files.take(room)) {
        if (await file.length() > _kMaxPhotoBytes) {
          tooBig = true;
          continue;
        }
        if (!_d.photos.contains(file.path)) added.add(file.path);
      }
      if (!mounted) return;
      setState(() {
        _d.photos.addAll(added);
        if (added.isNotEmpty) _err.remove('photos');
      });
      if (tooBig) {
        _msg('Une image dépasse 8 Mo et a été ignorée.');
      } else if (files.length > room) {
        _msg('$_kMaxPhotos photos maximum : les suivantes sont ignorées.');
      }
    } on PlatformException {
      if (!mounted) return;
      _msg('Impossible d’ouvrir les photos. Réessayez.');
    }
  }

  // --- Validation ----------------------------------------------------------

  Map<String, String> _validate(int step) {
    final e = <String, String>{};

    if (step == 0) {
      if (_d.photos.isEmpty) e['photos'] = 'Ajoutez au moins une photo.';
      final name = _text('name');
      if (name.isEmpty) {
        e['name'] = 'Donnez un nom à votre article.';
      } else if (name.length < 3) {
        e['name'] = 'Le nom est trop court.';
      }
    } else if (step == 1) {
      if (_d.category == null) e['category'] = 'Choisissez une catégorie.';
      if (_d.materials.isEmpty) e['materials'] = 'Indiquez au moins un matériau.';
      if (_text('description').length < 20) {
        e['description'] = 'Décrivez votre article (20 caractères minimum).';
      }
    } else if (step == 2) {
      if (_d.availability != ArticleAvailability.unique && _d.hasVariants) {
        final vs = _d.variants;
        if (vs.isEmpty) {
          e['variants'] = 'Ajoutez au moins un modèle ou désactivez l’option.';
        } else if (vs.any((v) => v.name.trim().isEmpty)) {
          e['variants'] = 'Donnez un nom à chaque modèle.';
        } else if (vs.map((v) => v.name.trim().toLowerCase()).toSet().length !=
            vs.length) {
          e['variants'] = 'Deux modèles portent le même nom.';
        } else if (_d.availability == ArticleAvailability.inStock &&
            vs.every((v) => v.quantity <= 0)) {
          e['variants'] = 'Au moins un modèle doit avoir du stock.';
        }
      }
    } else if (step == 3) {
      final price = int.tryParse(_text('price'));
      if (price == null || price <= 0) {
        e['price'] = 'Saisissez un prix supérieur à zéro.';
      }
      if (!_d.pickup && !_d.home && !_d.stopDesk) {
        e['delivery'] = 'Choisissez au moins un mode de remise.';
      }
      if (_d.home || _d.stopDesk) {
        final weight = double.tryParse(_text('weight').replaceAll(',', '.'));
        if (weight == null || weight <= 0) {
          e['weight'] = 'Indiquez le poids emballé (en kg).';
        }
        if (!_d.freeShipping) {
          final fee = int.tryParse(_text('fee'));
          if (fee == null || fee <= 0) {
            e['fee'] = 'Indiquez les frais, ou activez « Livraison offerte ».';
          }
        }
      }
      final digits = _text('phone').replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty && (digits.length < 8 || digits.length > 10)) {
        e['phone'] = 'Numéro invalide.';
      }
    }
    return e;
  }

  void _showErrors(Map<String, String> errors, int step) {
    setState(() {
      _err
        ..clear()
        ..addAll(errors);
    });
    HapticFeedback.lightImpact();
    final first = _errorOrder[step].firstWhere(
      errors.containsKey,
      orElse: () => '',
    );
    if (first.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[first]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          alignment: 0.1,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _next() {
    FocusScope.of(context).unfocus();
    final errors = _validate(_step);
    if (errors.isNotEmpty) {
      _showErrors(errors, _step);
      return;
    }
    _goTo(_step + 1);
  }

  // --- Publication ---------------------------------------------------------

  ArtisanArticle _buildArticle() {
    final availability = _d.availability;
    final variants =
        availability != ArticleAvailability.unique && _d.hasVariants
        ? _d.variants.map((v) => v.copy()).toList()
        : <ArticleVariant>[];

    final quantity = switch (availability) {
      ArticleAvailability.unique => 1,
      ArticleAvailability.madeToOrder => _kMadeToOrderStock,
      ArticleAvailability.inStock =>
        variants.isEmpty
            ? _d.qty
            : variants.fold<int>(0, (sum, v) => sum + v.quantity),
    };

    final dims = [_text('dimL'), _text('dimW'), _text('dimH')];
    final dimensions = dims.every((x) => x.isEmpty)
        ? null
        : '${dims.map((x) => x.isEmpty ? '–' : x).join(' × ')} cm';

    final phoneDigits = _text('phone').replaceAll(RegExp(r'\D'), '');
    final delivers = _d.home || _d.stopDesk;

    return ArtisanArticle(
      name: _text('name'),
      category: _d.category ?? 'Artisanat',
      model: variants.map((v) => v.name.trim()).join(', '),
      quantity: quantity,
      price: int.parse(_text('price')).toDouble(),
      currency: _d.currency,
      description: _text('description'),
      photoPath: _d.photos.isEmpty ? null : _d.photos.first,
      contactPhone: phoneDigits.isEmpty
          ? null
          : '${_country.dial} ${_text('phone')}',
      photoPaths: List.of(_d.photos),
      materials: _d.materials.toList(),
      technique: _d.technique,
      origin: _text('origin').isEmpty ? null : _text('origin'),
      dimensions: dimensions,
      weightKg: double.tryParse(_text('weight').replaceAll(',', '.')),
      careInstructions: _text('care').isEmpty ? null : _text('care'),
      customizable: _d.customizable,
      availability: availability,
      leadTimeDays: availability == ArticleAvailability.madeToOrder
          ? _d.leadTimeDays
          : null,
      variants: variants,
      sku: _text('sku').isEmpty ? null : _text('sku'),
      lowStockAlert: availability == ArticleAvailability.inStock
          ? _d.lowStock
          : 0,
      pickupAtWorkshop: _d.pickup,
      homeDelivery: _d.home,
      stopDesk: _d.stopDesk,
      freeShipping: delivers && _d.freeShipping,
      shippingFee: delivers && !_d.freeShipping
          ? int.tryParse(_text('fee'))
          : null,
      shipsAbroad: delivers && _d.abroad,
      prepDays: availability == ArticleAvailability.inStock ? _d.prepDays : 0,
      fragile: _d.fragile,
      cashOnDelivery: _d.cod,
      returnPolicy: _d.returns,
    );
  }

  Future<void> _publish() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    for (var s = 0; s < 4; s++) {
      final errors = _validate(s);
      if (errors.isNotEmpty) {
        _goTo(s);
        _showErrors(errors, s);
        _msg('Il manque des informations à l’étape ${s + 1}.');
        return;
      }
    }

    setState(() {
      _saving = true;
      _result = _FormResult.none;
    });

    try {
      final saved = await _saveArticle(_buildArticle());
      if (!mounted) return;
      _DraftStore.current = null;
      setState(() {
        _created = saved;
        _saving = false;
        _result = _FormResult.success;
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'article creation',
        ),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _saving = false;
        _result = _FormResult.error;
      });
    }
  }

  Future<ArtisanArticle> _saveArticle(ArtisanArticle article) async {
    if (!AuthApi.useBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return article;
    }
    final id = await OeuvreApi.publishArtisanArticle(
      article: {
        'titre': article.name,
        'categorie': 'ARTISANAT',
        'categorie_detaillee': article.category,
        'modele': article.model,
        'quantite_disponible': article.quantity,
        'devise': article.currency,
        'technique': article.technique,
        'dimensions': article.dimensions,
        'description': article.description,
        'prix_fixe': 'FIXE',
        'prix_depart': article.price,
        'disponibilite': 'OUVERTE_PROPOSITIONS',
        'details_commerce': {
          'materials': article.materials,
          'origin': article.origin,
          'weight_kg': article.weightKg,
          'care_instructions': article.careInstructions,
          'customizable': article.customizable,
          'availability': article.availability.name,
          'lead_time_days': article.leadTimeDays,
          'variants': [
            for (final variant in article.variants)
              {
                'name': variant.name,
                'quantity': variant.quantity,
                'price_extra': variant.priceExtra,
              },
          ],
          'sku': article.sku,
          'low_stock_alert': article.lowStockAlert,
          'pickup_at_workshop': article.pickupAtWorkshop,
          'home_delivery': article.homeDelivery,
          'stop_desk': article.stopDesk,
          'free_shipping': article.freeShipping,
          'shipping_fee': article.shippingFee,
          'ships_abroad': article.shipsAbroad,
          'prep_days': article.prepDays,
          'fragile': article.fragile,
          'cash_on_delivery': article.cashOnDelivery,
          'return_policy': article.returnPolicy.name,
        },
      },
      photoPaths: article.photoPaths,
    );
    return article.withBackendId(id);
  }

  void _closeOverlay() => setState(() => _result = _FormResult.none);

  void _dismissSuccess() => Navigator.of(context).pop(_created);

  void _retry() {
    setState(() => _result = _FormResult.none);
    _publish();
  }

  // --- Navigation ----------------------------------------------------------

  Future<_Leave> _askLeave() async {
    final choice = await showDialog<_Leave>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la création ?'),
        content: const Text(
          'Vous pouvez enregistrer un brouillon pour reprendre plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_Leave.stay),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_Leave.discard),
            child: const Text('Abandonner'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(_Leave.save),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    return choice ?? _Leave.stay;
  }

  Future<void> _handleBack() async {
    if (_result == _FormResult.success) {
      _dismissSuccess();
      return;
    }
    if (_result == _FormResult.error) {
      _closeOverlay();
      return;
    }
    if (_saving) return;
    if (_step > 0) {
      _goTo(_step - 1);
      return;
    }
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final choice = await _askLeave();
    if (!mounted) return;
    if (choice == _Leave.save) {
      _saveDraft(announce: false);
      Navigator.of(context).pop();
    } else if (choice == _Leave.discard) {
      Navigator.of(context).pop();
    }
  }

  void _handleNavigationTap(int index) {
    if (index == widget.navIndex) {
      _handleBack();
      return;
    }
    handleArtisanNavTap(context, index: index, current: widget.navIndex);
  }

  // =========================================================================
  // INTERFACE
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final overlay = _result != _FormResult.none;
    final last = _step == 4;

    return PopScope<void>(
      canPop: _result == _FormResult.none && !_saving && _step == 0 && !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _WizardHeader(
              step: _step,
              maxStep: _maxStep,
              onBack: _handleBack,
              onStepTap: _goTo,
            ),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: AtlartCloudBackground()),
                  IgnorePointer(
                    ignoring: overlay,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: ListView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(
                              AtlartLayout.pageHPadding,
                              14,
                              AtlartLayout.pageHPadding,
                              24,
                            ),
                            children: switch (_step) {
                              0 => _stepPhotos(),
                              1 => _stepDetails(),
                              2 => _stepStock(),
                              3 => _stepPriceDelivery(),
                              _ => _stepPreview(),
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_result == _FormResult.success)
                    Positioned(
                      left: 14,
                      right: 14,
                      top: 14,
                      bottom: 14,
                      child: _ResultOverlay(
                        message:
                            'Votre article « ${_created?.name ?? ''} » a été '
                            'publié avec succès. Merci pour votre confiance.',
                        icon: Icons.check_rounded,
                        actionLabel: 'Terminer',
                        onClose: _dismissSuccess,
                        onBack: _dismissSuccess,
                        onAction: _dismissSuccess,
                      ),
                    ),
                  if (_result == _FormResult.error)
                    Positioned(
                      left: 14,
                      right: 14,
                      top: 14,
                      bottom: 14,
                      child: _ResultOverlay(
                        message:
                            'Une erreur s’est produite, merci de réessayer '
                            'ultérieurement.',
                        icon: Icons.close_rounded,
                        actionLabel: 'Réessayer',
                        onClose: _closeOverlay,
                        onBack: _closeOverlay,
                        onAction: _retry,
                      ),
                    ),
                ],
              ),
            ),
            if (!overlay)
              _ActionBar(
                secondaryLabel: last ? 'Brouillon' : (_step > 0 ? 'Retour' : null),
                onSecondary: last ? _saveDraft : _handleBack,
                primaryLabel: last ? 'Publier l’article' : 'Continuer',
                onPrimary: last ? _publish : _next,
                loading: _saving,
              ),
          ],
        ),
        bottomNavigationBar: AtlartOffersBottomNav(
          currentIndex: widget.navIndex,
          onTap: _handleNavigationTap,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Étape 1 : photos & nom
  // ---------------------------------------------------------------------

  List<Widget> _stepPhotos() => [
    const _SectionTitle('PHOTOS'),
    const SizedBox(height: 10),
    KeyedSubtree(
      key: _key('photos'),
      child: _PhotoPicker(
        photos: _d.photos,
        max: _kMaxPhotos,
        errorText: _err['photos'],
        onAdd: _addPhotos,
        onRemove: (i) => setState(() => _d.photos.removeAt(i)),
        onMakeCover: (i) => setState(() {
          _d.photos.insert(0, _d.photos.removeAt(i));
        }),
      ),
    ),
    const SizedBox(height: 10),
    const _Tip(
      'Les acheteurs regardent d’abord les photos. Prenez la pièce de face, '
      'puis un détail, l’échelle (posée sur une main ou un meuble) et l’article '
      'en situation. Touchez une miniature pour en faire la photo principale.',
    ),
    const SizedBox(height: 22),
    const _SectionTitle('NOM DE L’ARTICLE'),
    const SizedBox(height: 10),
    KeyedSubtree(
      key: _key('name'),
      child: _TField(
        label: 'Nom de l’article *',
        controller: _t['name']!,
        hint: 'Ex. Vase en argile peint à la main',
        errorText: _err['name'],
        maxLength: 80,
        onChanged: (_) => _clearErr('name'),
      ),
    ),
    const SizedBox(height: 8),
    const _Tip(
      'Dites d’abord ce que c’est, puis la matière ou le style : '
      '« Tapis berbère en laine, motifs losanges ».',
    ),
  ];

  // ---------------------------------------------------------------------
  // Étape 2 : détails
  // ---------------------------------------------------------------------

  List<Widget> _stepDetails() {
    final category = _d.category;
    final suggestions = category == null
        ? const <String>[]
        : (_kCategoryMaterials[category] ?? const <String>[]);
    final materialChips = [
      ...suggestions,
      ..._d.materials.where((m) => !suggestions.contains(m)),
    ];

    return [
      const _SectionTitle('CATÉGORIE'),
      const SizedBox(height: 10),
      KeyedSubtree(
        key: _key('category'),
        child: _Pills(
          options: _kCategoryMaterials.keys.toList(),
          isSelected: (c) => c == _d.category,
          onTap: (c) => setState(() {
            _d.category = c;
            _d.fragile = _kFragileCategories.contains(c);
            _err.remove('category');
          }),
          errorText: _err['category'],
        ),
      ),
      const SizedBox(height: 22),
      const _SectionTitle('MATÉRIAUX'),
      const SizedBox(height: 10),
      KeyedSubtree(
        key: _key('materials'),
        child: _Pills(
          options: materialChips,
          isSelected: _d.materials.contains,
          onTap: (m) => setState(() {
            if (!_d.materials.add(m)) _d.materials.remove(m);
            _err.remove('materials');
          }),
          errorText: _err['materials'],
          emptyHint: 'Choisissez d’abord une catégorie pour voir des suggestions.',
        ),
      ),
      const SizedBox(height: 10),
      _TField(
        label: 'Autre matériau',
        controller: _t['material']!,
        hint: 'Ex. Pigments naturels',
        suffix: IconButton(
          tooltip: 'Ajouter',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_rounded, color: AtlartPalette.coral),
          onPressed: _addCustomMaterial,
        ),
        onSubmitted: (_) => _addCustomMaterial(),
      ),
      const SizedBox(height: 22),
      const _SectionTitle('FABRICATION'),
      const SizedBox(height: 10),
      _Pills(
        options: _kTechniques,
        isSelected: (t) => t == _d.technique,
        onTap: (t) => setState(() => _d.technique = t),
      ),
      const SizedBox(height: 12),
      _TField(
        label: 'Ville ou région de fabrication',
        controller: _t['origin']!,
        hint: 'Ex. Nabeul',
        capitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 22),
      const _SectionTitle('DIMENSIONS (FACULTATIF)'),
      const SizedBox(height: 10),
      Row(
        children: [
          for (final item in const [
            ('dimL', 'Long. (cm)'),
            ('dimW', 'Larg. (cm)'),
            ('dimH', 'Haut. (cm)'),
          ])
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: item.$1 == 'dimH' ? 0 : 8),
                child: _TField(
                  label: item.$2,
                  controller: _t[item.$1]!,
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 22),
      const _SectionTitle('DESCRIPTION'),
      const SizedBox(height: 10),
      KeyedSubtree(
        key: _key('description'),
        child: _TField(
          label: 'Description *',
          controller: _t['description']!,
          hint: 'Ce que c’est, comment c’est fait, à quoi ça sert…',
          errorText: _err['description'],
          minLines: 4,
          maxLines: 6,
          maxLength: 600,
          onChanged: (_) => _clearErr('description'),
        ),
      ),
      const SizedBox(height: 8),
      const _Tip(
        'Précisez la matière, les dimensions, l’usage et le temps de '
        'fabrication. Un texte clair rassure l’acheteur et réduit les questions.',
      ),
      const SizedBox(height: 12),
      _TField(
        label: 'Conseils d’entretien (facultatif)',
        controller: _t['care']!,
        hint: 'Ex. Laver à la main, éviter le lave-vaisselle',
        maxLength: 120,
      ),
      const SizedBox(height: 12),
      _SwitchTile(
        title: 'Personnalisation possible',
        subtitle: 'Couleur, taille, gravure… sur demande de l’acheteur',
        icon: Icons.brush_outlined,
        value: _d.customizable,
        onChanged: (v) => setState(() => _d.customizable = v),
      ),
    ];
  }

  void _addCustomMaterial() {
    final value = _text('material');
    if (value.isEmpty) return;
    if (_d.materials.length >= 8) {
      _msg('8 matériaux maximum.');
      return;
    }
    setState(() {
      _d.materials.add(value);
      _err.remove('materials');
    });
    _t['material']!.clear();
  }

  // ---------------------------------------------------------------------
  // Étape 3 : stock & modèles
  // ---------------------------------------------------------------------

  List<Widget> _stepStock() {
    final availability = _d.availability;
    final inStock = availability == ArticleAvailability.inStock;
    final madeToOrder = availability == ArticleAvailability.madeToOrder;
    final totalStock = _d.variants.fold<int>(0, (sum, v) => sum + v.quantity);

    return [
      const _SectionTitle('DISPONIBILITÉ'),
      const SizedBox(height: 10),
      _OptionCard(
        icon: Icons.inventory_2_outlined,
        title: 'En stock',
        subtitle: 'J’ai des exemplaires prêts à partir.',
        selected: inStock,
        onTap: () => setState(() => _d.availability = ArticleAvailability.inStock),
      ),
      const SizedBox(height: 8),
      _OptionCard(
        icon: Icons.handyman_outlined,
        title: 'Sur commande',
        subtitle: 'Je fabrique l’article après la commande.',
        selected: madeToOrder,
        onTap: () =>
            setState(() => _d.availability = ArticleAvailability.madeToOrder),
      ),
      const SizedBox(height: 8),
      _OptionCard(
        icon: Icons.diamond_outlined,
        title: 'Pièce unique',
        subtitle: 'Un seul exemplaire existe.',
        selected: availability == ArticleAvailability.unique,
        onTap: () => setState(() {
          _d.availability = ArticleAvailability.unique;
          _d.hasVariants = false;
          _d.qty = 1;
        }),
      ),
      const SizedBox(height: 22),
      if (availability == ArticleAvailability.unique)
        const _Tip(
          'Une pièce unique est retirée de la vente dès qu’elle est vendue : '
          'aucun stock à gérer.',
        )
      else ...[
        const _SectionTitle('MODÈLES'),
        const SizedBox(height: 10),
        _SwitchTile(
          title: 'Plusieurs modèles',
          subtitle:
              'Taille, couleur, motif… regroupés dans une seule annonce '
              '(plutôt que plusieurs annonces séparées).',
          icon: Icons.palette_outlined,
          value: _d.hasVariants,
          onChanged: (v) => setState(() {
            _d.hasVariants = v;
            if (v && _d.variants.isEmpty) _d.variants.add(ArticleVariant());
            _err.remove('variants');
          }),
        ),
        if (_d.hasVariants) ...[
          const SizedBox(height: 10),
          KeyedSubtree(
            key: _key('variants'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _d.variants.length; i++)
                  _VariantRow(
                    key: ObjectKey(_d.variants[i]),
                    variant: _d.variants[i],
                    index: i,
                    showQty: inStock,
                    currency: _d.currency,
                    onChanged: () {
                      _clearErr('variants');
                      setState(() {});
                    },
                    onRemove: () => setState(() {
                      _d.variants.removeAt(i);
                      if (_d.variants.isEmpty) _d.hasVariants = false;
                    }),
                  ),
                if (_err['variants'] != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                    child: Text(_err['variants']!, style: _errorStyle),
                  ),
                if (_d.variants.length < _kMaxVariants)
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _d.variants.add(ArticleVariant())),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Ajouter un modèle'),
                    style: TextButton.styleFrom(
                      foregroundColor: AtlartPalette.coral,
                    ),
                  ),
                if (inStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 6),
                    child: Text(
                      'Stock total : $totalStock',
                      style: _bodyStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ] else if (inStock) ...[
          const SizedBox(height: 10),
          _StepperTile(
            title: 'Quantité disponible',
            subtitle: 'Exemplaires identiques en stock',
            value: _d.qty,
            min: 1,
            max: 9999,
            onChanged: (v) => setState(() => _d.qty = v),
          ),
        ],
        const SizedBox(height: 22),
        if (madeToOrder) ...[
          const _SectionTitle('DÉLAI DE FABRICATION'),
          const SizedBox(height: 10),
          _Pills(
            options: [for (final d in _kLeadTimes) '$d jours'],
            isSelected: (label) => label == '${_d.leadTimeDays} jours',
            onTap: (label) => setState(
              () => _d.leadTimeDays = int.parse(label.split(' ').first),
            ),
          ),
          const SizedBox(height: 8),
          const _Tip(
            'Ce délai est affiché à l’acheteur avant la commande. Soyez réaliste : '
            'mieux vaut annoncer 14 jours et livrer en 10.',
          ),
        ] else ...[
          const _SectionTitle('SUIVI DU STOCK'),
          const SizedBox(height: 10),
          _StepperTile(
            title: 'Alerte stock bas',
            subtitle: _d.lowStock == 0
                ? 'Désactivée'
                : 'Prévenez-moi quand il reste ${_d.lowStock} exemplaire(s) ou moins',
            value: _d.lowStock,
            min: 0,
            max: 99,
            onChanged: (v) => setState(() => _d.lowStock = v),
          ),
          const SizedBox(height: 10),
          _TField(
            label: 'Référence interne (facultatif)',
            controller: _t['sku']!,
            hint: 'Ex. POT-014',
            capitalization: TextCapitalization.characters,
            maxLength: 20,
            suffix: TextButton(
              onPressed: _generateSku,
              child: const Text('Générer'),
            ),
          ),
        ],
      ],
    ];
  }

  void _generateSku() {
    final letters = (_d.category ?? 'ART').replaceAll(RegExp(r'[^A-Za-z]'), '');
    final prefix = (letters.length >= 3 ? letters.substring(0, 3) : 'ART')
        .toUpperCase();
    final number = (DateTime.now().millisecondsSinceEpoch % 1000)
        .toString()
        .padLeft(3, '0');
    setState(() => _t['sku']!.text = '$prefix-$number');
  }

  // ---------------------------------------------------------------------
  // Étape 4 : prix & livraison
  // ---------------------------------------------------------------------

  List<Widget> _stepPriceDelivery() {
    final delivers = _d.home || _d.stopDesk;
    final inStock = _d.availability == ArticleAvailability.inStock;

    return [
      const _SectionTitle('PRIX'),
      const SizedBox(height: 10),
      _Pills(
        options: _kCurrencies,
        isSelected: (c) => c == _d.currency,
        onTap: (c) => setState(() => _d.currency = c),
      ),
      const SizedBox(height: 10),
      KeyedSubtree(
        key: _key('price'),
        child: _TField(
          label: 'Prix de vente (${_d.currency}) *',
          controller: _t['price']!,
          hint: 'Ex. 80',
          errorText: _err['price'],
          keyboardType: TextInputType.number,
          // Entiers seulement : la fiche produit lit le prix en entier.
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
          onChanged: (_) => _clearErr('price'),
        ),
      ),
      const SizedBox(height: 8),
      _PriceHelper(
        currency: _d.currency,
        onApply: (value) => setState(() {
          _t['price']!.text = '$value';
          _err.remove('price');
        }),
      ),
      const SizedBox(height: 8),
      const _Tip(
        'Votre prix doit couvrir les matériaux, votre temps, vos charges et une '
        'marge. N’y ajoutez pas la livraison : elle se règle plus bas.',
      ),
      const SizedBox(height: 22),
      const _SectionTitle('MODES DE REMISE'),
      const SizedBox(height: 10),
      KeyedSubtree(
        key: _key('delivery'),
        child: Column(
          children: [
            _SwitchTile(
              title: 'Retrait à l’atelier',
              subtitle: 'Gratuit : l’acheteur vient récupérer l’article',
              icon: Icons.storefront_outlined,
              value: _d.pickup,
              onChanged: (v) => setState(() {
                _d.pickup = v;
                _err.remove('delivery');
              }),
            ),
            const SizedBox(height: 8),
            _SwitchTile(
              title: 'Livraison à domicile',
              subtitle: 'Par transporteur, jusqu’à la porte',
              icon: Icons.local_shipping_outlined,
              value: _d.home,
              onChanged: (v) => setState(() {
                _d.home = v;
                _err.remove('delivery');
              }),
            ),
            const SizedBox(height: 8),
            _SwitchTile(
              title: 'Point relais (stop desk)',
              subtitle: 'Remise en agence du transporteur',
              icon: Icons.store_mall_directory_outlined,
              value: _d.stopDesk,
              onChanged: (v) => setState(() {
                _d.stopDesk = v;
                _err.remove('delivery');
              }),
            ),
            if (_err['delivery'] != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_err['delivery']!, style: _errorStyle),
                ),
              ),
          ],
        ),
      ),
      if (delivers) ...[
        const SizedBox(height: 22),
        const _SectionTitle('EXPÉDITION'),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: _key('weight'),
          child: _TField(
            label: 'Poids emballé (kg) *',
            controller: _t['weight']!,
            hint: 'Ex. 1,5',
            errorText: _err['weight'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => _clearErr('weight'),
          ),
        ),
        const SizedBox(height: 8),
        const _Tip(
          'Au-delà de 5 kg, certains transporteurs appliquent un supplément. '
          'Pesez l’article avec son emballage.',
        ),
        const SizedBox(height: 10),
        _SwitchTile(
          title: 'Livraison offerte',
          subtitle: 'Les frais sont inclus dans votre prix',
          icon: Icons.redeem_outlined,
          value: _d.freeShipping,
          onChanged: (v) => setState(() {
            _d.freeShipping = v;
            _err.remove('fee');
          }),
        ),
        if (!_d.freeShipping) ...[
          const SizedBox(height: 10),
          KeyedSubtree(
            key: _key('fee'),
            child: _TField(
              label: 'Frais de livraison (${_d.currency}) *',
              controller: _t['fee']!,
              hint: 'Ex. 600',
              errorText: _err['fee'],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) => _clearErr('fee'),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _SwitchTile(
          title: 'Envoi vers les autres pays du Maghreb',
          subtitle: 'Sinon, livraison dans votre pays uniquement',
          icon: Icons.public_rounded,
          value: _d.abroad,
          onChanged: (v) => setState(() => _d.abroad = v),
        ),
        const SizedBox(height: 10),
        _SwitchTile(
          title: 'Article fragile',
          subtitle: 'Emballage renforcé (céramique, verre, zellige…)',
          icon: Icons.warning_amber_rounded,
          value: _d.fragile,
          onChanged: (v) => setState(() => _d.fragile = v),
        ),
        if (inStock) ...[
          const SizedBox(height: 14),
          const _SectionTitle('DÉLAI DE PRÉPARATION'),
          const SizedBox(height: 10),
          _Pills(
            options: [for (final d in _kPrepDays) d == 1 ? '1 jour' : '$d jours'],
            isSelected: (label) =>
                label == (_d.prepDays == 1 ? '1 jour' : '${_d.prepDays} jours'),
            onTap: (label) => setState(
              () => _d.prepDays = int.parse(label.split(' ').first),
            ),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: _Tip(
              'Le délai de fabrication de l’étape 3 s’ajoute au délai de livraison.',
            ),
          ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: _key('phone'),
          child: _TField(
            label: 'N° Tél. pour le transporteur (facultatif)',
            controller: _t['phone']!,
            hint: '00 000 000',
            prefix: '${_country.flag} ${_country.dial}',
            errorText: _err['phone'],
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              LengthLimitingTextInputFormatter(14),
            ],
            onChanged: (_) => _clearErr('phone'),
          ),
        ),
      ],
      const SizedBox(height: 22),
      const _SectionTitle('PAIEMENT & RETOURS'),
      const SizedBox(height: 10),
      _SwitchTile(
        title: 'Paiement à la livraison',
        subtitle: 'L’acheteur règle en main propre à la réception',
        icon: Icons.payments_outlined,
        value: _d.cod,
        onChanged: (v) => setState(() => _d.cod = v),
      ),
      const SizedBox(height: 12),
      _Pills(
        options: const ['Pas de retour', 'Retour sous 7 jours', 'Retour sous 14 jours'],
        isSelected: (label) =>
            label ==
            switch (_d.returns) {
              ReturnPolicy.none => 'Pas de retour',
              ReturnPolicy.days7 => 'Retour sous 7 jours',
              ReturnPolicy.days14 => 'Retour sous 14 jours',
            },
        onTap: (label) => setState(() {
          _d.returns = switch (label) {
            'Retour sous 7 jours' => ReturnPolicy.days7,
            'Retour sous 14 jours' => ReturnPolicy.days14,
            _ => ReturnPolicy.none,
          };
        }),
      ),
      const SizedBox(height: 8),
      const _Tip(
        'Pour les pièces sur mesure ou personnalisées, le retour est en général '
        'exclu : indiquez-le clairement.',
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // Étape 5 : aperçu & publication
  // ---------------------------------------------------------------------

  List<Widget> _stepPreview() {
    final price = int.tryParse(_text('price'));
    final hasExtra =
        _d.hasVariants && _d.variants.any((v) => v.priceExtra > 0);
    final priceLabel = price == null
        ? '—'
        : '${hasExtra ? 'à partir de ' : ''}$price ${_d.currency}';

    final stock = switch (_d.availability) {
      ArticleAvailability.unique => 'Pièce unique',
      ArticleAvailability.madeToOrder => 'Sur commande · ${_d.leadTimeDays} j',
      ArticleAvailability.inStock =>
        '${_d.hasVariants ? _d.variants.fold<int>(0, (s, v) => s + v.quantity) : _d.qty} disponibles',
    };

    final delivery = <String>[
      if (_d.pickup) 'Retrait atelier',
      if (_d.home) 'Domicile',
      if (_d.stopDesk) 'Point relais',
    ];
    final deliveryLine = delivery.isEmpty
        ? 'Aucun mode de remise'
        : '${delivery.join(' · ')}${(_d.home || _d.stopDesk) ? (_d.freeShipping ? ' · livraison offerte' : ' · ${_text('fee')} ${_d.currency}') : ''}';

    const titles = [
      'Photos et nom',
      'Détails et description',
      'Stock et modèles',
      'Prix et livraison',
    ];
    final checks = [
      for (var s = 0; s < 4; s++) (s, titles[s], _validate(s)),
    ];
    final allOk = checks.every((c) => c.$3.isEmpty);

    return [
      const _SectionTitle('APERÇU POUR L’ACHETEUR'),
      const SizedBox(height: 10),
      _PreviewCard(
        coverPath: _d.photos.isEmpty ? null : _d.photos.first,
        title: _text('name').isEmpty ? 'Nom de l’article' : _text('name'),
        priceLabel: priceLabel,
        technique: _d.technique,
        chips: [
          if (_d.category != null) _d.category!,
          stock,
          if (_d.customizable) 'Personnalisable',
        ],
        lines: [
          (Icons.place_outlined, _text('origin').isEmpty
              ? 'Atelier artisan'
              : 'Fabriqué à ${_text('origin')}'),
          (Icons.local_shipping_outlined, deliveryLine),
          if (_d.cod) (Icons.payments_outlined, 'Paiement à la livraison'),
          (
            Icons.assignment_return_outlined,
            switch (_d.returns) {
              ReturnPolicy.none => 'Pas de retour',
              ReturnPolicy.days7 => 'Retour sous 7 jours',
              ReturnPolicy.days14 => 'Retour sous 14 jours',
            },
          ),
        ],
      ),
      const SizedBox(height: 22),
      const _SectionTitle('AVANT DE PUBLIER'),
      const SizedBox(height: 10),
      for (final c in checks)
        _CheckRow(
          label: c.$2,
          problem: c.$3.isEmpty ? null : c.$3.values.first,
          onTap: () => _goTo(c.$1),
        ),
      const SizedBox(height: 8),
      _Tip(
        allOk
            ? 'Tout est prêt. Vous pourrez modifier l’article à tout moment '
                  'depuis votre profil.'
            : 'Touchez une ligne pour compléter l’étape concernée, ou enregistrez '
                  'un brouillon pour continuer plus tard.',
      ),
    ];
  }
}

// ===========================================================================
// WIDGETS
// ===========================================================================

const _errorStyle = TextStyle(
  color: _kError,
  fontSize: 9.5,
  height: 1.3,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w500,
);

// --- En-tête de l'assistant -------------------------------------------------

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({
    required this.step,
    required this.maxStep,
    required this.onBack,
    required this.onStepTap,
  });

  final int step;
  final int maxStep;
  final VoidCallback onBack;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AtlartPalette.skyHeader, Color(0xFFE6F2FC)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            children: [
              SizedBox(
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AtlartBack(onPressed: onBack),
                    ),
                    Image.asset(
                      AtlartAssets.logoHorizontal,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                        'ATLART',
                        style: TextStyle(
                          color: AtlartPalette.blueText,
                          fontSize: 14,
                          letterSpacing: 0.8,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${step + 1} / ${_kStepLabels.length}',
                          style: const TextStyle(
                            color: AtlartPalette.navy,
                            fontSize: 10.5,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _kStepTitles[step],
                  style: AtlartType.title.copyWith(fontSize: 18, height: 1.3),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < _kStepLabels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: i <= maxStep && i != step
                            ? () => onStepTap(i)
                            : null,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: i == _kStepLabels.length - 1 ? 0 : 5,
                          ),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i <= step
                                      ? AtlartPalette.blueText
                                      : Colors.white.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _kStepLabels[i],
                                style: TextStyle(
                                  color: i == step
                                      ? AtlartPalette.navy
                                      : AtlartPalette.blueTextLight,
                                  fontSize: 8.5,
                                  fontFamily: 'Poppins',
                                  fontWeight: i == step
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Barre d'actions --------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.primaryLabel,
    required this.onPrimary,
    required this.loading,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool loading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDF2F7))),
      ),
      child: Row(
        children: [
          if (secondaryLabel != null) ...[
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: loading ? null : onSecondary,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AtlartPalette.navyDark,
                    side: const BorderSide(color: _kLine),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    secondaryLabel!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 3,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AtlartPalette.coral,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [AtlartShadows.button],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: loading ? null : onPrimary,
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            primaryLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Petits éléments --------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF6C9AE0),
      fontSize: 9.5,
      letterSpacing: 0.8,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _kTipFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 15,
            color: Color(0xFFE9A15B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AtlartPalette.blueTextSoft,
                fontSize: 9.5,
                height: 1.5,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Puces à choix simple ou multiple (la logique est dans [isSelected]/[onTap]).
class _Pills extends StatelessWidget {
  const _Pills({
    required this.options,
    required this.isSelected,
    required this.onTap,
    this.errorText,
    this.emptyHint,
  });

  final List<String> options;
  final bool Function(String) isSelected;
  final ValueChanged<String> onTap;
  final String? errorText;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (options.isEmpty && emptyHint != null)
          Text(emptyHint!, style: _bodyStyle.copyWith(color: _kLabel))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                GestureDetector(
                  onTap: () => onTap(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected(option)
                          ? AtlartPalette.blueText
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected(option)
                            ? AtlartPalette.blueText
                            : _kLine,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected(option)
                            ? Colors.white
                            : AtlartPalette.blueText,
                        fontSize: 10.5,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(errorText!, style: _errorStyle),
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF2F1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AtlartPalette.coral : Colors.transparent,
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x145975A2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AtlartPalette.coral : AtlartPalette.blueText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AtlartPalette.navyDark,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AtlartPalette.blueTextLight,
                      fontSize: 9.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AtlartPalette.coral : _kLine,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 9, 8, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x145975A2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AtlartPalette.blueText),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AtlartPalette.navyDark,
                    fontSize: 11.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AtlartPalette.blueTextLight,
                    fontSize: 9,
                    height: 1.4,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AtlartPalette.coral,
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFFC9D5E3) : AtlartPalette.navyDark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundBtn(
          icon: Icons.remove_rounded,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 40,
          child: Center(
            child: Text(
              '$value',
              style: const TextStyle(
                color: AtlartPalette.navy,
                fontSize: 13,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        _RoundBtn(
          icon: Icons.add_rounded,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x145975A2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AtlartPalette.navyDark,
                    fontSize: 11.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AtlartPalette.blueTextLight,
                    fontSize: 9,
                    height: 1.4,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QtyStepper(value: value, onChanged: onChanged, min: min, max: max),
        ],
      ),
    );
  }
}

// --- Champs -----------------------------------------------------------------

/// Cadre commun : bleu clair quand vide, blanc quand rempli ou actif (Figma).
class _Shell extends StatelessWidget {
  const _Shell({
    required this.label,
    required this.child,
    this.errorText,
    this.filled = false,
    this.focused = false,
    this.onTap,
  });

  final String label;
  final Widget child;
  final String? errorText;
  final bool filled;
  final bool focused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final Color fill = hasError
        ? _kErrorFill
        : (filled ? Colors.white : _kFieldFill);
    final Color border = hasError
        ? _kErrorBorder
        : (focused
              ? AtlartPalette.blueText.withValues(alpha: 0.55)
              : Colors.transparent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.2),
              boxShadow: filled && !hasError
                  ? const [
                      BoxShadow(
                        color: Color(0x1A5975A2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: _labelStyle),
                const SizedBox(height: 3),
                child,
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
            child: Text(errorText!, style: _errorStyle),
          ),
      ],
    );
  }
}

class _TField extends StatefulWidget {
  const _TField({
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.capitalization = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final int? minLines;
  final int maxLines;
  final String? prefix;
  final Widget? suffix;
  final TextCapitalization capitalization;

  @override
  State<_TField> createState() => _TFieldState();
}

class _TFieldState extends State<_TField> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return ListenableBuilder(
      listenable: Listenable.merge([w.controller, _focus]),
      builder: (context, _) {
        return _Shell(
          label: w.label,
          errorText: w.errorText,
          filled: w.controller.text.isNotEmpty || _focus.hasFocus,
          focused: _focus.hasFocus,
          onTap: _focus.requestFocus,
          child: Row(
            children: [
              if (w.prefix != null) ...[
                Text(w.prefix!, style: _valueStyle.copyWith(fontSize: 11.5)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: TextField(
                  controller: w.controller,
                  focusNode: _focus,
                  keyboardType: w.keyboardType,
                  inputFormatters: w.inputFormatters,
                  textCapitalization: w.capitalization,
                  textInputAction: w.maxLines > 1
                      ? TextInputAction.newline
                      : TextInputAction.done,
                  minLines: w.minLines,
                  maxLines: w.maxLines,
                  maxLength: w.maxLength,
                  onChanged: w.onChanged,
                  onSubmitted: w.onSubmitted,
                  cursorColor: AtlartPalette.blueText,
                  style: _valueStyle,
                  buildCounter: w.maxLength == null
                      ? null
                      : (
                          BuildContext context, {
                          required int currentLength,
                          required bool isFocused,
                          required int? maxLength,
                        }) => Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$currentLength/$maxLength',
                            style: _labelStyle,
                          ),
                        ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: w.hint,
                    hintStyle: _hintStyle,
                  ),
                ),
              ),
              if (w.suffix != null) w.suffix!,
            ],
          ),
        );
      },
    );
  }
}

// --- Modèles (variantes) ----------------------------------------------------

class _VariantRow extends StatefulWidget {
  const _VariantRow({
    super.key,
    required this.variant,
    required this.index,
    required this.showQty,
    required this.currency,
    required this.onChanged,
    required this.onRemove,
  });

  final ArticleVariant variant;
  final int index;
  final bool showQty;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_VariantRow> createState() => _VariantRowState();
}

class _VariantRowState extends State<_VariantRow> {
  late final TextEditingController _name = TextEditingController(
    text: widget.variant.name,
  );
  late final TextEditingController _extra = TextEditingController(
    text: widget.variant.priceExtra == 0 ? '' : '${widget.variant.priceExtra}',
  );

  @override
  void dispose() {
    _name.dispose();
    _extra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.variant;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x145975A2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TField(
                  label: 'Modèle ${widget.index + 1} *',
                  controller: _name,
                  hint: 'Ex. Grand – bleu',
                  maxLength: 30,
                  onChanged: (value) {
                    v.name = value;
                    widget.onChanged();
                  },
                ),
              ),
              IconButton(
                tooltip: 'Supprimer ce modèle',
                onPressed: widget.onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AtlartPalette.blueTextLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.showQty) ...[
                  _QtyStepper(
                    value: v.quantity,
                    onChanged: (q) {
                      v.quantity = q;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _TField(
                    label: 'Supplément (${widget.currency})',
                    controller: _extra,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (value) {
                      v.priceExtra = int.tryParse(value) ?? 0;
                      widget.onChanged();
                    },
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

// --- Calculateur de prix ----------------------------------------------------

class _PriceHelper extends StatefulWidget {
  const _PriceHelper({required this.currency, required this.onApply});

  final String currency;
  final ValueChanged<int> onApply;

  @override
  State<_PriceHelper> createState() => _PriceHelperState();
}

class _PriceHelperState extends State<_PriceHelper> {
  final _cost = TextEditingController();
  final _hours = TextEditingController();
  final _rate = TextEditingController();
  int _margin = 30;
  bool _open = false;

  @override
  void dispose() {
    _cost.dispose();
    _hours.dispose();
    _rate.dispose();
    super.dispose();
  }

  int? get _suggested {
    final cost = int.tryParse(_cost.text) ?? 0;
    final hours = double.tryParse(_hours.text.replaceAll(',', '.')) ?? 0;
    final rate = int.tryParse(_rate.text) ?? 0;
    final base = cost + hours * rate;
    if (base <= 0) return null;
    return (base * (1 + _margin / 100)).round();
  }

  @override
  Widget build(BuildContext context) {
    final suggested = _suggested;
    final digits = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                const Icon(
                  Icons.calculate_outlined,
                  size: 19,
                  color: AtlartPalette.blueText,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Calculer mon prix',
                    style: TextStyle(
                      color: AtlartPalette.navyDark,
                      fontSize: 11.5,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AtlartPalette.blueText,
                ),
              ],
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TField(
                    label: 'Matériaux (${widget.currency})',
                    controller: _cost,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TField(
                    label: 'Heures de travail',
                    controller: _hours,
                    hint: '0',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TField(
              label: 'Votre tarif horaire (${widget.currency}/h)',
              controller: _rate,
              hint: '0',
              keyboardType: TextInputType.number,
              inputFormatters: digits,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Marge', style: _bodyStyle),
                const SizedBox(width: 10),
                _Pills(
                  options: [for (final m in _kMargins) '$m %'],
                  isSelected: (label) => label == '$_margin %',
                  onTap: (label) => setState(
                    () => _margin = int.parse(label.replaceAll(' %', '')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggested == null
                        ? 'Renseignez au moins un coût.'
                        : 'Prix conseillé : $suggested ${widget.currency}',
                    style: _bodyStyle.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (suggested != null)
                  TextButton(
                    onPressed: () {
                      widget.onApply(suggested);
                      setState(() => _open = false);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AtlartPalette.coral,
                    ),
                    child: const Text('Utiliser'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// --- Photos -----------------------------------------------------------------

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photos,
    required this.max,
    required this.onAdd,
    required this.onRemove,
    required this.onMakeCover,
    this.errorText,
  });

  final List<String> photos;
  final int max;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;
  final String? errorText;

  Widget _thumb(int i) {
    if (i < photos.length) {
      return GestureDetector(
        onTap: () => onMakeCover(i),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photos[i]),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: _kFieldFill),
              ),
            ),
            Positioned(
              top: 3,
              right: 3,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: AtlartPalette.navyDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (i == photos.length && photos.isNotEmpty) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kLine),
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            color: AtlartPalette.blueText,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: _kFieldFill.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = photos.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasCover ? null : onAdd,
          borderRadius: BorderRadius.circular(14),
          child: CustomPaint(
            foregroundPainter: _DashedBorderPainter(
              color: errorText != null ? _kErrorBorder : const Color(0xFF2E4A73),
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: !hasCover
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.file_upload_outlined,
                            size: 24,
                            color: AtlartPalette.navy,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Ajouter des photos',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AtlartPalette.navy,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'JPEG, PNG — jusqu’à 5 photos, 8 Mo chacune',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              color: AtlartPalette.blueTextLight,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(photos.first),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AtlartPalette.blueTextLight,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AtlartPalette.coral,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Photo principale',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: IconButton.filledTonal(
                              onPressed: () => onRemove(0),
                              tooltip: 'Retirer la photo',
                              icon: const Icon(Icons.close, size: 16),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.92,
                                ),
                                foregroundColor: AtlartPalette.navyDark,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i < max; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 1 ? 0 : 8),
                  child: AspectRatio(aspectRatio: 1, child: _thumb(i)),
                ),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(errorText!, style: _errorStyle),
          ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 3), paint);
        distance += 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

// --- Aperçu & liste de contrôle ---------------------------------------------

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.coverPath,
    required this.title,
    required this.priceLabel,
    required this.technique,
    required this.chips,
    required this.lines,
  });

  final String? coverPath;
  final String title;
  final String priceLabel;
  final String technique;
  final List<String> chips;
  final List<(IconData, String)> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F3554),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                coverPath == null
                    ? const ColoredBox(
                        color: _kFieldFill,
                        child: Icon(
                          Icons.image_outlined,
                          size: 34,
                          color: AtlartPalette.blueTextLight,
                        ),
                      )
                    : Image.file(
                        File(coverPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: _kFieldFill),
                      ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.handyman_outlined,
                          size: 12,
                          color: AtlartPalette.blueText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          technique,
                          style: const TextStyle(
                            color: AtlartPalette.blueText,
                            fontSize: 9,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AtlartPalette.navy,
                    fontSize: 13.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  priceLabel,
                  style: const TextStyle(
                    color: AtlartPalette.coral,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < chips.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: i == 0
                              ? const Color(0xFFFFE9D2)
                              : const Color(0xFFD9E8F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          chips[i],
                          style: TextStyle(
                            color: i == 0
                                ? const Color(0xFFC77A2B)
                                : AtlartPalette.blueText,
                            fontSize: 9,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(line.$1, size: 15, color: AtlartPalette.blueText),
                        const SizedBox(width: 8),
                        Expanded(child: Text(line.$2, style: _bodyStyle)),
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
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.problem,
    required this.onTap,
  });

  final String label;
  final String? problem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ok = problem == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ok ? Colors.transparent : _kErrorBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x145975A2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              size: 20,
              color: ok ? _kOk : _kError,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AtlartPalette.navyDark,
                      fontSize: 11.5,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!ok)
                    Text(
                      problem!,
                      style: const TextStyle(
                        color: _kError,
                        fontSize: 9.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AtlartPalette.blueTextLight,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Résultat (succès / erreur) : panneau gris translucide du Figma ---------

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.message,
    required this.icon,
    required this.actionLabel,
    required this.onClose,
    required this.onBack,
    required this.onAction,
  });

  final String message;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: const Color(0xFFDADCE2).withValues(alpha: 0.92),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _kOverlayText,
                            fontSize: 16,
                            height: 1.55,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Tooltip(
                        message: actionLabel,
                        child: Material(
                          color: AtlartPalette.coral,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: onAction,
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(icon, color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: IconButton(
                  tooltip: 'Retour',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: _kOverlayText),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(
                    side: BorderSide(color: _kOverlayText, width: 1.4),
                  ),
                  child: InkWell(
                    onTap: onClose,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: _kOverlayText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
