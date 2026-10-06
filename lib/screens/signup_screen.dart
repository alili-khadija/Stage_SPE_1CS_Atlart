import 'package:flutter/material.dart';

import '../app_session.dart';
import '../services/auth_api.dart';
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

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();

  String _country = 'DZ';
  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _nameError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
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

    setState(() => _loading = true);

    try {
      await AtlartSession.instance.register(
        nomEmprunt: _nameController.text.trim(),
        email: email,
        motDePasse: _passwordController.text,
        paysCode: _country,
        localisation: _locationController.text.trim(),
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
                  onChanged: (value) {
                    setState(() => _country = value ?? _country);
                  },
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
                  label: 'Localisation',
                  controller: _locationController,
                  hint: 'Ville ou adresse (facultatif)',
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