import 'package:flutter/material.dart';

import '../models/messaging.dart';
import '../widgets/event_ui.dart' show EventPageHeader, EventColors;
import '../widgets/messaging_ui.dart';
import '../widgets/offers_ui.dart'
    show
        OfferColors,
        OfferNote,
        OfferPrimaryButton,
        OfferSectionLabel,
        OfferText;
import 'conversation_screen.dart';

/// Point d'entrée unique pour « Contacter / Écrire / Envoyer un message ».
///
/// - conversation déjà existante pour (personne, élément) → on l'ouvre ;
/// - sinon → formulaire de première demande (soumise à vérification).
Future<void> openContact(
  BuildContext context, {
  required ChatParticipant recipient,
  required ChatContext about,
}) {
  final existing = MessageStore.instance.find(recipient.id, about.id);
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => existing != null
          ? ConversationScreen(threadId: existing.id)
          : NewMessageScreen(participant: recipient, about: about),
    ),
  );
}

/// Premier message (Airbnb : « Contacter l'hôte »). Après l'envoi, la demande
/// passe en vérification par l'équipe Atlart.
class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({
    super.key,
    required this.participant,
    required this.about,
    this.initialText,
    this.resendThreadId,
  });

  final ChatParticipant participant;
  final ChatContext about;
  final String? initialText;

  /// Renseigné quand on corrige un message refusé par la modération.
  final String? resendThreadId;

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  static const _min = 20;
  static const _max = 500;

  final _store = MessageStore.instance;
  late final _text = TextEditingController(text: widget.initialText ?? '');
  bool _busy = false;
  bool _submitted = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String get _value => _text.text.trim();

  String? get _error {
    if (_value.length < _min) {
      return 'Écrivez au moins $_min caractères pour que '
          '${widget.participant.name} comprenne votre demande.';
    }
    return MessageGuard.check(_value);
  }

  /// L'avertissement coordonnées s'affiche en direct, le reste après l'envoi.
  String? get _liveWarning => MessageGuard.check(_value);

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (_error != null) return;

    setState(() => _busy = true);
    try {
      final String threadId;
      final resendId = widget.resendThreadId;
      if (resendId != null) {
        await _store.resend(resendId, _value);
        threadId = resendId;
      } else {
        final thread = await _store.startThread(
          participant: widget.participant,
          about: widget.about,
          text: _value,
        );
        threadId = thread.id;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConversationScreen(threadId: threadId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(
        e is StateError
            ? e.message
            : 'Impossible d’envoyer la demande. Réessayez dans un instant.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.participant.name;
    final shownError = _submitted ? _error : _liveWarning;
    final hasError = shownError != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          EventPageHeader(
            title: widget.resendThreadId != null
                ? 'Modifier le message'
                : 'Nouveau message',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChatContextCard(about: widget.about),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      ChatAvatar(name: name, radius: 17),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'À : $name',
                              style: OfferText.poppins(
                                11.5,
                                weight: FontWeight.w700,
                              ),
                            ),
                            if (widget.participant.subtitle.isNotEmpty)
                              Text(
                                widget.participant.subtitle,
                                style: OfferText.poppins(
                                  9,
                                  color: OfferColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const OfferSectionLabel('Votre message'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasError && (_submitted || _liveWarning != null)
                            ? OfferColors.error.withValues(alpha: 0.75)
                            : EventColors.line,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _text,
                          onChanged: (_) => setState(() {}),
                          minLines: 5,
                          maxLines: 9,
                          maxLength: _max,
                          textCapitalization: TextCapitalization.sentences,
                          cursorColor: OfferColors.navy,
                          style: OfferText.poppins(12),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            counterText: '',
                            hintText:
                                'Bonjour $name, je suis intéressé(e) par '
                                '« ${widget.about.title} »…',
                            hintStyle: OfferText.poppins(
                              11.5,
                              weight: FontWeight.w400,
                              color: OfferColors.muted,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_text.text.length}/$_max',
                            style: OfferText.poppins(
                              8.5,
                              color: OfferColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 6),
                    Text(
                      shownError,
                      style: OfferText.poppins(
                        9.5,
                        color: OfferColors.error,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Questions rapides',
                    style: OfferText.poppins(9.5, color: OfferColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in widget.about.suggestions)
                        ActionChip(
                          label: Text(
                            s,
                            style: OfferText.poppins(
                              9.5,
                              color: OfferColors.steel,
                            ),
                          ),
                          backgroundColor: const Color(0xFFEAF2FB),
                          side: BorderSide.none,
                          onPressed: () {
                            _text.text = s;
                            _text.selection = TextSelection.collapsed(
                              offset: s.length,
                            );
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OfferNote(
                    text:
                        'Pour votre sécurité, l’équipe Atlart vérifie chaque '
                        'premier message avant de le transmettre. Ne partagez '
                        'ni téléphone, ni e-mail, ni lien : vous pourrez '
                        'échanger librement dès que $name aura répondu.',
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
                label: widget.resendThreadId != null
                    ? 'Renvoyer pour vérification'
                    : 'Envoyer la demande',
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
