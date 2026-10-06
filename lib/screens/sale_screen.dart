import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'publish_common.dart';
import 'verifications_screen.dart';

class SalePage extends StatefulWidget {
  const SalePage({super.key, required this.draft});

  final ArtworkDraft draft;

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  late SaleMode? _mode = widget.draft.saleMode;
  late bool _negotiable = widget.draft.negotiable;
  late final TextEditingController _price =
      TextEditingController(text: widget.draft.price);

  @override
  void initState() {
    super.initState();
    _price.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  bool get _valid {
    if (_mode == null) return false;
    if (_mode == SaleMode.openToOffers) {
      return (int.tryParse(_price.text) ?? 0) > 0;
    }
    return true;
  }

  void _next() {
    if (!_valid) return;

    widget.draft
      ..saleMode = _mode
      ..negotiable = _negotiable
      ..price = _mode == SaleMode.openToOffers
          ? _price.text.replaceAll(RegExp(r'\D'), '')
          : '';

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VerificationPage(draft: widget.draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublishScaffold(
      title: 'Information',
      serifTitle: true,
      step: 3,
      onNext: _valid ? _next : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel("Détails de l'œuvre"),
          const SizedBox(height: 28),
          _OptionCard(
            icon: Icons.menu_book_outlined,
            iconBg: const Color(0xFFF3E1B8),
            iconColor: const Color(0xFF5A6B8C),
            title: 'Exposition seule',
            subtitle: 'Non destinée à la vente',
            selected: _mode == SaleMode.exhibitionOnly,
            dimmed: _mode != null && _mode != SaleMode.exhibitionOnly,
            onTap: () => setState(() => _mode = SaleMode.exhibitionOnly),
          ),
          const SizedBox(height: 10),
          _OptionCard(
            icon: Icons.add,
            iconBg: const Color(0xFFFDE8CF),
            iconColor: const Color(0xFFE39A5B),
            title: 'Ouverte aux propositions',
            subtitle: 'Prix fixe ou négociable',
            selected: _mode == SaleMode.openToOffers,
            dimmed: _mode != null && _mode != SaleMode.openToOffers,
            onTap: () => setState(() => _mode = SaleMode.openToOffers),
          ),
          const SizedBox(height: 10),
          _OptionCard(
            icon: Icons.check,
            iconBg: const Color(0xFFFCE0DC),
            iconColor: AppColors.coral,
            title: 'Déjà vendue',
            subtitle: 'Visible mais non disponible',
            selected: _mode == SaleMode.sold,
            dimmed: _mode != null && _mode != SaleMode.sold,
            onTap: () => setState(() => _mode = SaleMode.sold),
          ),
          const SizedBox(height: 32),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _buildDetail(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail() {
    switch (_mode) {
      case null:
        return const SizedBox(width: double.infinity);
      case SaleMode.exhibitionOnly:
        return const _NoteCard(
          "Aucun prix à renseigner — cette œuvre n'est pas mise en vente.",
        );
      case SaleMode.sold:
        return const _NoteCard(
          "Aucun prix à renseigner — l'œuvre reste visible mais n'est plus "
          "disponible.",
        );
      case SaleMode.openToOffers:
        return _buildOffersPanel();
    }
  }

  Widget _buildOffersPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _segment(
                title: 'Prix fixe',
                subtitle: 'Pas de négociation',
                selected: !_negotiable,
                onTap: () => setState(() => _negotiable = false),
              ),
              const SizedBox(width: 8),
              _segment(
                title: 'Négociable',
                subtitle: 'Les visiteurs proposent',
                selected: _negotiable,
                onTap: () => setState(() => _negotiable = true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.hint,
                      ),
                    ),
                  ),
                ),
                Text(
                  'MAD',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppColors.hint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _negotiable
                ? "C'est votre prix de départ. Les visiteurs pourront vous "
                    "faire des propositions : vous restez libre d'accepter, "
                    "refuser ou contre-proposer."
                : "C'est votre prix de vente. Les visiteurs ne pourront pas "
                    "négocier.",
            style: GoogleFonts.inter(
              fontSize: 9,
              height: 1.4,
              color: AppColors.hint,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 12,
                  color: AppColors.progress,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _negotiable
                        ? 'Le bouton « Faire une offre » apparaîtra sur votre '
                            'fiche œuvre.'
                        : 'Le bouton « Acheter » apparaîtra sur votre '
                            'fiche œuvre.',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      height: 1.4,
                      color: AppColors.infoText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7E9CC7), AppColors.progress],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? null
                : Border.all(color: const Color(0xFFE3E6EB)),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  color: selected ? Colors.white70 : AppColors.hint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: dimmed ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        color: const Color(0xFF9C7A3C),
                      ),
                    ),
                  ],
                ),
              ),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.progress, width: 1.5),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.progress,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 9,
          height: 1.5,
          color: const Color(0xFF8A6D3B),
        ),
      ),
    );
  }
}