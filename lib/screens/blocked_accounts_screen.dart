import 'package:flutter/material.dart';

import '../app_session.dart';
import '../services/auth_api.dart';
import '../services/safety_api.dart';
import '../theme/atlart_ui_theme.dart';
import '../widgets/profile_shared_widgets.dart';

class BlockedAccount {
  BlockedAccount({
    this.userId,
    required this.name,
    required this.blockedOn,
    required this.color,
  });

  final String? userId;
  final String name;
  final String blockedOn; // ex. "Bloqué le 12 sept. 2026"
  final Color color;
}

/// "Comptes bloqués" : la personne bloquée ne peut plus écrire, suivre ni
/// voir le profil de l'utilisateur, sans en être prévenue.
class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key, this.initialAccounts});

  final List<BlockedAccount>? initialAccounts;

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  static const _colors = [
    Color(0xFF8A6FC9),
    Color(0xFF3A9BD8),
    Color(0xFF258F81),
  ];
  late final List<BlockedAccount> _accounts;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _accounts = widget.initialAccounts ?? [];
    if (widget.initialAccounts != null) {
      _loading = false;
    } else {
      _loadBlockedAccounts();
    }
  }

  String _dateLabel(Object? rawDate) {
    final date = DateTime.tryParse('$rawDate')?.toLocal();
    if (date == null) return 'Bloqué récemment';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return 'Bloqué le $day/$month/${date.year}';
  }

  Future<void> _loadBlockedAccounts() async {
    final token = AtlartSession.instance.token;
    if (!AuthApi.useBackend || token == null) {
      setState(() {
        _accounts.addAll([
          BlockedAccount(
            name: 'Karim M.',
            blockedOn: 'Bloqué le 12/09/2026',
            color: _colors[0],
          ),
          BlockedAccount(
            name: 'Zied T.',
            blockedOn: 'Bloqué le 28/08/2026',
            color: _colors[1],
          ),
        ]);
        _loading = false;
      });
      return;
    }
    try {
      final rows = await SafetyApi.blockedUsers(token);
      if (!mounted) return;
      setState(() {
        _accounts
          ..clear()
          ..addAll([
            for (var i = 0; i < rows.length; i++)
              BlockedAccount(
                userId: '${rows[i]['utilisateur_id'] ?? ''}',
                name: '${rows[i]['nom_emprunt'] ?? 'Utilisateur AtlArt'}',
                blockedOn: _dateLabel(rows[i]['date_blocage']),
                color: _colors[i % _colors.length],
              ),
          ]);
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _unblock(int index) async {
    final account = _accounts[index];
    final token = AtlartSession.instance.token;
    if (AuthApi.useBackend && token != null && account.userId != null) {
      try {
        await SafetyApi.unblockUser(token: token, userId: account.userId!);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Déblocage impossible : $error')),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    final name = _accounts[index].name;
    setState(() => _accounts.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name débloqué(e).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      appBar: const ProfileSubPageHeader(title: 'Comptes bloqués'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD3E6FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: AtlartPalette.blueText),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Les personnes bloquées ne peuvent ni vous écrire, ni vous '
                      'suivre, ni voir votre profil. Elles ne sont jamais prévenues.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: AtlartPalette.navy,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _loadError = null;
                        });
                        _loadBlockedAccounts();
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            else if (_accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('Aucun compte bloqué.', style: AtlartType.subtitle),
                ),
              )
            else ...[
              for (var i = 0; i < _accounts.length; i++)
                _BlockedRow(
                  account: _accounts[i],
                  onUnblock: () => _unblock(i),
                ),
              const SizedBox(height: 6),
              const Text(
                'Débloquer ne rétablit pas les abonnements : il faudra se '
                'suivre à nouveau.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AtlartPalette.blueTextLight,
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.account, required this.onUnblock});
  final BlockedAccount account;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14273A56), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          InitialsAvatar(name: account.name, radius: 21, gradient: [account.color, account.color]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AtlartPalette.navy,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  account.blockedOn,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AtlartPalette.blueTextLight,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onUnblock,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AtlartPalette.blueText),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            ),
            child: const Text(
              'Débloquer',
              style: TextStyle(
                color: AtlartPalette.blueText,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
