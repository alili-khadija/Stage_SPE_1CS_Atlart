import 'package:flutter/material.dart';

import '../models/offer_status.dart';
import '../widgets/offers_ui.dart';
import 'my_offers_screen.dart';

class OfferCreateScreen extends StatefulWidget {
  const OfferCreateScreen({
    super.key,
    required this.title,
    required this.artisanName,
    this.suggestedAmount = '1500',
    this.startingPrice,
    this.artisanCity,
    this.thumbnailColor = const Color(0xFF258F81),
  });

  final String title;
  final String artisanName;
  final String suggestedAmount;
  final String? startingPrice;
  final String? artisanCity;
  final Color thumbnailColor;

  @override
  State<OfferCreateScreen> createState() => _OfferCreateScreenState();
}

class _OfferCreateScreenState extends State<OfferCreateScreen> {
  late final TextEditingController _amount = TextEditingController(
    text: offerGroupDigits(widget.suggestedAmount),
  );
  final _message = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  void _sendOffer() {
    FocusScope.of(context).unfocus();
    final amount = offerParseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Saisissez un montant valide.');
      return;
    }

    setState(() => _sending = true);
    final offer = BuyerOffer(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: widget.title,
      price: offerFormatMad(amount),
      artisan: widget.artisanName,
      timeAgo: 'À l’instant',
      status: OfferStatus.enNegociation,
      thumbnailColor: widget.thumbnailColor,
      message: _message.text.trim(),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => MyOffersScreen(initialOffer: offer),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.artisanCity;
    return OffersScaffold(
      title: 'Faire une offre',
      showLogo: false,
      showBack: true,
      showNav: false,
      light: true,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OfferSummaryCard(
                    title: widget.title,
                    subtitle: city == null || city.isEmpty
                        ? widget.artisanName
                        : '${widget.artisanName} · $city',
                    thumbColor: widget.thumbnailColor,
                    priceLine: widget.startingPrice == null
                        ? null
                        : 'Prix de départ : ${widget.startingPrice}',
                  ),
                  const SizedBox(height: 30),
                  const OfferSectionLabel('Votre proposition'),
                  const SizedBox(height: 10),
                  OfferAmountField(
                    controller: _amount,
                    errorText: _error,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 18),
                  const OfferNote(
                    text:
                        'L’artiste peut accepter, refuser, ou vous faire '
                        'une contre-proposition. Cette offre n’est pas un '
                        'paiement — le règlement se fait directement avec '
                        'l’artiste.',
                  ),
                  const SizedBox(height: 12),
                  _MessageField(controller: _message),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: OfferPrimaryButton(
              label: 'Envoyer l’offre',
              busy: _sending,
              shadow: true,
              onPressed: _sending ? null : _sendOffer,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageField extends StatelessWidget {
  const _MessageField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: OfferColors.shadow,
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      minLines: 3,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: OfferColors.navy,
      style: OfferText.poppins(11.5),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: 'Ajoutez un mot pour votre proposition...',
        hintStyle: OfferText.poppins(11, color: OfferColors.muted),
      ),
    ),
  );
}
