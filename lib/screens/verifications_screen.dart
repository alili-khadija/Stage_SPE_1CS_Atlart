import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'publish_common.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key, required this.draft});

  final ArtworkDraft draft;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _certified = false;

  ArtworkDraft get _draft => widget.draft;

  String get _saleLine {
    switch (_draft.saleMode) {
      case SaleMode.exhibitionOnly:
        return 'Exposition seule';
      case SaleMode.sold:
        return 'Déjà vendue';
      case SaleMode.openToOffers:
        final price = formatPrice(_draft.price);
        return _draft.negotiable
            ? 'Ouverte aux propositions · à partir de $price MAD'
            : 'Prix fixe · $price MAD';
      case null:
        return '';
    }
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Brouillon enregistré')),
      );
  }

  void _submit() {
    if (!_certified) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Œuvre envoyée')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PublishScaffold(
      title: 'Vérification',
      serifTitle: true,
      step: 4,
      onNext: _certified ? _submit : null,
      secondaryLabel: 'Enregistrer comme brouillon',
      onSecondary: _saveDraft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel("Détails de l'œuvre"),
          const SizedBox(height: 28),
          _buildSummary(),
          const SizedBox(height: 32),
          _buildCertification(),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final details = <String>[
      if (_draft.technique.trim().isNotEmpty)
        '${_draft.technique} · ${_draft.year}',
      if (_draft.location.trim().isNotEmpty) _draft.location.trim(),
      if (_draft.length.isNotEmpty || _draft.height.isNotEmpty)
        'Dimensions : ${_draft.length} × ${_draft.height} cm',
      if (_saleLine.isNotEmpty) _saleLine,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: _draft.mainPhoto == null
                  ? const ColoredBox(color: Color(0xFF5B77A5))
                  : Image.file(
                      File(_draft.mainPhoto!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: Color(0xFF5B77A5),
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _draft.title.isEmpty ? 'Œuvre sans titre' : _draft.title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in details)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  height: 1.4,
                  color: AppColors.ink,
                ),
              ),
            ),
          if (_draft.tagList.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final tag in _draft.tagList) _TagChip(tag),
              ],
            ),
          ],
          if (_draft.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _draft.description.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9,
                height: 1.4,
                color: AppColors.hint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertification() {
    return Semantics(
      label: "J'atteste être l'auteur de cette œuvre",
      checked: _certified,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _certified = !_certified),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _certified
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 15,
                height: 15,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: _certified ? AppColors.progress : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.progress, width: 1.3),
                ),
                child: _certified
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "J'atteste être l'auteur de cette œuvre",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Je certifie sur l'honneur que cette création est "
                      "originale et m'appartient. Une fausse déclaration peut "
                      "entraîner la suspension du compte.",
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w500,
          color: AppColors.chipText,
        ),
      ),
    );
  }
}