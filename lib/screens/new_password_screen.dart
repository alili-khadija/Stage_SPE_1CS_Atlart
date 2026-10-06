import 'package:flutter/material.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_ui_widgets.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearErrors(String _) {
    if (_passwordError != null || _confirmError != null) {
      setState(() {
        _passwordError = null;
        _confirmError = null;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _passwordError = null;
      _confirmError = null;
    });

    if (_passwordController.text.length < 8) {
      setState(() => _passwordError =
          'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _confirmError = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _loading = true);
    // TODO: brancher l'appel réel de réinitialisation du mot de passe.
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Sur le Figma : bandeau logo en haut, pas de bouton retour.
    return AtlartPage(
      gradient: AtlartPalette.welcomeGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AtlartHeaderLogo(),
          SizedBox(height: AtlartHeaderLogo.gapBefore(context, 264)),
          const Center(
            child: Text('Nouveau mot de passe', style: AtlartType.title),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Choisissez un mot de passe d\u2019au moins 8 caractères.',
                  style: AtlartType.subtitleStrong,
                ),
              ),
            ),
          ),
          const SizedBox(height: 70),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45),
            child: Column(
              children: [
                SizedBox(
                  height: 90,
                  child: AtlartField(
                    label: 'Nouveau mot de passe',
                    controller: _passwordController,
                    hint: 'Saisissez-le',
                    obscureText: _obscure1,
                    textInputAction: TextInputAction.next,
                    onChanged: _clearErrors,
                    onToggleObscure: () =>
                        setState(() => _obscure1 = !_obscure1),
                    errorText: _passwordError,
                  ),
                ),
                AtlartField(
                  label: 'Confirmer le mot de passe',
                  controller: _confirmController,
                  hint: 'Saisissez-le à nouveau',
                  obscureText: _obscure2,
                  textInputAction: TextInputAction.done,
                  onChanged: _clearErrors,
                  onToggleObscure: () => setState(() => _obscure2 = !_obscure2),
                  errorText: _confirmError,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45),
            child: AtlartButton(
              label: 'Réinitialiser',
              height: 49,
              loading: _loading,
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: AtlartFooter(
              leading: 'Vous vous souvenez de votre mot de passe ?',
              action: 'Se connecter',
              stacked: true,
              fontSize: 10.5,
              onTap: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
          const SizedBox(height: 27),
        ],
      ),
    );
  }
}