import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_ui_widgets.dart';
import 'event_draft.dart';
import 'event_form_widgets.dart';
import 'event_submitted_screen.dart';

/// Formulaire de création d'un événement. Les champs affichés changent
/// selon [EventType] :
/// - Exposition / Résidence : deux dates (Début / Fin).
/// - Atelier : une date + un horaire.
///
/// MODIF (reprise visuelle) : les champs ne sont plus chacun dans leur
/// propre carte à ombre — ils sont regroupés par thème ("Quand & où",
/// "Capacité & description"...) dans une seule carte avec un filet
/// entre les lignes. C'est ce qui donnait l'effet "chargé" signalé sur
/// la première version ; le fond reprend aussi le dégradé ciel→blanc de
/// l'écran de connexion au lieu d'un bleu plat sans rapport avec le
/// reste du parcours. Le bug d'overflow de 4px venait de l'en-tête en
/// `appBar:` à hauteur fixe — il est maintenant un simple widget qui
/// suit son contenu (voir [EventFormHeader] dans event_form_widgets.dart).
class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key, this.initialDraft});

  final EventDraft? initialDraft;

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  late EventDraft _draft = widget.initialDraft ?? EventDraft();
  late final _titleCtrl = TextEditingController(text: _draft.title);
  late final _timeCtrl = TextEditingController(text: _draft.timeRange);
  late final _locationCtrl = TextEditingController(text: _draft.location);
  late final _descriptionCtrl = TextEditingController(text: _draft.description);

  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _changeType(EventType type) {
    setState(() {
      _draft.type = type;
      // Une capacité de 60 n'a pas de sens pour un atelier de 12
      // personnes ni l'inverse : on repart sur une valeur par défaut
      // raisonnable à chaque changement de type plutôt que de garder un
      // nombre qui n'aurait plus de rapport avec le nouveau contexte.
      _draft.capacity = switch (type) {
        EventType.exposition => 60,
        EventType.atelier => 12,
        EventType.residence => 20,
      };
    });
  }

  Future<void> _addScheduleItem() async {
    final item = await showAddScheduleSheet(context, code: _draft.nextScheduleCode);
    if (item != null) setState(() => _draft.schedule.add(item));
  }

  String? _validate() {
    if (_titleCtrl.text.trim().isEmpty) return 'Donnez un titre à votre événement.';
    if (_draft.startDate == null) {
      return _draft.type.usesSingleDateAndTime ? 'Choisissez une date.' : 'Choisissez une date de début.';
    }
    if (!_draft.type.usesSingleDateAndTime) {
      if (_draft.endDate == null) return 'Choisissez une date de fin.';
      if (_draft.endDate!.isBefore(_draft.startDate!)) {
        return 'La date de fin doit être après la date de début.';
      }
    }
    if (_locationCtrl.text.trim().isEmpty) return 'Indiquez un lieu.';
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _submitting = true);
    _draft
      ..title = _titleCtrl.text.trim()
      ..timeRange = _timeCtrl.text.trim()
      ..location = _locationCtrl.text.trim()
      ..description = _descriptionCtrl.text.trim();

    // TODO: remplacer par le vrai appel API de création d'événement.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => EventSubmittedScreen(draft: _draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = _draft.type;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EventPageBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const EventFormHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  children: [
                    Align(alignment: Alignment.centerLeft, child: EventTypeBadge(type: type)),
                    const SizedBox(height: 12),
                    CoverUploadBox(
                      imagePath: _draft.imagePath,
                      onTap: () {
                        // TODO: brancher image_picker, comme dans add_article_screen.dart.
                      },
                    ),
                    const SizedBox(height: 14),
                    EventTypeTabs(value: type, onChanged: _changeType),
                    const SizedBox(height: 22),

                    // ---- Groupe "Quand & où" : titre, dates, mode, lieu ----
                    FormSection(
                      eyebrow: 'Quand & où',
                      rows: [
                        FieldRow(label: 'Titre de l\'événement', controller: _titleCtrl, hint: 'Ex. Regards sur la Médina'),
                        if (type.usesSingleDateAndTime)
                          DateAndTimeRow(
                            date: _draft.startDate,
                            onPickDate: (d) => setState(() => _draft.startDate = d),
                            timeController: _timeCtrl,
                          )
                        else
                          DateRangeRow(
                            start: _draft.startDate,
                            end: _draft.endDate,
                            onPickStart: (d) => setState(() => _draft.startDate = d),
                            onPickEnd: (d) => setState(() => _draft.endDate = d),
                          ),
                        ModeToggleRow(value: _draft.mode, onChanged: (m) => setState(() => _draft.mode = m)),
                        FieldRow(label: 'Lieu', controller: _locationCtrl, hint: 'Ville, adresse ou lien', trailingIcon: Icons.location_on_outlined),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ---- Groupe "Capacité & description" ----
                    FormSection(
                      eyebrow: 'Capacité & description',
                      rows: [
                        CapacityRow(label: type.capacityLabel, value: _draft.capacity, onChanged: (v) => setState(() => _draft.capacity = v)),
                        FieldRow(
                          label: 'Description',
                          controller: _descriptionCtrl,
                          hint: 'Décrivez votre événement…',
                          minLines: 2,
                          maxLines: 5,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ---- Programme / Temps forts / Séances ----
                    ScheduleSection(
                      type: type,
                      items: _draft.schedule,
                      onRemove: (i) => setState(() => _draft.schedule.removeAt(i)),
                      onAdd: _addScheduleItem,
                    ),
                    const SizedBox(height: 18),
                    const InfoBanner(
                      text: 'Un modérateur valide l\'événement sous 24h. Chaque '
                          'inscription reste soumise à votre validation.',
                    ),
                  ],
                ),
              ),

              // Barre basse détachée du fond (fine bordure + ombre), pour que
              // le bouton ne "flotte" plus au milieu du dégradé.
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEDF2F9))),
                ),
                child: AtlartButton(
                  label: _submitting ? 'Envoi…' : 'Soumettre l\'événement',
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}