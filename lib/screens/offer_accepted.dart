import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/offers_ui.dart';

class OfferAcceptedScreen extends StatefulWidget {
  const OfferAcceptedScreen({
    super.key,
    required this.amount,
    required this.artisanName,
    required this.expiresAt,
    this.artisanId,
    this.expiresLabel,
    this.onContactArtist,
  });

  final String amount;
  final String artisanName;
  final DateTime expiresAt;
  final String? artisanId;
  final String? expiresLabel;
  final VoidCallback? onContactArtist;

  @override
  State<OfferAcceptedScreen> createState() => _OfferAcceptedScreenState();
}

class _OfferAcceptedScreenState extends State<OfferAcceptedScreen> {
  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  Timer? _timer;
  late Duration _remaining = _difference();

  @override
  void initState() {
    super.initState();
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _remaining = _difference());
        if (_remaining == Duration.zero) timer.cancel();
      });
    }
  }

  Duration _difference() {
    final difference = widget.expiresAt.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String get _countdown =>
      '${_two(_remaining.inHours)}:'
      '${_two(_remaining.inMinutes % 60)}:'
      '${_two(_remaining.inSeconds % 60)}';

  String get _expiryLabel {
    if (_remaining == Duration.zero) {
      return 'Le délai de confirmation est expiré';
    }
    if (widget.expiresLabel != null) return widget.expiresLabel!;
    final date = widget.expiresAt;
    return 'Expire le ${date.day} ${_months[date.month - 1]} '
        'à ${_two(date.hour)}:${_two(date.minute)}';
  }

  void _contactArtist() {
    final callback = widget.onContactArtist;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).pushNamed('/messages');
  }

  @override
  Widget build(BuildContext context) {
    return OffersScaffold(
      navIndex: 3,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 12, 30, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 36),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBCD6F3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33496E9C),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Offre acceptée !',
                  style: OfferText.poppins(
                    14,
                    weight: FontWeight.w700,
                    color: OfferColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: OfferText.poppins(
                      10.5,
                      color: const Color(0xFF2D4560),
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(text: 'Votre offre de '),
                      TextSpan(
                        text: widget.amount,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            ' a été acceptée par ${widget.artisanName}. '
                            'La pièce vous est réservée le temps de finaliser.',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: OfferColors.slate,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'TEMPS RESTANT POUR CONFIRMER',
                        style: OfferText.poppins(
                          8,
                          weight: FontWeight.w500,
                          color: Colors.white70,
                          spacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _countdown,
                        style:
                            OfferText.poppins(
                              27,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _expiryLabel,
                        style: OfferText.poppins(8, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: OfferColors.line),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Montant convenu',
                        style: OfferText.poppins(
                          10.5,
                          color: OfferColors.olive,
                        ),
                      ),
                      Text(
                        widget.amount,
                        style: OfferText.poppins(
                          10.5,
                          weight: FontWeight.w700,
                          color: OfferColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OfferPrimaryButton(
                  label: 'Contacter l’artiste',
                  height: 48,
                  onPressed: _contactArtist,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
