import 'dart:async';

import 'package:flutter/material.dart';

import '../app_session.dart';
import '../services/auth_api.dart';
import '../services/localite_api.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_ui_widgets.dart';
import 'role_selection_screen.dart';
import 'welcome_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.role});

  final AtlartRole role;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _countries = {
    'DZ': ('🇩🇿', 'Algérie'),
    'MA': ('🇲🇦', 'Maroc'),
    'TN': ('🇹🇳', 'Tunisie'),
    'LY': ('🇱🇾', 'Libye'),
    'MR': ('🇲🇷', 'Mauritanie'),
  };

  // Pays pour lesquels la liste des communes est disponible.
  static const _paysAvecCommunes = {'DZ', 'MA', 'TN'};

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  String _country = 'DZ';
  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _nameError;
  String? _passwordError;

  // Recherche de commune
  Timer? _debounce;
  int _searchSeq = 0;
  Localite? _selected;
  List<Localite> _suggestions = const [];
  bool _searching = false;
  bool _noResult = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _onChanged(String _) {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  void _onCityChanged(String text) {
    _debounce?.cancel();
    // Toute modification du texte annule la commune choisie.
    _selected = null;
    final q = text.trim();

    if (!_paysAvecCommunes.contains(_country) || q.length < 2) {
      setState(() {
        _suggestions = const [];
        _searching = false;
        _noResult = false;
      });
      return;
    }

    setState(() {
      _searching = true;
      _noResult = false;
    });

    final seq = ++_searchSeq;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await LocaliteApi.rechercher(_country, q);
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _suggestions = results;
        _searching = false;
        _noResult = results.isEmpty;
      });
    });
  }

  void _selectLocalite(Localite l) {
    _debounce?.cancel();
    _searchSeq++;
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = l;
      _cityController.text = l.nom;
      _suggestions = const [];
      _searching = false;
      _noResult = false;
    });
  }

  void _onCountryChanged(String? value) {
    if (value == null || value == _country) return;
    _debounce?.cancel();
    _searchSeq++;
    setState(() {
      _country = value;
      _selected = null;
      _cityController.clear();
      _suggestions = const [];
      _searching = false;
      _noResult = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });

    if (!_canSubmit) return;

    if (!RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email)) {
      setState(() => _emailError = 'Veuillez saisir un e-mail valide.');
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(
        () => _passwordError =
            'Le mot de passe doit contenir au moins 8 caractères.',
      );
      return;
    }

    // Commune choisie dans la liste -> envoyée par son identifiant.
    // Sinon (pays sans liste, ou commune absente de la liste) le texte
    // saisi est conservé tel quel dans l'adresse.
    final adresse = _addressController.text.trim();
    final villeLibre = _selected == null ? _cityController.text.trim() : '';
    final localisation = [
      if (villeLibre.isNotEmpty) villeLibre,
      if (adresse.isNotEmpty) adresse,
    ].join(', ');

    setState(() => _loading = true);

    try {
      await AtlartSession.instance.register(
        nomEmprunt: _nameController.text.trim(),
        email: email,
        motDePasse: _passwordController.text,
        paysCode: _country,
        localisation: localisation,
        localiteId: _selected?.id,
        roleSouhaite: widget.role.name,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _nameError = error.fieldErrors['nom_emprunt'];
        _emailError = error.fieldErrors['email'];
        _passwordError = error.fieldErrors['mot_de_passe'];
      });
      if (_nameError == null && _emailError == null && _passwordError == null) {
        _showMessage(error.message);
      }
      return;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'registration',
        ),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Une erreur est survenue. Réessayez.');
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WelcomeScreen(
          role: widget.role,
          firstName: AtlartSession.firstName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasList = _paysAvecCommunes.contains(_country);

    return AtlartPage(
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 80),
          const Center(
            child: Text('Créer un compte', style: AtlartType.title),
          ),
          const SizedBox(height: 6),
          const Center(
            child: SizedBox(
              width: 220,
              child: Text(
                'Quelques informations pour commencer.',
                textAlign: TextAlign.center,
                style: AtlartType.subtitle,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                AtlartField(
                  label: 'Nom d’emprunt',
                  controller: _nameController,
                  hint: 'Votre nom',
                  errorText: _nameError,
                  textInputAction: TextInputAction.next,
                  onChanged: _onChanged,
                ),
                const SizedBox(height: 14),
                AtlartField(
                  label: 'E-mail',
                  controller: _emailController,
                  hint: 'exemple@mail.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: _onChanged,
                  errorText: _emailError,
                ),
                const SizedBox(height: 14),
                AtlartField(
                  label: 'Mot de passe',
                  controller: _passwordController,
                  hint: '8 caractères minimum',
                  obscureText: _obscure,
                  errorText: _passwordError,
                  textInputAction: TextInputAction.next,
                  onChanged: _onChanged,
                  onToggleObscure: () {
                    setState(() => _obscure = !_obscure);
                  },
                ),
                const SizedBox(height: 14),
                AtlartDropdown<String>(
                  label: 'Pays',
                  value: _country,
                  onChanged: _onCountryChanged,
                  items: [
                    for (final entry in _countries.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text('${entry.value.$1}  ${entry.value.$2}'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                AtlartField(
                  label: 'Commune',
                  controller: _cityController,
                  hint: hasList
                      ? 'Tapez puis choisissez dans la liste'
                      : 'Votre ville (facultatif)',
                  textInputAction: TextInputAction.next,
                  onChanged: _onCityChanged,
                ),
                if (_suggestions.isNotEmpty)
                  _LocaliteSuggestions(
                    items: _suggestions,
                    onSelected: _selectLocalite,
                  )
                else if (_searching)
                  const _CityHint(text: 'Recherche…')
                else if (_noResult && _selected == null)
                  const _CityHint(
                    text: 'Commune introuvable : votre saisie sera '
                        'enregistrée telle quelle.',
                  )
                else if (_selected != null)
                  _CityHint(
                    text: _selected!.region == null ||
                            _selected!.region == _selected!.nom
                        ? '✓ ${_selected!.nom}'
                        : '✓ ${_selected!.nom}, ${_selected!.region}',
                  ),
                const SizedBox(height: 14),
                AtlartField(
                  label: 'Adresse',
                  controller: _addressController,
                  hint: 'Rue, quartier… (facultatif)',
                  textInputAction: TextInputAction.done,
                  onChanged: _onChanged,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: AtlartButton(
              label: 'Continuer',
              loading: _loading,
              onPressed: _canSubmit && !_loading ? _submit : null,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CityHint extends StatelessWidget {
  const _CityHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: AtlartPalette.blueTextLight,
            fontSize: 10,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

class _LocaliteSuggestions extends StatelessWidget {
  const _LocaliteSuggestions({required this.items, required this.onSelected});

  final List<Localite> items;
  final ValueChanged<Localite> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [AtlartShadows.field],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEDF2F9)),
            InkWell(
              onTap: () => onSelected(items[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].nom,
                            style: const TextStyle(
                              color: AtlartPalette.navy,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          if (items[i].region != null &&
                              items[i].region != items[i].nom)
                            Text(
                              items[i].region!,
                              style: const TextStyle(
                                color: AtlartPalette.blueTextLight,
                                fontSize: 10,
                                fontFamily: 'Poppins',
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (items[i].nomAr != null)
                      Text(
                        items[i].nomAr!,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: AtlartPalette.navy,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}