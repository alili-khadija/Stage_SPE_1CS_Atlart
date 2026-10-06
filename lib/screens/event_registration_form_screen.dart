import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_session.dart';
import '../models/event_detail.dart';
import '../models/event_registration.dart';
import '../widgets/event_ui.dart';
import '../widgets/offers_ui.dart'
    show
        OfferColors,
        OfferNote,
        OfferPrimaryButton,
        OfferSectionLabel,
        OfferText;
import 'registration_sent_screen.dart';

class EventRegistrationFormScreen extends StatefulWidget {
  const EventRegistrationFormScreen({
    super.key,
    required this.event,
    this.onViewRegistrations,
  });

  final EventDetail event;
  final VoidCallback? onViewRegistrations;

  @override
  State<EventRegistrationFormScreen> createState() =>
      _EventRegistrationFormScreenState();
}

class _EventRegistrationFormScreenState
    extends State<EventRegistrationFormScreen> {
  final _store = EventRegistrationStore.instance;
  late final _name = TextEditingController(
    text: AtlartSession.firstName.trim(),
  );
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _message = TextEditingController();

  int _participants = 1;
  bool _consent = false;
  bool _busy = false;
  bool _submitted = false;

  EventDetail get _event => widget.event;

  int get _maxParticipants {
    final places = _event.placesLeft;
    if (places == null || places > 10) return 10;
    return places < 1 ? 1 : places;
  }

  String? get _nameError =>
      _name.text.trim().length < 2 ? 'Saisissez votre nom complet.' : null;
  String? get _emailError =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())
      ? null
      : 'Saisissez une adresse e-mail valide.';
  String? get _phoneError =>
      _phone.text.replaceAll(RegExp(r'\D'), '').length >= 8
      ? null
      : 'Saisissez un numéro de téléphone valide.';
  String? get _messageError =>
      _event.requiresValidation && _message.text.trim().length < 10
      ? 'Ajoutez au moins 10 caractères pour motiver votre demande.'
      : null;
  String? get _consentError =>
      _consent ? null : 'Votre accord est nécessaire pour continuer.';

  bool get _isValid =>
      _nameError == null &&
      _emailError == null &&
      _phoneError == null &&
      _messageError == null &&
      _consentError == null;

  String? _errorToShow(String? error) => _submitted ? error : null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    _message.dispose();
    super.dispose();
  }

  void _refresh([String _ = '']) {
    if (_submitted) setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!_isValid) {
      _showMessage('Vérifiez les champs signalés avant de continuer.');
      return;
    }

    setState(() => _busy = true);
    try {
      final registration = await _store.register(
        _event,
        form: EventRegistrationForm(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          city: _city.text.trim(),
          participants: _participants,
          message: _message.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RegistrationSentPage(
            registration: registration,
            onViewRegistrations: widget.onViewRegistrations,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage('Impossible d’envoyer la demande : $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizer = _event.organizer?.name ?? 'L’organisateur';
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          EventPageHeader(
            title: 'Inscription',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EventSummary(event: _event),
                  const SizedBox(height: 22),
                  const OfferSectionLabel('Vos coordonnées'),
                  const SizedBox(height: 10),
                  _RegistrationField(
                    label: 'Nom complet',
                    controller: _name,
                    hint: 'Ex. Yasmine Bouzidi',
                    errorText: _errorToShow(_nameError),
                    capitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    onChanged: _refresh,
                  ),
                  const SizedBox(height: 10),
                  _RegistrationField(
                    label: 'E-mail',
                    controller: _email,
                    hint: 'vous@exemple.com',
                    errorText: _errorToShow(_emailError),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onChanged: _refresh,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _RegistrationField(
                          label: 'Téléphone',
                          controller: _phone,
                          hint: '+216 00 000 000',
                          errorText: _errorToShow(_phoneError),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\s()\-]'),
                            ),
                          ],
                          autofillHints: const [AutofillHints.telephoneNumber],
                          onChanged: _refresh,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: _RegistrationField(
                          label: 'Ville (facultatif)',
                          controller: _city,
                          hint: 'Tunis',
                          capitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const OfferSectionLabel('Participation'),
                  const SizedBox(height: 10),
                  _ParticipantStepper(
                    value: _participants,
                    max: _maxParticipants,
                    onChanged: (value) => setState(() => _participants = value),
                  ),
                  const SizedBox(height: 22),
                  OfferSectionLabel(
                    _event.requiresValidation
                        ? 'Message à l’organisateur'
                        : 'Message (facultatif)',
                  ),
                  const SizedBox(height: 10),
                  _RegistrationField(
                    label: _event.requiresValidation
                        ? 'Pourquoi souhaitez-vous participer ?'
                        : 'Un mot pour l’organisateur',
                    controller: _message,
                    hint: 'Votre parcours, vos attentes, vos besoins particuliers…',
                    errorText: _errorToShow(_messageError),
                    minLines: 4,
                    capitalization: TextCapitalization.sentences,
                    onChanged: _refresh,
                  ),
                  const SizedBox(height: 16),
                  OfferNote(
                    text: _event.requiresValidation
                        ? '$organizer examinera votre demande. Vous serez '
                              'informé(e) de sa réponse.'
                        : 'Votre place sera confirmée après l’envoi du formulaire.',
                  ),
                  const SizedBox(height: 16),
                  _ConsentCheckbox(
                    checked: _consent,
                    errorText: _errorToShow(_consentError),
                    onToggle: () => setState(() => _consent = !_consent),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: EventColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: OfferPrimaryButton(
                label: _event.requiresValidation
                    ? 'Envoyer ma demande'
                    : 'Confirmer mon inscription',
                busy: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventSummary extends StatelessWidget {
  const _EventSummary({required this.event});

  final EventDetail event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EventColors.line),
        boxShadow: const [
          BoxShadow(
            color: OfferColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: EventHeroImage(event: event),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OfferText.poppins(
                    10.5,
                    weight: FontWeight.w700,
                    color: OfferColors.navy,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    event.dateLabel,
                    event.location,
                  ].where((value) => value.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OfferText.poppins(8.5, color: OfferColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({
    required this.label,
    required this.controller,
    required this.hint,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.minLines = 1,
    this.capitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    final multiline = minLines > 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: errorText == null
              ? EventColors.line
              : OfferColors.error.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: OfferText.poppins(9, color: OfferColors.muted)),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: minLines,
            maxLines: multiline ? null : 1,
            keyboardType:
                keyboardType ??
                (multiline ? TextInputType.multiline : TextInputType.text),
            textCapitalization: capitalization,
            inputFormatters: inputFormatters,
            autofillHints: autofillHints,
            style: OfferText.poppins(10.5, color: OfferColors.ink),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: OfferText.poppins(10, color: OfferColors.muted),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 3),
            Text(
              errorText!,
              style: OfferText.poppins(9, color: OfferColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParticipantStepper extends StatelessWidget {
  const _ParticipantStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: EventColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre de participants',
                  style: OfferText.poppins(9, color: OfferColors.muted),
                ),
                Text(
                  value == max && max > 1 ? 'Maximum atteint' : 'Vous compris',
                  style: OfferText.poppins(8.5, color: OfferColors.olive),
                ),
              ],
            ),
          ),
          _StepButton(
            icon: Icons.remove,
            enabled: value > 1,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: OfferText.serif(18),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? OfferColors.steel : const Color(0xFFD5E0EE),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({
    required this.checked,
    required this.errorText,
    required this.onToggle,
  });

  final bool checked;
  final String? errorText;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          checked: checked,
          label: 'Accepter le partage de mes coordonnées',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: checked
                        ? const Color(0xFF4A7FAF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: errorText != null
                          ? OfferColors.error
                          : OfferColors.navy,
                      width: 1.6,
                    ),
                  ),
                  child: checked
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'J’accepte que mes coordonnées soient transmises à '
                    'l’organisateur pour la gestion de l’événement.',
                    style: OfferText.poppins(9.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 28),
            child: Text(
              errorText!,
              style: OfferText.poppins(9, color: OfferColors.error),
            ),
          ),
      ],
    );
  }
}
