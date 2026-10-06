import 'package:flutter/material.dart';

import '../app_session.dart';
import '../services/auth_api.dart';
import 'forgot_password_screen.dart';
import 'role_selection_screen.dart';
import 'search_screen.dart';

const _kLogoAsset = 'assets/images/logo_atlart.png';
const _kMountainAsset = 'assets/images/background_atlas.png';

const double _kMountainOpacity = 0.6;
const double _kMountainFadeEnd = 0.45;

const _kSky = Color(0xFFC2DFF7);
const _kFieldFill = Color(0xFFD5ECFF);
const _kErrorFill = Color(0xFFFDECEB);
const _kErrorBorder = Color(0xFFF28B8B);
const _kError = Color(0xFFE86B69);
const _kNavy = Color(0xFF16324A);
const _kBlue = Color(0xFF5975A2);
const _kHint = Color(0xFF9A998F);
const _kCoral = Color(0xFFFF7A7A);
const _kCoralSoft = Color(0xFFFFA2A2);
const _kOnCoral = Color(0xFFF2EDDD);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_loading &&
      !_hasError &&
      _usernameController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _onChanged(String _) => setState(() {
        _hasError = false;
        _errorMessage = null;
      });

  Future<void> _submit() async {
    if (!_canSubmit) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await AtlartSession.instance.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = error.kind == AuthErrorKind.invalidCredentials;
        _errorMessage = error.message;
      });
      return;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'login',
        ),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Une erreur est survenue. Réessayez.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
      (_) => false,
    );
  }

  void _openForgot() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
      );

  void _openSignup() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSky,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kSky, _kSky, Colors.white],
                  stops: [0.0, 0.12, 0.62],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(child: _Mountains()),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, c) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: c.maxHeight),
                          child: IntrinsicHeight(child: _content()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return Stack(
      children: [
        const Positioned(
          top: 20,
          left: 0,
          right: 0,
          height: 300,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.03),
                  radius: 0.62,
                  colors: [Color(0xF2FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 98),
            SizedBox(
              height: 136,
              child: Center(
                child: Image.asset(
                  _kLogoAsset,
                  width: 155,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.air,
                    size: 80,
                    color: _kBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 56),
            const Center(
              child: Text(
                'ATLART',
                style: TextStyle(
                  color: _kBlue,
                  fontSize: 36,
                  height: 1.2,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'The strong wind of the Atlas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kBlue,
                  fontSize: 19,
                  height: 1.4,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 151),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: Column(
                children: [
                  _LoginField(
                    placeholder: 'USERNAME',
                    controller: _usernameController,
                    hasError: _hasError,
                    onChanged: _onChanged,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 22),
                  _LoginField(
                    placeholder: 'PASSWORD',
                    controller: _passwordController,
                    hasError: _hasError,
                    obscure: _obscure,
                    onToggle: () => setState(() => _obscure = !_obscure),
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 30,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child:
                            _errorMessage == null
                                ? _signupOrForgotLine()
                                : _errorLine(_errorMessage!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: _LoginButton(
                loading: _loading,
                onPressed: _canSubmit ? _submit : null,
              ),
            ),
            const SizedBox(height: 67),
          ],
        ),
      ],
    );
  }

  Widget _errorLine(String message) {
    const style = TextStyle(
      color: _kError,
      fontSize: 10,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(message, style: style),
        GestureDetector(
          onTap: _openForgot,
          child: Text(
            'Mot de passe oublié?',
            style: style.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: _kError,
            ),
          ),
        ),
      ],
    );
  }

  Widget _signupOrForgotLine() {
    const base = TextStyle(
      color: _kNavy,
      fontSize: 10,
      height: 1.4,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openSignup,
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                    text: 'Vous n\u2019avez pas de compte? ', style: base),
                TextSpan(
                  text: 'Inscrivez-vous',
                  style: base.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: _kNavy,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: _openForgot,
          child: Text(
            'Mot de passe oublié?',
            style: base.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: _kNavy,
            ),
          ),
        ),
      ],
    );
  }
}

class _Mountains extends StatelessWidget {
  const _Mountains();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
        stops: [0.0, _kMountainFadeEnd],
      ).createShader(rect),
      child: Opacity(
        opacity: _kMountainOpacity,
        child: Image.asset(
          _kMountainAsset,
          fit: BoxFit.fitWidth,
          alignment: Alignment.bottomCenter,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _LoginField extends StatefulWidget {
  const _LoginField({
    required this.placeholder,
    required this.controller,
    required this.hasError,
    required this.onChanged,
    this.obscure = false,
    this.onToggle,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final String placeholder;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final bool obscure;
  final VoidCallback? onToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  final _focus = FocusNode();

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _focus.hasFocus || widget.controller.text.isNotEmpty;
    final error = widget.hasError;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: error ? _kErrorFill : _kFieldFill,
        borderRadius: BorderRadius.circular(14),
        border: error ? Border.all(color: _kErrorBorder) : null,
        boxShadow: (active && !error)
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              cursorColor: _kBlue,
              style: const TextStyle(
                color: _kNavy,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  color: _kHint,
                  fontSize: 9.5,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.onToggle != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  widget.obscure ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: _kBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kCoral,
            disabledBackgroundColor: loading ? _kCoral : _kCoralSoft,
            foregroundColor: _kOnCoral,
            disabledForegroundColor: _kOnCoral,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: _kOnCoral,
                  ),
                )
              : const Text(
                  'Log in',
                  style: TextStyle(
                    color: _kOnCoral,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}