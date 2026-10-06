import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/atlart_ui_theme.dart';

/// Boîte commune à tous les champs (fond, coins arrondis, ombre, erreur).
class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child, this.hasError = false, this.shadows})
    : fill = Colors.white,
      height = 51,
      padding = const EdgeInsets.symmetric(horizontal: 14);

  final Widget child;
  final bool hasError;
  final Color fill;
  final double height;
  final EdgeInsets padding;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: hasError ? AtlartPalette.errorBg : fill,
        borderRadius: BorderRadius.circular(14),
        border: hasError ? Border.all(color: AtlartPalette.errorBorder) : null,
        boxShadow: hasError ? null : shadows,
      ),
      child: child,
    );
  }
}

/// Message d'erreur rouge, avec lien souligné optionnel.
class AtlartError extends StatelessWidget {
  const AtlartError({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(message, style: AtlartType.errorText),
        if (actionLabel != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                actionLabel!,
                style: AtlartType.errorText.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: AtlartPalette.error,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Champ blanc avec label en majuscules dans le champ.
class AtlartField extends StatelessWidget {
  const AtlartField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.errorText,
    this.errorActionLabel,
    this.onErrorAction,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? errorActionLabel;
  final VoidCallback? onErrorAction;

  bool get hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldBox(
          hasError: hasError,
          shadows: const [AtlartShadows.field],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: AtlartType.fieldLabel),
                    const SizedBox(height: 2),
                    TextField(
                      controller: controller,
                      obscureText: obscureText,
                      keyboardType: keyboardType,
                      inputFormatters: inputFormatters,
                      textInputAction: textInputAction,
                      onChanged: onChanged,
                      cursorColor: AtlartPalette.blueText,
                      style: AtlartType.fieldValue,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: hint,
                        hintStyle: AtlartType.fieldHint,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              if (onToggleObscure != null)
                IconButton(
                  tooltip: obscureText
                      ? 'Afficher le mot de passe'
                      : 'Masquer le mot de passe',
                  onPressed: onToggleObscure,
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    size: 17,
                    color: AtlartPalette.blueText,
                  ),
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 9),
            child: AtlartError(
              message: errorText!,
              actionLabel: errorActionLabel,
              onAction: onErrorAction,
            ),
          ),
      ],
    );
  }
}

/// Champ « liste déroulante » (Pays).
class AtlartDropdown<T> extends StatelessWidget {
  const AtlartDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: _FieldBox(
        shadows: const [AtlartShadows.field],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AtlartType.fieldLabel),
            const SizedBox(height: 2),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                isDense: true,
                style: AtlartType.fieldValue.copyWith(
                  fontWeight: FontWeight.w400,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton principal corail.
class AtlartButton extends StatelessWidget {
  const AtlartButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [AtlartShadows.button],
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AtlartPalette.coral,
            disabledBackgroundColor: loading
                ? AtlartPalette.coral
                : AtlartPalette.coralSoft,
            foregroundColor: AtlartPalette.onCoral,
            disabledForegroundColor: AtlartPalette.onCoral,
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
                    color: AtlartPalette.onCoral,
                  ),
                )
              : Text(label, style: AtlartType.buttonLabel),
        ),
      ),
    );
  }
}

/// Bouton secondaire.
class AtlartGhostButton extends StatelessWidget {
  const AtlartGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 49,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AtlartPalette.navyDark, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4D6C9F),
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Ligne de lien.
class AtlartFooter extends StatelessWidget {
  const AtlartFooter({
    super.key,
    required this.leading,
    required this.action,
    required this.onTap,
    this.fontSize = 11,
    this.stacked = false,
    this.actionWeight = FontWeight.w600,
  });

  final String leading;
  final String action;
  final VoidCallback onTap;
  final double fontSize;
  final bool stacked;
  final FontWeight actionWeight;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      color: AtlartPalette.navyDark,
      fontSize: fontSize,
      height: 1.4,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
    );
    final actionStyle = base.copyWith(
      fontWeight: actionWeight,
      decoration: TextDecoration.underline,
      decorationColor: AtlartPalette.navyDark,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: stacked ? '${leading.trimRight()}\n' : leading,
                style: base,
              ),
              TextSpan(text: action, style: actionStyle),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Bandeau logo.
class AtlartHeaderLogo extends StatelessWidget {
  const AtlartHeaderLogo({super.key});

  static double _logoTop(BuildContext context) {
    final t = MediaQuery.of(context).padding.top + 2;
    return t > 8 ? t : 8;
  }

  static double heightOf(BuildContext context) {
    final h = _logoTop(context) + 40;
    return h > 56 ? h : 56;
  }

  static double gapBefore(BuildContext context, double titleTop) {
    final g = titleTop - heightOf(context);
    return g < 6 ? 6 : g;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightOf(context),
      child: Padding(
        padding: EdgeInsets.only(top: _logoTop(context)),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 40,
            child: Image.asset(
              AtlartAssets.logoHorizontal,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const _FallbackHeaderLogo(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackHeaderLogo extends StatelessWidget {
  const _FallbackHeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AtlartAssets.logo,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 4),
        const Text(
          'ATLART',
          style: TextStyle(
            color: AtlartPalette.blueText,
            fontSize: 15,
            letterSpacing: 0.8,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
