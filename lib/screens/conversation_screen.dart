import 'package:flutter/material.dart';

import '../models/messaging.dart';
import '../theme/atlart_ui_theme.dart' show AtlartAssets;
import '../widgets/messaging_ui.dart';
import '../widgets/offers_ui.dart' show OfferColors, OfferText;
import 'new_message_screen.dart';

/// Conversation (Airbnb : carte de l'élément épinglée, bandeau d'état de la
/// demande, bulles, messages système de l'équipe Atlart, zone de saisie
/// verrouillée tant que la conversation n'est pas ouverte).
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.threadId});

  final String threadId;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _store = MessageStore.instance;
  final _input = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;
  String? _warning;

  @override
  void initState() {
    super.initState();
    _store.markRead(widget.threadId);
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Un message reçu pendant que l'écran est ouvert est lu tout de suite.
  void _onStoreChanged() => _store.markRead(widget.threadId);

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send(ChatThread thread, [String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    // Avant l'ouverture, les coordonnées sont interdites (comme Airbnb).
    if (thread.status != ThreadStatus.open) {
      final reason = MessageGuard.check(text);
      if (reason != null) {
        setState(() => _warning = reason);
        return;
      }
    }

    setState(() {
      _sending = true;
      _warning = null;
    });
    try {
      await _store.send(thread.id, text);
      _input.clear();
    } catch (_) {
      if (mounted) _toast('Impossible d’envoyer le message. Réessayez.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openMenu(ChatThread thread) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Signaler la conversation'),
              subtitle: const Text('Un modérateur Atlart examinera l’échange.'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                // TODO : POST /conversations/{id}/report
                _toast('Merci, votre signalement a été transmis.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: Text('Bloquer ${thread.participant.name}'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                // TODO : brancher sur « Comptes bloqués ».
                _toast('${thread.participant.name} a été bloqué(e).');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final thread = _store.byId(widget.threadId);
        if (thread == null) {
          return const Scaffold(
            body: Center(child: Text('Conversation introuvable.')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              _Header(thread: thread, onMenu: () => _openMenu(thread)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ChatContextCard(about: thread.about),
              ),
              _StatusBanner(
                thread: thread,
                onEdit: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NewMessageScreen(
                      participant: thread.participant,
                      about: thread.about,
                      resendThreadId: thread.id,
                      initialText: thread.messages
                          .where((m) => m.fromMe && !m.system)
                          .map((m) => m.text)
                          .firstOrNull,
                    ),
                  ),
                ),
              ),
              Expanded(child: _Messages(thread: thread)),
              _Composer(
                thread: thread,
                controller: _input,
                focusNode: _focus,
                sending: _sending,
                warning: _warning,
                onChanged: (_) {
                  if (_warning != null) setState(() => _warning = null);
                  setState(() {});
                },
                onSend: () => _send(thread),
                onQuick: (text) => _send(thread, text),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── En-tête ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.thread, required this.onMenu});

  final ChatThread thread;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final p = thread.participant;

    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 4, 8, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DB6E1), Color(0xFFC3DAF2), Colors.white],
          stops: [0.0, 0.65, 1.0],
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Image.asset(
              AtlartAssets.logoHorizontal,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  'ATLART',
                  style: OfferText.poppins(
                    13,
                    weight: FontWeight.w700,
                    color: OfferColors.steel,
                    spacing: 3,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Retour',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              ChatAvatar(name: p.name, radius: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OfferText.poppins(
                              13,
                              weight: FontWeight.w700,
                              color: OfferColors.navy,
                            ),
                          ),
                        ),
                        if (p.verified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 13,
                            color: Color(0xFF36B77A),
                          ),
                        ],
                      ],
                    ),
                    if (p.subtitle.isNotEmpty)
                      Text(
                        p.subtitle,
                        style: OfferText.poppins(9, color: OfferColors.steel),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Plus d’options',
                onPressed: onMenu,
                icon: const Icon(
                  Icons.more_horiz,
                  color: OfferColors.navy,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Bandeau d'état ─────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.thread, required this.onEdit});

  final ChatThread thread;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = thread.participant.name;

    final (IconData icon, String title, String body, Color bg, Color fg)? spec =
        switch (thread.status) {
          ThreadStatus.inReview => (
            Icons.shield_outlined,
            'Vérification en cours',
            'Notre équipe relit chaque premier message avant de le transmettre '
                'à $name. C’est généralement rapide.',
            OfferColors.cream,
            OfferColors.brown,
          ),
          ThreadStatus.delivered when !thread.incoming => (
            Icons.mark_email_read_outlined,
            'Message transmis',
            'Vous pourrez continuer la discussion dès que $name aura répondu.',
            const Color(0xFFDCEBFA),
            const Color(0xFF3F5F8F),
          ),
          ThreadStatus.delivered => (
            Icons.mail_outline_rounded,
            'Nouvelle demande de $name',
            'Répondez pour ouvrir la conversation.',
            const Color(0xFFDCEBFA),
            const Color(0xFF3F5F8F),
          ),
          ThreadStatus.rejected => (
            Icons.report_gmailerrorred_outlined,
            'Message non approuvé',
            thread.rejectionReason ??
                'Votre message ne respecte pas les règles de la messagerie.',
            const Color(0xFFFFE3E3),
            OfferColors.error,
          ),
          ThreadStatus.open => null,
        };
    if (spec == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: spec.$4,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(spec.$1, size: 18, color: spec.$5),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.$2,
                  style: OfferText.poppins(
                    10.5,
                    weight: FontWeight.w700,
                    color: spec.$5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  spec.$3,
                  style: OfferText.poppins(9.5, color: spec.$5, height: 1.5),
                ),
                if (thread.status == ThreadStatus.rejected) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onEdit,
                    child: Text(
                      'Modifier et renvoyer',
                      style: OfferText.poppins(
                        10,
                        weight: FontWeight.w700,
                        color: spec.$5,
                      ).copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Messages ─────────────────────────

class _Messages extends StatelessWidget {
  const _Messages({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final messages = thread.messages;
    if (messages.isEmpty) return const SizedBox.shrink();

    // Liste inversée : le bas de la conversation reste visible avec le clavier.
    final reversed = messages.reversed.toList();

    return ListView.builder(
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: reversed.length,
      itemBuilder: (context, i) {
        final m = reversed[i];
        final older = i + 1 < reversed.length ? reversed[i + 1] : null;
        final newDay =
            older == null ||
            older.at.year != m.at.year ||
            older.at.month != m.at.month ||
            older.at.day != m.at.day;

        return Column(
          children: [
            if (newDay) _DayDivider(label: chatDayLabel(m.at)),
            m.system ? _SystemMessage(text: m.text) : _Bubble(message: m),
          ],
        );
      },
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(label, style: OfferText.poppins(9, color: OfferColors.muted)),
  );
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 13,
              color: OfferColors.steel,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: OfferText.poppins(
                  9,
                  color: OfferColors.steel,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFF6B84AB) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            boxShadow: mine
                ? null
                : const [
                    BoxShadow(
                      color: OfferColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
            border: mine ? null : Border.all(color: const Color(0xFFE3ECF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: OfferText.poppins(
                    11,
                    height: 1.5,
                    color: mine ? Colors.white : OfferColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                chatClock(message.at),
                style: OfferText.poppins(
                  7.5,
                  color: mine ? Colors.white70 : OfferColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Zone de saisie ─────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({
    required this.thread,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.warning,
    required this.onChanged,
    required this.onSend,
    required this.onQuick,
  });

  final ChatThread thread;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final String? warning;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final ValueChanged<String> onQuick;

  static const _quickReplies = [
    'Oui, c’est toujours disponible.',
    'Je reviens vers vous rapidement.',
    'Merci pour votre message !',
  ];

  @override
  Widget build(BuildContext context) {
    final canSend = thread.canSend;
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3ECF5))),
      ),
      child: SafeArea(
        top: false,
        child: !canSend
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: OfferColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        thread.status == ThreadStatus.rejected
                            ? 'Modifiez votre message pour le renvoyer.'
                            : 'La discussion s’ouvrira dès la réponse de '
                                  '${thread.participant.name}.',
                        textAlign: TextAlign.center,
                        style: OfferText.poppins(9.5, color: OfferColors.muted),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (thread.incoming && thread.status != ThreadStatus.open)
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        children: [
                          for (final q in _quickReplies)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  q,
                                  style: OfferText.poppins(
                                    9.5,
                                    color: OfferColors.steel,
                                  ),
                                ),
                                backgroundColor: const Color(0xFFEAF2FB),
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                                onPressed: () => onQuick(q),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (warning != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE3E3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        warning!,
                        style: OfferText.poppins(
                          9.5,
                          color: OfferColors.error,
                          height: 1.45,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F6FC),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFE3ECF5),
                              ),
                            ),
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: onChanged,
                              minLines: 1,
                              maxLines: 5,
                              maxLength: 1000,
                              textCapitalization: TextCapitalization.sentences,
                              cursorColor: OfferColors.navy,
                              style: OfferText.poppins(11.5),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                hintText: 'Écrire un message…',
                                hintStyle: OfferText.poppins(
                                  11.5,
                                  color: OfferColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Envoyer',
                          child: Material(
                            color: hasText && !sending
                                ? OfferColors.coral
                                : const Color(0xFFFFB9B9),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: hasText && !sending ? onSend : null,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: sending
                                    ? const Padding(
                                        padding: EdgeInsets.all(13),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
