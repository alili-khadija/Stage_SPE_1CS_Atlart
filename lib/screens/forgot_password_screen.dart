import 'package:flutter/material.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_ui_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    setState(() => _errorMessage = null);

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir votre e-mail');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Veuillez saisir un e-mail valide');
      return;
    }

    setState(() => _loading = true);

    // TODO: brancher l'appel réel d'envoi du lien de réinitialisation.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AtlartPage(
      showBack: true,
      child: _sent ? _sentView() : _formView(),
    );
  }

  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        const Center(child: Text('Mot de passe oublié', style: AtlartType.title)),
        const SizedBox(height: 8),
        const Center(
          child: SizedBox(
            width: 280,
            child: Text(
              'Entrez l\u2019adresse e-mail associée à votre compte, nous vous '
              'enverrons un lien pour le réinitialiser.',
              textAlign: TextAlign.center,
              style: AtlartType.subtitle,
            ),
          ),
        ),
        const SizedBox(height: 47),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 45),
          child: AtlartField(
            label: 'E-mail',
            controller: _emailController,
            hint: 'exemple@mail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            errorText: _errorMessage,
            onChanged: (_) {
              if (_errorMessage != null) setState(() => _errorMessage = null);
            },
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 45),
          child: AtlartButton(
            label: 'Envoyer le lien',
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
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(height: 27),
      ],
    );
  }

  Widget _sentView() {
    final email = _emailController.text.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [AtlartShadows.field],
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: AtlartPalette.success,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(child: Text('E-mail envoyé', style: AtlartType.title)),
          const SizedBox(height: 8),
          Text(
            email.isEmpty
                ? 'Vérifiez votre boîte de réception pour réinitialiser votre mot de passe.'
                : 'Un lien de réinitialisation a été envoyé à $email.',
            textAlign: TextAlign.center,
            style: AtlartType.subtitle,
          ),
          const Spacer(flex: 3),
          AtlartButton(
            label: 'Retour à la connexion',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 65),
        ],
      ),
    );
  }
}