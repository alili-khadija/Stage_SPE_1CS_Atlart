import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import 'event_draft.dart';

// Mêmes tons que le dégradé de login_screen.dart (_kSky, _kFieldFill) :
// repris ici pour que l'écran de création d'événement se sente de la
// même famille que l'accueil, plutôt que posé sur un bleu plat sans
// rapport avec le reste du parcours.
const _kEventSky = Color(0xFFC2DFF7);
const _kEventFieldFill = Color(0xFFD5ECFF);
const _kDivider = Color(0xFFEDF2F9);
const _kCardBorder = Color(0xFFE4ECF6);

/// Fond en dégradé (ciel → blanc) commun à l'écran de création
/// d'événement et à l'écran de confirmation, pour les rattacher
/// visuellement à l'écran de connexion plutôt qu'à un bleu plat isolé.
class EventPageBackground extends StatelessWidget {
  const EventPageBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kEventSky, _kEventSky, Colors.white],
          stops: [0.0, 0.1, 0.46],
        ),
      ),
      child: child,
    );
  }
}

/// En-tête : flèche retour + titre. Posé directement dans la colonne de
/// la page plutôt qu'en `appBar:` à hauteur fixe — c'est ce qui causait
/// le "BOTTOM OVERFLOWED BY 4.0 PIXELS" : un `Size.fromHeight(60)` figé
/// qui ne laissait pas assez de place au contenu réel une fois la
/// police chargée. Ici la hauteur suit simplement son contenu, donc le
/// débordement ne peut plus se reproduire. La barre de progression
/// pleine (qui n'affichait aucune info utile sur un formulaire à une
/// seule page) est retirée au passage ; un court trait corail sous le
/// titre suffit comme signature, cohérent avec le soulignement corail
/// utilisé ailleurs dans l'app pour marquer une sélection active.
class EventFormHeader extends StatelessWidget {
  const EventFormHeader({super.key, this.title = 'Nouvel événement'});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AtlartPalette.navy),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AtlartPalette.navy,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(width: 30, height: 2.5, decoration: BoxDecoration(color: AtlartPalette.coral, borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),
            const SizedBox(width: 28), // équilibre visuellement la flèche de gauche
          ],
        ),
      ),
    );
  }
}

/// Petit bandeau "ÉTIQUETTE" avec son repère corail, utilisé devant
/// chaque groupe de champs — même logique que les intitulés de section
/// du reste de l'app (un trait de couleur avant un libellé en petites
/// capitales, plutôt qu'une simple majuscule brute).
class SectionEyebrow extends StatelessWidget {
  const SectionEyebrow({super.key, required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Row(
      children: [
        Container(width: 3, height: 12, decoration: BoxDecoration(color: AtlartPalette.coral, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10.5, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: AtlartPalette.navy, fontFamily: 'Poppins'),
        ),
      ],
    );
    if (trailing == null) return text;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [text, trailing!]);
  }
}

/// Carte qui regroupe plusieurs lignes de champs avec un simple filet
/// entre elles, au lieu d'une carte-ombre séparée par champ : c'est ce
/// qui rendait le formulaire chargé. Un seul contour, une seule ombre
/// légère, pour tout le groupe.
class FormSection extends StatelessWidget {
  const FormSection({super.key, this.eyebrow, this.trailing, required this.rows});
  final String? eyebrow;
  final Widget? trailing;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          SectionEyebrow(label: eyebrow!, trailing: trailing),
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kCardBorder),
            boxShadow: const [BoxShadow(color: Color(0x0F1E3553), blurRadius: 16, offset: Offset(0, 5))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i != rows.length - 1) const Divider(height: 1, thickness: 1, color: _kDivider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Une ligne de champ texte simple à l'intérieur d'une [FormSection]
/// (titre, lieu, description...). Pas de fond ni d'ombre propres — la
/// carte qui l'entoure s'en charge.
class FieldRow extends StatelessWidget {
  const FieldRow({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.trailingIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AtlartType.fieldLabel),
                const SizedBox(height: 3),
                TextField(
                  controller: controller,
                  minLines: minLines,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  style: AtlartType.fieldValue.copyWith(fontWeight: maxLines > 1 ? FontWeight.w400 : FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: AtlartType.fieldHint,
                  ),
                ),
              ],
            ),
          ),
          if (trailingIcon != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 14),
              child: Icon(trailingIcon, size: 16, color: AtlartPalette.blueTextLight),
            ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? d) {
  if (d == null) return 'Choisir une date';
  const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

Future<DateTime?> _pickDate(BuildContext context, DateTime? current) {
  return showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
  );
}

class _DateCell extends StatelessWidget {
  const _DateCell({required this.label, required this.date, required this.onPick});
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await _pickDate(context, date);
        if (picked != null) onPick(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AtlartType.fieldLabel),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(date),
                  overflow: TextOverflow.ellipsis,
                  style: AtlartType.fieldValue.copyWith(
                    color: date == null ? AtlartPalette.blueTextLight : AtlartPalette.navy,
                    fontWeight: date == null ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.calendar_today_outlined, size: 13, color: AtlartPalette.blueTextLight),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ligne "Début / Fin" à l'intérieur d'une [FormSection] (exposition et
/// résidence), deux cellules de date séparées par un filet vertical.
class DateRangeRow extends StatelessWidget {
  const DateRangeRow({
    super.key,
    required this.start,
    required this.end,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateTime> onPickStart;
  final ValueChanged<DateTime> onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        children: [
          Expanded(child: _DateCell(label: 'DÉBUT', date: start, onPick: onPickStart)),
          Container(width: 1, height: 32, color: _kDivider, margin: const EdgeInsets.symmetric(horizontal: 14)),
          Expanded(child: _DateCell(label: 'FIN', date: end, onPick: onPickEnd)),
        ],
      ),
    );
  }
}

/// Ligne "Date / Horaire" (atelier) : une cellule de date, un champ
/// texte libre pour le créneau horaire.
class DateAndTimeRow extends StatelessWidget {
  const DateAndTimeRow({
    super.key,
    required this.date,
    required this.onPickDate,
    required this.timeController,
  });

  final DateTime? date;
  final ValueChanged<DateTime> onPickDate;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        children: [
          Expanded(child: _DateCell(label: 'DATE', date: date, onPick: onPickDate)),
          Container(width: 1, height: 32, color: _kDivider, margin: const EdgeInsets.symmetric(horizontal: 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HORAIRE', style: AtlartType.fieldLabel),
                const SizedBox(height: 3),
                TextField(
                  controller: timeController,
                  style: AtlartType.fieldValue.copyWith(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: '14h – 17h', hintStyle: AtlartType.fieldHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne Présentiel / Virtuel — un interrupteur compact, posé en ligne
/// plutôt qu'en gros bloc : la bascule reste lisible sans écraser les
/// champs voisins en importance.
class ModeToggleRow extends StatelessWidget {
  const ModeToggleRow({super.key, required this.value, required this.onChanged});
  final EventMode value;
  final ValueChanged<EventMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(EventMode m) {
      final selected = value == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AtlartPalette.navyDark : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              m.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AtlartPalette.blueTextLight, fontFamily: 'Poppins'),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          const Text('MODE', style: AtlartType.fieldLabel),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: _kEventFieldFill.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(999)),
              child: Row(children: [seg(EventMode.presentiel), seg(EventMode.virtuel)]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne "Capacité" : libellé, grand chiffre, +/- à droite — tout sur
/// une ligne, sans bloc séparé.
class CapacityRow extends StatelessWidget {
  const CapacityRow({super.key, required this.label, required this.value, required this.onChanged, this.min = 1, this.max = 999});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AtlartType.fieldLabel),
                const SizedBox(height: 3),
                Text('$value', style: const TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w700, fontSize: 19, color: AtlartPalette.navy)),
              ],
            ),
          ),
          _roundBtn(Icons.remove_rounded, value > min ? () => onChanged(value - 1) : null),
          const SizedBox(width: 8),
          _roundBtn(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AtlartPalette.navyDark : const Color(0xFFE1E9F2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 15, color: enabled ? Colors.white : AtlartPalette.blueTextLight)),
      ),
    );
  }
}

/// En-tête "Ajouter une couverture", conservé mais avec une bordure
/// teintée corail et une icône posée dans un cercle doux, pour qu'il ne
/// se confonde plus avec un simple champ texte vide.
class CoverUploadBox extends StatelessWidget {
  const CoverUploadBox({super.key, required this.imagePath, required this.onTap});
  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 108,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtlartPalette.coral.withValues(alpha: 0.35), width: 1.4),
        ),
        child: imagePath == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: const Color(0xFFFFE3E3), borderRadius: BorderRadius.circular(999)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined, size: 17, color: AtlartPalette.coral),
                  ),
                  const SizedBox(height: 8),
                  const Text('Ajouter une couverture', style: AtlartType.stepTitle),
                  const SizedBox(height: 2),
                  const Text('JPEG, PNG', style: TextStyle(fontSize: 9, color: AtlartPalette.blueTextLight, fontFamily: 'Poppins')),
                ],
              )
            : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
      ),
    );
  }
}

/// Pastille corail qui rappelle le type sélectionné, posée au-dessus de
/// la couverture.
class EventTypeBadge extends StatelessWidget {
  const EventTypeBadge({super.key, required this.type});
  final EventType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: AtlartPalette.coral, borderRadius: BorderRadius.circular(999)),
      child: Text(type.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
    );
  }
}

/// Sélecteur de type en onglets soulignés (Playfair + trait corail),
/// plutôt qu'en pilule pleine — même logique que les onglets de
/// l'espace admin et des sous-onglets de la zone navigation : une
/// sélection active se marque par un soulignement, pas par un bloc de
/// couleur qui alourdit la rangée.
class EventTypeTabs extends StatelessWidget {
  const EventTypeTabs({super.key, required this.value, required this.onChanged});
  final EventType value;
  final ValueChanged<EventType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final t in EventType.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: value == t ? AtlartPalette.coral : Colors.transparent, width: 2.5)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t.label,
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: value == t ? AtlartPalette.navy : AtlartPalette.blueTextLight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Section "Programme" / "Temps forts" / "Séances" : même traitement en
/// carte groupée que [FormSection], chaque créneau sur sa ligne avec un
/// filet entre eux.
class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key, required this.type, required this.items, required this.onRemove, required this.onAdd});
  final EventType type;
  final List<ScheduleItem> items;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final addLink = GestureDetector(
      onTap: onAdd,
      child: Text(type.addScheduleLabel, style: const TextStyle(color: AtlartPalette.coral, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
    );
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionEyebrow(label: type.scheduleTitle, trailing: addLink),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kCardBorder)),
            child: Text(
              switch (type) {
                EventType.residence => 'Ajoutez les jours clés de votre résidence.',
                EventType.atelier => 'Ajoutez les séances de votre atelier.',
                EventType.exposition => 'Ajoutez les moments clés de votre événement.',
              },
              style: const TextStyle(fontSize: 11.5, color: AtlartPalette.blueTextLight, fontFamily: 'Poppins'),
            ),
          ),
        ],
      );
    }
    return FormSection(
      eyebrow: type.scheduleTitle,
      trailing: addLink,
      rows: [
        for (var i = 0; i < items.length; i++) _ScheduleRow(item: items[i], onRemove: () => onRemove(i)),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item, required this.onRemove});
  final ScheduleItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 10, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFD4F0E2), borderRadius: BorderRadius.circular(6)),
            child: Text(item.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1F7A4F), fontFamily: 'Poppins')),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AtlartPalette.navy, fontFamily: 'Poppins')),
                if (item.subtitle.isNotEmpty)
                  Text(item.subtitle, style: const TextStyle(fontSize: 10.5, color: AtlartPalette.blueTextLight, fontFamily: 'Poppins')),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onRemove,
            child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 15, color: AtlartPalette.blueTextLight)),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'info avec un repère corail à gauche plutôt qu'un simple
/// bloc bleu plein — même logique d'accent que [SectionEyebrow], pour
/// que le rappel réglementaire se lise comme une note éditoriale et non
/// comme une alerte système.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Icons.shield_outlined});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _kEventFieldFill.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: AtlartPalette.coral, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AtlartPalette.blueText),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 10.5, height: 1.5, color: AtlartPalette.navy, fontFamily: 'Poppins'))),
        ],
      ),
    );
  }
}

/// Bottom sheet d'ajout d'un créneau (titre + description).
Future<ScheduleItem?> showAddScheduleSheet(BuildContext context, {required String code}) {
  final titleCtrl = TextEditingController();
  final subtitleCtrl = TextEditingController();
  return showModalBottomSheet<ScheduleItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: _kDivider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Ajouter un créneau · $code', style: AtlartType.stepTitle),
            const SizedBox(height: 14),
            _SheetField(label: 'Titre', controller: titleCtrl, hint: 'Ex. Vernissage'),
            const Divider(height: 1, color: _kDivider),
            _SheetField(label: 'Description', controller: subtitleCtrl, hint: 'Ex. Accueil des artistes, 18h'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AtlartPalette.coral,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(ScheduleItem(code: code, title: titleCtrl.text.trim(), subtitle: subtitleCtrl.text.trim()));
                },
                child: const Text('Ajouter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.label, required this.controller, required this.hint});
  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AtlartType.fieldLabel),
          const SizedBox(height: 3),
          TextField(
            controller: controller,
            style: AtlartType.fieldValue,
            decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: hint, hintStyle: AtlartType.fieldHint),
          ),
        ],
      ),
    );
  }
}
