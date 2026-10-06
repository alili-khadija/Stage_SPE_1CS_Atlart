import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';

class AtlartLogoStepHeader extends StatelessWidget {
  const AtlartLogoStepHeader({
    super.key,
    required this.title,
    required this.step,
    this.totalSteps = 4,
    this.showBack = false,
    this.onBack,
    this.logoAsset = AtlartAssets.logoHorizontal,
  });

  final String title;
  final int step;
  final int totalSteps;
  final bool showBack;
  final VoidCallback? onBack;
  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final safeTotalSteps = totalSteps < 1 ? 1 : totalSteps;
    final safeStep = step.clamp(0, safeTotalSteps);
    final progress = safeStep / safeTotalSteps;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 6, 20, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8DB6E1),
            Color(0xFFC3DAF2),
            Colors.white,
          ],
          stops: [0, 0.72, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 34,
            child: Image.asset(
              logoAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(
                child: Text(
                  'ATLART',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 3,
                    color: Color(0xFF2E5C8A),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (showBack)
                IconButton(
                  tooltip: 'Retour',
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Semantics(
                label: 'Étape $safeStep sur $safeTotalSteps',
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$safeStep / $safeTotalSteps',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Color(0xFF1F3A5F),
                      ),
                    ),
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
                  ColoredBox(color: Colors.white.withValues(alpha: 0.75)),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.toDouble(),
                    child: const ColoredBox(color: Color(0xFF6F9BD6)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AtlartCloudBackground extends StatelessWidget {
  const AtlartCloudBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(left: -90, top: 60, child: _CloudBlob(size: 260)),
          Positioned(right: -110, bottom: -60, child: _CloudBlob(size: 320)),
        ],
      ),
    );
  }
}

class _CloudBlob extends StatelessWidget {
  const _CloudBlob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x66BFD9F5), Color(0x00BFD9F5)],
        ),
      ),
    );
  }
}
