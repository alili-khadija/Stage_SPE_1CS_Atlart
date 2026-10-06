import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';

class AtlartStepHeader extends StatelessWidget {
  const AtlartStepHeader({
    super.key,
    required this.title,
    required this.step,
    required this.totalSteps,
    this.showBack = false,
    this.showBrand = true,
    this.onBack,
  });

  final String title;
  final int step;
  final int totalSteps;
  final bool showBack;
  final bool showBrand;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps <= 0
        ? 0.0
        : (step / totalSteps).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: EdgeInsets.fromLTRB(18, showBrand ? 8 : 14, 18, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AtlartPalette.skyHeader, Color(0xFFEAF4FD)],
        ),
      ),
      child: Column(
        children: [
          if (showBrand)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                'Atlart',
                style: AtlartType.title.copyWith(
                  fontSize: 19,
                  color: AtlartPalette.blueText,
                ),
              ),
            ),
          Row(
            children: [
              if (showBack) ...[
                IconButton(
                  tooltip: 'Retour',
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: AtlartPalette.navyDark,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$step / $totalSteps',
                  style: const TextStyle(
                    color: AtlartPalette.blueText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.white,
              color: AtlartPalette.blueText,
            ),
          ),
        ],
      ),
    );
  }
}
