import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

// ─────────────────────────────────────────────────────────────────────────
//  Messagerie Atlart — même principe que « Contacter l'hôte » sur Airbnb :
//
//   1. Le 1er message est une DEMANDE rattachée à un élément (œuvre,
//      article, événement, profil).
//   2. L'équipe Atlart (modération) la vérifie avant de la transmettre
//      → « En vérification ».
//   3. Une fois approuvée, elle est « Transmise » : l'expéditeur attend
//      la réponse (il ne peut pas relancer).
//   4. Dès que le destinataire répond, la conversation est « Ouverte ».
//   Un message refusé par la modération peut être corrigé et renvoyé.
//
//  Avant l'ouverture, les coordonnées (téléphone, e-mail, liens, réseaux)
//  sont interdites — comme sur Airbnb avant la réservation.
// ─────────────────────────────────────────────────────────────────────────

enum ChatContextKind { work, product, event, artist, general }

/// L'élément dont on parle (carte épinglée en haut de la conversation).
class ChatContext {
  const ChatContext({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.imageAsset,
    this.thumbColor = const Color(0xFF258F81),
  });

  final String id;
  final ChatContextKind kind;
  final String title;
  final String subtitle;
  final String? imageAsset;
  final Color thumbColor;

  String get kindLabel => switch (kind) {
    ChatContextKind.work => 'Œuvre',
    ChatContextKind.product => 'Article',
    ChatContextKind.event => 'Événement',
    ChatContextKind.artist => 'Profil',
    ChatContextKind.general => 'Discussion',
  };

  /// Questions rapides proposées dans le premier message.
  List<String> get suggestions => switch (kind) {
    ChatContextKind.work => const [
      'Cette œuvre est-elle toujours disponible ?',
      'Pouvez-vous m’en dire plus sur la technique ?',
      'Acceptez-vous de livrer ?',
    ],
    ChatContextKind.product => const [
      'Cet article est-il toujours en stock ?',
      'Quels sont les délais de préparation ?',
      'Faites-vous des commandes sur mesure ?',
    ],
    ChatContextKind.event => const [
      'Reste-t-il des places disponibles ?',
      'Le matériel est-il fourni ?',
      'Y a-t-il un tarif pour les groupes ?',
    ],
    _ => const [
      'Bonjour, j’aimerais échanger avec vous.',
      'Proposez-vous des collaborations ?',
    ],
  };
}

class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.name,
    this.role = '',
    this.location = '',
    this.verified = false,
  });

  final String id;
  final String name;
  final String role; // « Artisan », « Artiste », « Organisateur »
  final String location;
  final bool verified;

  String get subtitle =>
      [role, location].where((s) => s.isNotEmpty).join(' · ');
}

enum ThreadStatus { inReview, delivered, open, rejected }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.at,
    this.fromMe = true,
    this.system = false,
  });

  final String id;
  final String text;
  final DateTime at;
  final bool fromMe;

  /// Message de l'équipe Atlart (pastille centrée).
  final bool system;
}

class ChatThread {
  ChatThread({
    required this.id,
    required this.participant,
    required this.about,
    required this.status,
    required this.messages,
    this.incoming = false,
    this.rejectionReason,
    this.unread = 0,
  });

  final String id;
  final ChatParticipant participant;
  final ChatContext about;
  ThreadStatus status;
  final List<ChatMessage> messages;

  /// true : la demande vient de l'autre personne (je suis le destinataire).
  final bool incoming;
  String? rejectionReason;
  int unread;

  ChatMessage? get last => messages.isEmpty ? null : messages.last;

  DateTime get updatedAt => last?.at ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Le destinataire peut toujours répondre ; l'expéditeur seulement
  /// quand la conversation est ouverte.
  bool get canSend => incoming || status == ThreadStatus.open;

  /// Demande pas encore devenue une vraie conversation.
  bool get isRequest => status != ThreadStatus.open;
}

/// Filtre de modération côté application (la vraie modération est côté admin).
class MessageGuard {
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
  static final _url = RegExp(r'(https?://|www\.)\S+', caseSensitive: false);
  static final _phone = RegExp(r'(?:\+?\d[\s().-]*){8,}');
  static final _social = RegExp(
    r'\b(whats\s?app|telegram|instagram|insta|snap(?:chat)?|viber|messenger)\b',
    caseSensitive: false,
  );

  /// null = OK, sinon la raison à afficher.
  static String? check(String text) {
    if (_email.hasMatch(text)) {
      return 'Les adresses e-mail ne peuvent pas être partagées avant que '
          'la conversation soit ouverte.';
    }
    if (_url.hasMatch(text)) {
      return 'Les liens ne sont pas autorisés dans un premier message.';
    }
    if (_phone.hasMatch(text)) {
      return 'Les numéros de téléphone ne peuvent pas être partagés avant '
          'que la conversation soit ouverte.';
    }
    if (_social.hasMatch(text)) {
      return 'Merci de ne pas rediriger vers d’autres messageries ou réseaux '
          'pour l’instant.';
    }
    return null;
  }
}

class MessageStore extends ChangeNotifier {
  MessageStore._() {
    _seedDemo();
  }

  static final MessageStore instance = MessageStore._();

  /// DÉMO : simule la modération (4 s) puis la réponse (9 s). Mettre `false`
  /// en production : l'API / le push appellent alors [approve], [reject] et
  /// [receiveReply].
  static bool simulateBackend = true;

  final List<ChatThread> _threads = [];
  int _seq = 100;

  /// Plus récents d'abord.
  List<ChatThread> get threads {
    final list = List<ChatThread>.of(_threads);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  int get unreadTotal => _threads.fold(0, (sum, t) => sum + t.unread);

  ChatThread? byId(String id) {
    for (final t in _threads) {
      if (t.id == id) return t;
    }
    return null;
  }

  ChatThread? find(String participantId, String contextId) {
    for (final t in _threads) {
      if (t.participant.id == participantId && t.about.id == contextId) {
        return t;
      }
    }
    return null;
  }

  String _nextId(String prefix) => '$prefix-${++_seq}';

  // ── Envoi ──

  /// Premier message : crée la demande « En vérification ».
  Future<ChatThread> startThread({
    required ChatParticipant participant,
    required ChatContext about,
    required String text,
  }) async {
    final existing = find(participant.id, about.id);
    if (existing != null) return existing;

    final reason = MessageGuard.check(text);
    if (reason != null) throw StateError(reason);

    // TODO : POST /conversations { participantId, contextId, text }
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final thread = ChatThread(
      id: _nextId('thr'),
      participant: participant,
      about: about,
      status: ThreadStatus.inReview,
      messages: [
        ChatMessage(id: _nextId('msg'), text: text, at: DateTime.now()),
      ],
    );
    _threads.add(thread);
    notifyListeners();
    if (simulateBackend) _simulate(thread.id);
    return thread;
  }

  /// Renvoie un message refusé par la modération (corrigé).
  Future<void> resend(String threadId, String text) async {
    final t = byId(threadId);
    if (t == null || t.status != ThreadStatus.rejected) return;
    final reason = MessageGuard.check(text);
    if (reason != null) throw StateError(reason);

    // TODO : PUT /conversations/{id}/first-message
    await Future<void>.delayed(const Duration(milliseconds: 400));

    t.messages
      ..removeWhere((m) => !m.system && m.fromMe)
      ..add(ChatMessage(id: _nextId('msg'), text: text, at: DateTime.now()));
    t.status = ThreadStatus.inReview;
    t.rejectionReason = null;
    notifyListeners();
    if (simulateBackend) _simulate(t.id);
  }

  /// Message dans une conversation ouverte (ou réponse du destinataire).
  Future<void> send(String threadId, String text) async {
    final t = byId(threadId);
    if (t == null || !t.canSend) {
      throw StateError('Conversation non ouverte');
    }

    // TODO : POST /conversations/{id}/messages
    t.messages.add(
      ChatMessage(id: _nextId('msg'), text: text, at: DateTime.now()),
    );
    if (t.incoming && t.status != ThreadStatus.open) {
      t.status = ThreadStatus.open;
      t.messages.add(
        _system('Conversation ouverte avec ${t.participant.name}.'),
      );
    }
    notifyListeners();
  }

  void markRead(String threadId) {
    final t = byId(threadId);
    if (t == null || t.unread == 0) return;
    t.unread = 0;
    notifyListeners();
  }

  // ── Côté serveur / admin (à brancher sur l'API) ──

  ChatMessage _system(String text) => ChatMessage(
    id: _nextId('sys'),
    text: text,
    at: DateTime.now(),
    system: true,
  );

  /// La modération approuve le premier message.
  void approve(String threadId) {
    final t = byId(threadId);
    if (t == null || t.status != ThreadStatus.inReview) return;
    t.status = ThreadStatus.delivered;
    t.messages.add(
      _system(
        'Message vérifié par l’équipe Atlart et transmis à '
        '${t.participant.name}.',
      ),
    );
    notifyListeners();
  }

  /// La modération refuse (raison affichée à l'expéditeur).
  void reject(String threadId, String reason) {
    final t = byId(threadId);
    if (t == null || t.status != ThreadStatus.inReview) return;
    t.status = ThreadStatus.rejected;
    t.rejectionReason = reason;
    notifyListeners();
  }

  /// Le destinataire répond : la conversation s'ouvre.
  void receiveReply(String threadId, String text) {
    final t = byId(threadId);
    if (t == null ||
        t.status == ThreadStatus.inReview ||
        t.status == ThreadStatus.rejected) {
      return;
    }
    t.messages.add(
      ChatMessage(
        id: _nextId('msg'),
        text: text,
        at: DateTime.now(),
        fromMe: false,
      ),
    );
    t.status = ThreadStatus.open;
    t.unread++;
    notifyListeners();
  }

  void _simulate(String threadId) {
    Timer(const Duration(seconds: 4), () => approve(threadId));
    Timer(const Duration(seconds: 9), () {
      final t = byId(threadId);
      receiveReply(
        threadId,
        'Bonjour ! Merci pour votre message. Oui, tout à fait, '
        'n’hésitez pas si vous avez d’autres questions.',
      );
      if (t != null) notifyListeners();
    });
  }

  // ── Données de démonstration ──

  void _seedDemo() {
    final now = DateTime.now();

    _threads.addAll([
      ChatThread(
        id: 'thr-1',
        participant: const ChatParticipant(
          id: 'yasmine-bouazizi',
          name: 'Yasmine Bouazizi',
          role: 'Artiste',
          location: 'Tunis',
          verified: true,
        ),
        about: const ChatContext(
          id: 'work-medina-fragments',
          kind: ChatContextKind.work,
          title: 'Médina, fragments',
          subtitle: 'À partir de 1 800 MAD',
        ),
        status: ThreadStatus.open,
        unread: 1,
        messages: [
          ChatMessage(
            id: 'm1',
            text: 'Bonjour, cette œuvre est-elle toujours disponible ?',
            at: now.subtract(const Duration(hours: 5)),
          ),
          ChatMessage(
            id: 'm2',
            text:
                'Message vérifié par l’équipe Atlart et transmis à '
                'Yasmine Bouazizi.',
            at: now.subtract(const Duration(hours: 4, minutes: 40)),
            system: true,
          ),
          ChatMessage(
            id: 'm3',
            text:
                'Bonjour ! Oui, elle est disponible. Je peux la préparer '
                'pour une livraison sous une semaine.',
            at: now.subtract(const Duration(hours: 2)),
            fromMe: false,
          ),
        ],
      ),
      ChatThread(
        id: 'thr-2',
        participant: const ChatParticipant(
          id: 'atelier-dorra',
          name: 'Atelier Dorra',
          role: 'Artisan',
          location: 'Tlemcen',
          verified: true,
        ),
        about: const ChatContext(
          id: 'product-theiere',
          kind: ChatContextKind.product,
          title: 'Théière en terre cuite',
          subtitle: '4 500 DZD',
          thumbColor: Color(0xFFC9784E),
        ),
        status: ThreadStatus.delivered,
        messages: [
          ChatMessage(
            id: 'm4',
            text: 'Bonjour, faites-vous des commandes sur mesure ?',
            at: now.subtract(const Duration(days: 1, hours: 3)),
          ),
          ChatMessage(
            id: 'm5',
            text:
                'Message vérifié par l’équipe Atlart et transmis à '
                'Atelier Dorra.',
            at: now.subtract(const Duration(days: 1, hours: 2)),
            system: true,
          ),
        ],
      ),
      ChatThread(
        id: 'thr-3',
        participant: const ChatParticipant(
          id: 'karim-t',
          name: 'Karim T.',
          role: 'Membre',
          location: 'Alger',
        ),
        about: const ChatContext(
          id: 'artist-me',
          kind: ChatContextKind.artist,
          title: 'Votre profil',
          thumbColor: Color(0xFF5975A2),
        ),
        status: ThreadStatus.delivered,
        incoming: true,
        unread: 1,
        messages: [
          ChatMessage(
            id: 'm6',
            text:
                'Bonjour, j’aime beaucoup votre travail. Proposez-vous '
                'des ateliers pour débutants ?',
            at: now.subtract(const Duration(minutes: 35)),
            fromMe: false,
          ),
        ],
      ),
    ]);
  }
}
