import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/messaging.dart';
import '../theme/atlart_ui_theme.dart' show AtlartAssets;
import '../widgets/messaging_ui.dart';
import '../widgets/offers_ui.dart';
import 'conversation_screen.dart';

/// Boîte de réception (onglet « Messagerie »).
/// Filtres : Tous · Non lus · Demandes (conversations pas encore ouvertes).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

enum _Filter { all, unread, requests }

class _MessagesScreenState extends State<MessagesScreen> {
  final _store = MessageStore.instance;
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _store.loadRemote().catchError((Object error) {
      debugPrint('Unable to load conversations: $error');
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ChatThread> _visible(List<ChatThread> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((t) {
      final matchesFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.unread => t.unread > 0,
        _Filter.requests => t.isRequest,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return '${t.participant.name} ${t.about.title}'.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return OffersScaffold(
      title: 'Messagerie',
      navIndex: 1,
      logoAsset: AtlartAssets.logoHorizontal,
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final all = _store.threads;
          final threads = _visible(all);
          final unread = all.where((t) => t.unread > 0).length;
          final requests = all.where((t) => t.isRequest).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _SearchField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(
                      label: 'Tous',
                      selected: _filter == _Filter.all,
                      onTap: () => setState(() => _filter = _Filter.all),
                    ),
                    _FilterChip(
                      label: 'Non lus${unread > 0 ? ' · $unread' : ''}',
                      selected: _filter == _Filter.unread,
                      onTap: () => setState(() => _filter = _Filter.unread),
                    ),
                    _FilterChip(
                      label: 'Demandes${requests > 0 ? ' · $requests' : ''}',
                      selected: _filter == _Filter.requests,
                      onTap: () => setState(() => _filter = _Filter.requests),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: threads.isEmpty
                    ? _Empty(filtering: all.isNotEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: threads.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _ThreadTile(
                          thread: threads[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ConversationScreen(threadId: threads[i].id),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          const Icon(Icons.search_rounded, size: 18, color: OfferColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: OfferText.poppins(11.5),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Rechercher une conversation',
                hintStyle: OfferText.poppins(11, color: OfferColors.muted),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Effacer la recherche',
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: OfferColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? OfferColors.steel : const Color(0xFFD6E5F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  label,
                  style: OfferText.poppins(
                    10,
                    weight: FontWeight.w600,
                    color: selected ? Colors.white : OfferColors.steel,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = thread.last;
    final unread = thread.unread > 0;
    final preview = last?.text ?? '';
    final prefix = last != null && last.fromMe && !last.system ? 'Vous : ' : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: OfferColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ChatAvatar(name: thread.participant.name),
                    if (unread)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: OfferColors.coral,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              thread.participant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: OfferText.poppins(
                                12,
                                weight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (thread.participant.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 12,
                              color: Color(0xFF36B77A),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            chatListTime(thread.updatedAt),
                            style: OfferText.poppins(
                              8.5,
                              color: OfferColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${thread.about.kindLabel} · ${thread.about.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OfferText.poppins(
                          9,
                          color: const Color(0xFF6C9BD8),
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$prefix$preview',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: OfferText.poppins(
                          10,
                          height: 1.4,
                          weight: unread ? FontWeight.w600 : FontWeight.w400,
                          color: unread ? OfferColors.ink : OfferColors.muted,
                        ),
                      ),
                      if (thread.isRequest) ...[
                        const SizedBox(height: 6),
                        ThreadStatusPill(thread: thread),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtering});

  final bool filtering;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: OfferColors.shadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: OfferColors.steel,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filtering ? 'Aucun résultat' : 'Aucun message',
              style: OfferText.serif(17),
            ),
            const SizedBox(height: 6),
            Text(
              filtering
                  ? 'Essayez un autre filtre ou un autre mot-clé.'
                  : 'Contactez un artiste, un artisan ou un organisateur '
                        'depuis sa fiche : vos échanges apparaîtront ici.',
              textAlign: TextAlign.center,
              style: OfferText.poppins(
                10,
                color: OfferColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
