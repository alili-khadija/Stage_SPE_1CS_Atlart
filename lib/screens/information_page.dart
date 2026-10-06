import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'publish_common.dart';
import 'sale_screen.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key, required this.draft});

  final ArtworkDraft draft;

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  late final TextEditingController _title =
      TextEditingController(text: widget.draft.title);
  late final TextEditingController _technique =
      TextEditingController(text: widget.draft.technique);
  late final TextEditingController _length =
      TextEditingController(text: widget.draft.length);
  late final TextEditingController _height =
      TextEditingController(text: widget.draft.height);
  late final TextEditingController _tags =
      TextEditingController(text: widget.draft.tags);
  late final TextEditingController _description =
      TextEditingController(text: widget.draft.description);

  @override
  void initState() {
    super.initState();
    for (final controller in [_title, _technique, _length, _height]) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _isValid =>
      _title.text.trim().isNotEmpty &&
      _technique.text.trim().isNotEmpty &&
      _length.text.trim().isNotEmpty &&
      _height.text.trim().isNotEmpty;

  void _saveDraft() {
    widget.draft
      ..title = _title.text.trim()
      ..technique = _technique.text.trim()
      ..length = _length.text.trim()
      ..height = _height.text.trim()
      ..tags = _tags.text.trim()
      ..description = _description.text.trim();
  }

  void _next() {
    if (!_isValid) return;
    _saveDraft();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SalePage(draft: widget.draft),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _technique,
      _length,
      _height,
      _tags,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PublishScaffold(
      title: 'Information',
      serifTitle: true,
      step: 2,
      onNext: _isValid ? _next : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel("Détails de l'œuvre"),
          const SizedBox(height: 28),
          _FieldCard(
            label: 'Titre',
            controller: _title,
            hint: 'Ex : Médina, fragments',
            bold: true,
          ),
          const SizedBox(height: 10),
          _FieldCard(
            label: 'Technique',
            controller: _technique,
            hint: 'Ex : Techniques mixtes, poterie…',
            bold: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FieldCard(
                  label: 'Longueur',
                  controller: _length,
                  hint: 'L cm',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FieldCard(
                  label: 'Hauteur',
                  controller: _height,
                  hint: 'H cm',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FieldCard(
            label: 'Tags',
            controller: _tags,
            hint: 'Ex : #peinture, #moderne',
            minLines: 3,
          ),
          const SizedBox(height: 10),
          _FieldCard(
            label: 'Description (caption)',
            controller: _description,
            hint: "Le contexte ou l'histoire derrière cette création…",
            minLines: 4,
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.controller,
    required this.hint,
    this.bold = false,
    this.minLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool bold;
  final int minLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final multiline = minLines > 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: AppColors.hint,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            keyboardType: keyboardType ??
                (multiline ? TextInputType.multiline : TextInputType.text),
            inputFormatters: inputFormatters,
            minLines: minLines,
            maxLines: multiline ? null : 1,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}