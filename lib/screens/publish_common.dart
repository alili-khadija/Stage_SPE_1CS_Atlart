import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const coral = Color(0xFFFF7373);
  static const sectionBlue = Color(0xFF4A6FA5);
  static const progress = Color(0xFF4F6D9A);
  static const ink = Color(0xFF1F2F46);
  static const hint = Color(0xFF8A8F98);
  static const tipBg = Color(0xFFFDEBCB);
  static const tipText = Color(0xFF8A5A00);
  static const dashed = Color(0xFFE8C44A);
  static const cream = Color(0xFFF6EEDD);
  static const infoBg = Color(0xFFC9D9F2);
  static const infoText = Color(0xFF3F5F8F);
  static const chipBg = Color(0xFFFCE9C8);
  static const chipText = Color(0xFF9A6A1A);
}

enum SaleMode { exhibitionOnly, openToOffers, sold }

String formatThousands(int value) {
  final digits = value.toString();
  final result = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) result.write(' ');
    result.write(digits[i]);
  }

  return result.toString();
}

String formatPrice(String raw) {
  final value = int.tryParse(raw.replaceAll(RegExp(r'\D'), ''));
  return value == null ? '' : formatThousands(value);
}

class ArtworkDraft {
  final List<String> photoPaths = [];

  String title = '';
  String technique = '';
  String length = '';
  String height = '';
  String tags = '';
  String description = '';
  String location = '';
  int year = DateTime.now().year;

  SaleMode? saleMode;
  bool negotiable = true;
  String price = '';

  String? get mainPhoto => photoPaths.isEmpty ? null : photoPaths.first;

  List<String> get tagList => tags
      .split(RegExp(r'[,\s]+'))
      .map((tag) => tag.replaceAll('#', '').trim())
      .where((tag) => tag.isNotEmpty)
      .map((tag) => '${tag[0].toUpperCase()}${tag.substring(1)}')
      .toList();
}

class PublishScaffold extends StatelessWidget {
  const PublishScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.child,
    required this.onNext,
    this.serifTitle = false,
    this.totalSteps = 4,
    this.buttonLabel = 'Suivant',
    this.busy = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final bool serifTitle;
  final int step;
  final int totalSteps;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onNext;
  final bool busy;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSteps > 0 ? totalSteps : 1;
    final safeStep = step.clamp(0, safeTotal).toInt();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8FB0DE),
                Color(0xFFDCEBFA),
                Color(0xFFC9DFF6),
              ],
              stops: [0, 0.25, 1],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: _PublishHeader(
                        title: title,
                        serif: serifTitle,
                        step: safeStep,
                        total: safeTotal,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                        child: child,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (secondaryLabel != null) ...[
                            _SecondaryButton(
                              label: secondaryLabel!,
                              onPressed: busy ? null : onSecondary,
                            ),
                            const SizedBox(height: 10),
                          ],
                          _PrimaryButton(
                            label: buttonLabel,
                            onPressed: onNext,
                            busy: busy,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PublishHeader extends StatelessWidget {
  const _PublishHeader({
    required this.title,
    required this.serif,
    required this.step,
    required this.total,
  });

  final String title;
  final bool serif;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Retour',
              onPressed: () => Navigator.maybePop(context),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                serif ? title.toUpperCase() : title,
                overflow: TextOverflow.ellipsis,
                style: serif
                    ? GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )
                    : GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$step / $total',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.hint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.white.withValues(alpha: 0.6)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: total == 0 ? 0.0 : step / total,
                    child: const ColoredBox(color: AppColors.progress),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || busy;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.62,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.coral,
            disabledBackgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E4A73),
          side: const BorderSide(color: Color(0xFF2E4A73)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.sectionBlue,
        letterSpacing: 0.3,
      ),
    );
  }
}

class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    required this.color,
    this.fill,
    this.radius = 16,
  });

  final Widget child;
  final Color color;
  final Color? fill;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: color, radius: radius),
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
    const strokeWidth = 1.2;
    const dashLength = 3.0;
    const dashGap = 3.0;

    if (size.width <= strokeWidth || size.height <= strokeWidth) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end =
            (distance + dashLength).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}