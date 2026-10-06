import 'package:flutter/material.dart';

import '../models/offer_status.dart';
import '../widgets/offers_ui.dart';
import 'offer_negotiation_screen.dart';

class BuyerOffer {
  const BuyerOffer({
    required this.id,
    required this.title,
    required this.price,
    required this.artisan,
    required this.timeAgo,
    required this.status,
    required this.thumbnailColor,
    this.message = '',
  });

  final String id;
  final String title;
  final String price;
  final String artisan;
  final String timeAgo;
  final OfferStatus status;
  final Color thumbnailColor;
  final String message;

  BuyerOffer copyWith({String? price, String? timeAgo, OfferStatus? status}) =>
      BuyerOffer(
        id: id,
        title: title,
        price: price ?? this.price,
        artisan: artisan,
        timeAgo: timeAgo ?? this.timeAgo,
        status: status ?? this.status,
        thumbnailColor: thumbnailColor,
        message: message,
      );
}

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key, this.initialOffer});

  final BuyerOffer? initialOffer;

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  bool _showSent = true;

  late final List<BuyerOffer> _sent = [
    if (widget.initialOffer != null) widget.initialOffer!,
    const BuyerOffer(
      id: 'demo-1',
      title: 'Médina, fragments',
      price: '1 500 MAD',
      artisan: 'Yasmine Bouzidi',
      timeAgo: 'Il y a 2 h',
      status: OfferStatus.enNegociation,
      thumbnailColor: Color(0xFF258F81),
    ),
    const BuyerOffer(
      id: 'demo-2',
      title: 'Poterie de Safi',
      price: '420 MAD',
      artisan: 'Atelier Amrani',
      timeAgo: 'Hier',
      status: OfferStatus.accepte,
      thumbnailColor: Color(0xFFB49B82),
    ),
    const BuyerOffer(
      id: 'demo-3',
      title: 'Zellige bleu',
      price: '2 200 MAD',
      artisan: 'Yasmine Bouzidi',
      timeAgo: 'Il y a 3 jours',
      status: OfferStatus.accepte,
      thumbnailColor: Color(0xFFE88D63),
    ),
  ];

  final List<BuyerOffer> _received = const [
    BuyerOffer(
      id: 'received-1',
      title: 'Tapis Beni Ourain',
      price: '1 800 MAD',
      artisan: 'Coopérative Tafraout',
      timeAgo: 'Aujourd’hui',
      status: OfferStatus.enNegociation,
      thumbnailColor: Color(0xFF7389AC),
    ),
  ];

  Future<void> _openOffer(BuyerOffer offer) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OfferNegotiationScreen(
          offer: offer,
          onStatusChanged: (status, price) {
            final index = _sent.indexWhere((item) => item.id == offer.id);
            if (index < 0 || !mounted) return;
            setState(() {
              _sent[index] = offer.copyWith(status: status, price: price);
            });
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final offers = _showSent ? _sent : _received;

    return OffersScaffold(
      title: 'Mes offres',
      navIndex: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                _OfferTab(
                  label: 'Envoyées · ${_sent.length}',
                  selected: _showSent,
                  onTap: () => setState(() => _showSent = true),
                ),
                const SizedBox(width: 10),
                _OfferTab(
                  label: 'Reçues · ${_received.length}',
                  selected: !_showSent,
                  onTap: () => setState(() => _showSent = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: offers.isEmpty
                ? Center(
                    child: Text(
                      _showSent
                          ? 'Aucune offre envoyée.'
                          : 'Aucune offre reçue.',
                      style: OfferText.poppins(13, color: OfferColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: offers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _OfferCard(
                      offer: offers[index],
                      onTap: () => _openOffer(offers[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OfferTab extends StatelessWidget {
  const _OfferTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF637FA6) : const Color(0xFFD4E1F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF59708F),
            fontSize: 10,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onTap});

  final BuyerOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: OfferSummaryCard(
        title: offer.title,
        subtitle: offer.artisan,
        thumbColor: offer.thumbnailColor,
        trailingAmount: offer.price,
        trailingCaption: offer.timeAgo,
        status: offer.status,
      ),
    );
  }
}
