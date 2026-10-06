import 'package:flutter/material.dart';

import '../models/offer_status.dart';
import '../widgets/offers_ui.dart';
import 'my_offers_screen.dart' show BuyerOffer;
import 'offer_accepted.dart';

/// Un message de la négociation : un montant (+ texte optionnel).
class OfferMessage {
  const OfferMessage({
    required this.amount,
    required this.time,
    required this.fromSeller,
    this.text,
  });

  final String amount; // ex. « 1 700 MAD »
  final String time; // ex. « 15:10 »
  final bool fromSeller;
  final String? text;
}

/// « Mes offres » → détail d'une négociation (Figma : Acheteur, 2e écran).
class OfferNegotiationScreen extends StatefulWidget {
  const OfferNegotiationScreen({
    super.key,
    required this.offer,
    this.messages,
    this.onStatusChanged,
  });

  final BuyerOffer offer;

  /// Historique réel de la négociation. Si absent, un aperçu est généré.
  final List<OfferMessage>? messages;
  final void Function(OfferStatus status, String? agreedPrice)? onStatusChanged;

  @override
  State<OfferNegotiationScreen> createState() => _OfferNegotiationScreenState();
}

class _OfferNegotiationScreenState extends State<OfferNegotiationScreen> {
  final _scroll = ScrollController();
  late final List<OfferMessage> _messages = List.of(
    widget.messages ?? _previewThread(widget.offer),
  );
  bool _busy = false;

  static List<OfferMessage> _previewThread(BuyerOffer offer) => [
    OfferMessage(
      amount: offer.price,
      time: '14:02',
      fromSeller: false,
      text: offer.message.isEmpty ? null : offer.message,
    ),
    const OfferMessage(
      amount: '1 700 MAD',
      time: '15:10',
      fromSeller: true,
      text: 'Merci pour votre intérêt ! Je peux descendre à ce prix.',
    ),
  ];

  /// Le dernier mot est à l'acheteur : on attend la réponse de l'artiste.
  bool get _awaitingSeller => _messages.isEmpty || !_messages.last.fromSeller;

  /// Dernier montant proposé par l'artiste (celui qu'on peut accepter).
  String? get _sellerAmount {
    for (final m in _messages.reversed) {
      if (m.fromSeller) return m.amount;
    }
    return null;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _accept() {
    final amount = _sellerAmount;
    if (_busy || _awaitingSeller || amount == null) return;
    setState(() => _busy = true);
    widget.onStatusChanged?.call(OfferStatus.accepte, amount);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OfferAcceptedScreen(
          amount: amount,
          artisanName: widget.offer.artisan,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      ),
    );
  }

  void _refuse() {
    if (_busy) return;
    widget.onStatusChanged?.call(OfferStatus.refuse, null);
    Navigator.of(context).pop();
  }

  Future<void> _counterOffer() async {
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CounterOfferSheet(),
    );
    if (amount == null || !mounted) return;

    final now = TimeOfDay.now();
    setState(() {
      _messages.add(
        OfferMessage(
          amount: offerFormatMad(amount),
          time:
              '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}',
          fromSeller: false,
        ),
      );
    });

    // TODO : envoyer la contre-proposition à votre API.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Contre-proposition envoyée (aperçu).')),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final sellerAmount = _sellerAmount;

    return OffersScaffold(
      title: 'Mes offres',
      navIndex: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 8, 26, 12),
            child: OfferSummaryCard(
              title: offer.title,
              subtitle: offer.artisan,
              thumbColor: offer.thumbnailColor,
              trailingAmount: offer.price,
              trailingCaption: offer.timeAgo,
              status: offer.status,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(26, 8, 26, 12),
              child: _ConversationPanel(messages: _messages),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 6, 26, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OfferPrimaryButton(
                  label: _awaitingSeller || sellerAmount == null
                      ? 'En attente de l’artiste…'
                      : 'Accepter $sellerAmount',
                  height: 46,
                  busy: _busy,
                  onPressed: _awaitingSeller || sellerAmount == null
                      ? null
                      : _accept,
                ),
                const SizedBox(height: 8),
                OfferOutlineButton(
                  label: 'Refuser',
                  onPressed: _busy ? null : _refuse,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _busy ? null : _counterOffer,
                  child: Text(
                    'Faire une contre-proposition',
                    style: OfferText.poppins(
                      10.5,
                      weight: FontWeight.w700,
                      color: OfferColors.navy,
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le panneau dégradé ardoise de la maquette qui contient les bulles.
class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({required this.messages});
  final List<OfferMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5F7089), Color(0xFFB7C7DC)],
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < messages.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _Bubble(message: messages[i]),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final OfferMessage message;

  @override
  Widget build(BuildContext context) {
    final seller = message.fromSeller;
    final fg = seller ? Colors.white : OfferColors.navy;

    return Align(
      alignment: seller ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.92,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: seller ? const Color(0xFF6B84AB) : Colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.amount, style: OfferText.serif(14, color: fg)),
              if (message.text != null) ...[
                const SizedBox(height: 6),
                Text(
                  message.text!,
                  style: OfferText.poppins(10.5, color: fg, height: 1.45),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                message.time,
                style: OfferText.poppins(
                  8,
                  color: seller ? Colors.white70 : OfferColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feuille « Faire une contre-proposition » : renvoie un montant entier (MAD).
class _CounterOfferSheet extends StatefulWidget {
  const _CounterOfferSheet();

  @override
  State<_CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends State<_CounterOfferSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = offerParseAmount(_controller.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Saisissez un montant valide.');
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: OfferColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Faire une contre-proposition',
                  textAlign: TextAlign.center,
                  style: OfferText.poppins(14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Proposez un nouveau montant à l’artiste.',
                  textAlign: TextAlign.center,
                  style: OfferText.poppins(10, color: OfferColors.muted),
                ),
                const SizedBox(height: 18),
                OfferAmountField(
                  controller: _controller,
                  autofocus: true,
                  errorText: _error,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                const SizedBox(height: 18),
                OfferPrimaryButton(label: 'Envoyer', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
