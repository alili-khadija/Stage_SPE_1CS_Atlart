import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/artisan_product.dart';
import '../models/messaging.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/offers_ui.dart'
    show OfferColors, OfferNote, OfferPrimaryButton, OfferText;
import 'new_message_screen.dart';

String _messageSlug(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

class ArtisanProductDetailScreen extends StatelessWidget {
  const ArtisanProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final available = OrderStore.instance.stockLeft(product);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 280,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProductImage(product: product),
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 12,
                        left: 16,
                        child: _RoundAction(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Retour',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AtlartPalette.navyDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            product.priceLabel,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AtlartPalette.navyDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${product.category} · ${product.priceNote}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: AtlartPalette.blueTextLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoLine(
                        icon: Icons.location_on_outlined,
                        text: product.artisanLocation,
                      ),
                      const SizedBox(height: 8),
                      _InfoLine(
                        icon: Icons.inventory_2_outlined,
                        text: product.stock == null
                            ? 'Disponible'
                            : '$available disponibles',
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCEAF8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.storefront_outlined,
                                size: 19,
                                color: AtlartPalette.blueText,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.artisanName,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AtlartPalette.navyDark,
                                    ),
                                  ),
                                  Text(
                                    product.artisanLocation,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 9,
                                      color: AtlartPalette.blueText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF36B77A),
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        const _SectionHeading('À PROPOS DE CET ARTICLE'),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            height: 1.6,
                            color: AtlartPalette.navy,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE3ECF5))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (!product.isMine) ...[
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => openContact(
                          context,
                          recipient: ChatParticipant(
                            id: 'artisan-${_messageSlug(product.artisanName)}',
                            name: product.artisanName,
                            role: 'Artisan',
                            location: product.artisanLocation,
                          ),
                          about: ChatContext(
                            id: 'product-${product.id}',
                            kind: ChatContextKind.product,
                            title: product.title,
                            subtitle: product.priceLabel,
                            imageAsset: product.imageAsset,
                            thumbColor: product.thumbColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: AtlartPalette.navyDark),
                          shape: const CircleBorder(),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: AtlartPalette.navyDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OfferPrimaryButton(
                      label: product.isMine
                          ? 'Votre article'
                          : available == 0
                          ? 'Rupture de stock'
                          : 'Commander · ${product.priceLabel}',
                      onPressed: product.isMine || available == 0
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ArtisanOrderFormScreen(product: product),
                              ),
                            ),
                    ),
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

class ArtisanOrderFormScreen extends StatefulWidget {
  const ArtisanOrderFormScreen({super.key, required this.product});

  final Product product;

  @override
  State<ArtisanOrderFormScreen> createState() => _ArtisanOrderFormScreenState();
}

class _ArtisanOrderFormScreenState extends State<ArtisanOrderFormScreen> {
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _note = TextEditingController();
  int _quantity = 1;
  late FulfillmentMode _mode = widget.product.allowsPickup
      ? FulfillmentMode.pickup
      : FulfillmentMode.delivery;
  bool _busy = false;

  Product get _product => widget.product;
  int get _available => OrderStore.instance.stockLeft(_product);
  int get _total =>
      _product.price * _quantity +
      (_mode == FulfillmentMode.delivery ? _product.deliveryFee : 0);

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final order = await OrderStore.instance.place(
        product: _product,
        quantity: _quantity,
        mode: _mode,
        contact: OrderContact(
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          city: _city.text.trim(),
          note: _note.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ArtisanOrderConfirmationScreen(order: order),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Commande impossible : $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _OrderHeader(
            title: 'Passer une commande',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                const _SectionHeading('RÉCAPITULATIF'),
                const SizedBox(height: 12),
                _ProductSummary(product: product),
                const SizedBox(height: 14),
                _QuantityControl(
                  value: _quantity,
                  max: _available,
                  onChanged: (value) => setState(() => _quantity = value),
                ),
                const SizedBox(height: 22),
                const _SectionHeading('MODE DE RÉCEPTION'),
                const SizedBox(height: 10),
                if (product.allowsPickup)
                  _ModeOption(
                    title: 'Retrait atelier',
                    subtitle: product.artisanLocation,
                    selected: _mode == FulfillmentMode.pickup,
                    onTap: () => setState(() => _mode = FulfillmentMode.pickup),
                  ),
                if (product.allowsDelivery)
                  Padding(
                    padding: EdgeInsets.only(top: product.allowsPickup ? 8 : 0),
                    child: _ModeOption(
                      title: 'Livraison',
                      subtitle: product.deliveryFee == 0
                          ? 'Frais offerts'
                          : 'Frais : ${formatMoney(product.deliveryFee, product.currency)}',
                      selected: _mode == FulfillmentMode.delivery,
                      onTap: () =>
                          setState(() => _mode = FulfillmentMode.delivery),
                    ),
                  ),
                if (_mode == FulfillmentMode.delivery) ...[
                  const SizedBox(height: 14),
                  _OrderField(
                    label: 'Adresse de livraison',
                    hint: 'Rue et numéro',
                    controller: _address,
                    capitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 9),
                  _OrderField(
                    label: 'Ville',
                    hint: 'Votre ville',
                    controller: _city,
                    capitalization: TextCapitalization.words,
                  ),
                ],
                const SizedBox(height: 18),
                const _SectionHeading('COORDONNÉES'),
                const SizedBox(height: 10),
                _OrderField(
                  label: 'Téléphone',
                  hint: '+213 00 00 00 00',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()\-]')),
                  ],
                ),
                const SizedBox(height: 9),
                _OrderField(
                  label: 'Note pour l’artisan (facultatif)',
                  hint: 'Précisions pour votre commande',
                  controller: _note,
                  minLines: 2,
                  capitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                _PriceRow(
                  label: 'Sous-total',
                  value: formatMoney(
                    product.price * _quantity,
                    product.currency,
                  ),
                ),
                const SizedBox(height: 8),
                _PriceRow(
                  label: 'Livraison',
                  value: _mode == FulfillmentMode.delivery
                      ? formatMoney(product.deliveryFee, product.currency)
                      : '—',
                ),
                const Divider(height: 24),
                _PriceRow(
                  label: 'Total',
                  value: formatMoney(_total, product.currency),
                  bold: true,
                ),
                const SizedBox(height: 14),
                OfferNote(
                  text: product.autoAccept
                      ? 'La commande sera confirmée immédiatement.'
                      : 'Votre commande sera envoyée à l’artisan pour validation. '
                            'Aucun paiement n’est effectué dans cette démo.',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE3ECF5))),
            ),
            child: SafeArea(
              top: false,
              child: OfferPrimaryButton(
                label: 'Confirmer la commande',
                busy: _busy,
                onPressed: _busy ? null : _placeOrder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ArtisanOrderConfirmationScreen extends StatelessWidget {
  const ArtisanOrderConfirmationScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final accepted = order.status == OrderStatus.accepted;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 34),
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFFF7478),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              accepted ? 'Votre commande est confirmée' : 'Commande envoyée',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AtlartPalette.navyDark,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              accepted
                  ? 'L’artisan a accepté votre commande.'
                  : 'L’artisan doit confirmer la disponibilité de l’article.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                height: 1.5,
                color: AtlartPalette.blueText,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _OrderConfirmationCard(order: order),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
              child: OfferPrimaryButton(
                label: 'Continuer à découvrir',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.imagePath != null) {
      return Image.file(
        File(product.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ProductPlaceholder(product: product),
      );
    }
    if (product.imageAsset != null) {
      return Image.asset(
        product.imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ProductPlaceholder(product: product),
      );
    }
    return _ProductPlaceholder(product: product);
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: product.thumbColor,
    child: const Center(
      child: Icon(Icons.image_outlined, size: 38, color: Colors.white),
    ),
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: OfferColors.navy),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: AtlartPalette.blueText),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: AtlartPalette.navy,
          ),
        ),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: OfferText.poppins(
      9.5,
      weight: FontWeight.w700,
      color: OfferColors.steel,
      spacing: 0.4,
    ),
  );
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      18,
      MediaQuery.paddingOf(context).top + 12,
      18,
      18,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8FB5E0), Color(0xFFDCEBFA), Colors.white],
        stops: [0, 0.78, 1],
      ),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Retour',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        Expanded(
          child: Text(
            title,
            style: OfferText.poppins(
              15,
              weight: FontWeight.w700,
              color: AtlartPalette.navyDark,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFDCEAF8),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 52,
            height: 48,
            child: _ProductImage(product: product),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OfferText.poppins(
                  9.5,
                  weight: FontWeight.w700,
                  color: OfferColors.navy,
                ),
              ),
              Text(
                product.artisanName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OfferText.poppins(8, color: OfferColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          product.priceLabel,
          style: OfferText.poppins(
            9,
            weight: FontWeight.w700,
            color: OfferColors.navy,
          ),
        ),
      ],
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFDCEAF8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Quantité',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: AtlartPalette.blueText,
            ),
          ),
        ),
        _QuantityButton(
          icon: Icons.remove,
          enabled: value > 1,
          onTap: () => onChanged(value - 1),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: OfferText.poppins(
              12,
              weight: FontWeight.w700,
              color: OfferColors.navy,
            ),
          ),
        ),
        _QuantityButton(
          icon: Icons.add,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    ),
  );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: enabled ? OfferColors.steel : const Color(0xFFB9CCE1),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 25,
        height: 25,
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    ),
  );
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F0FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? OfferColors.steel : const Color(0xFFD3E3F2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 17,
            color: selected ? OfferColors.steel : OfferColors.muted,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: OfferText.poppins(
                    10,
                    weight: FontWeight.w600,
                    color: OfferColors.navy,
                  ),
                ),
                Text(
                  subtitle,
                  style: OfferText.poppins(8.5, color: OfferColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrderField extends StatelessWidget {
  const _OrderField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.minLines = 1,
    this.capitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int minLines;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6FC),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFD3E3F2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OfferText.poppins(8.5, color: OfferColors.muted)),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : null,
          keyboardType:
              keyboardType ??
              (minLines > 1 ? TextInputType.multiline : TextInputType.text),
          inputFormatters: inputFormatters,
          textCapitalization: capitalization,
          style: OfferText.poppins(10, color: OfferColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: OfferText.poppins(9.5, color: OfferColors.muted),
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(top: 4),
          ),
        ),
      ],
    ),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: OfferText.poppins(
            bold ? 11 : 9.5,
            weight: bold ? FontWeight.w700 : FontWeight.w400,
            color: bold ? OfferColors.navy : OfferColors.muted,
          ),
        ),
      ),
      Text(
        value,
        style: OfferText.poppins(
          bold ? 11 : 9.5,
          weight: bold ? FontWeight.w700 : FontWeight.w400,
          color: OfferColors.navy,
        ),
      ),
    ],
  );
}

class _OrderConfirmationCard extends StatelessWidget {
  const _OrderConfirmationCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFDCEAF8),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PriceRow(label: 'N° de commande', value: order.id),
        const SizedBox(height: 8),
        _PriceRow(label: 'Article', value: order.product.title),
        const SizedBox(height: 8),
        _PriceRow(label: 'Quantité', value: '${order.quantity}'),
        const SizedBox(height: 8),
        _PriceRow(
          label: order.mode == FulfillmentMode.pickup
              ? 'Retrait atelier'
              : 'Livraison · ${order.contact.city}',
          value: formatMoney(order.deliveryFee, order.product.currency),
        ),
        const Divider(height: 22),
        _PriceRow(
          label: 'Total',
          value: formatMoney(order.total, order.product.currency),
          bold: true,
        ),
        const SizedBox(height: 12),
        Text(
          'Artisan · ${order.product.artisanName}',
          style: OfferText.poppins(9, color: OfferColors.navy),
        ),
      ],
    ),
  );
}
