import 'package:flutter/material.dart';

import '../app_session.dart';
import '../services/auth_api.dart';
import '../services/favorite_api.dart';

/// Favorite action for any entity accepted by the backend favorites endpoint.
class FavoriteActionButton extends StatefulWidget {
  const FavoriteActionButton({
    super.key,
    required this.entityType,
    required this.entityId,
    this.size = 42,
  });

  final String entityType;
  final String? entityId;
  final double size;

  @override
  State<FavoriteActionButton> createState() => _FavoriteActionButtonState();
}

class _FavoriteActionButtonState extends State<FavoriteActionButton> {
  bool _isFavorite = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.entityId;
    final token = AtlartSession.instance.token;
    if (id == null || token == null || !AuthApi.useBackend) return;
    try {
      final rows = await FavoriteApi.list(token);
      if (!mounted) return;
      setState(() {
        _isFavorite = rows.any(
          (row) =>
              '${row['entite_type']}'.toUpperCase() ==
                  widget.entityType.toUpperCase() &&
              '${row['entite_id']}' == id,
        );
      });
    } on FavoriteApiException catch (error) {
      debugPrint('Could not load favorite: $error');
    }
  }

  Future<void> _toggle() async {
    final id = widget.entityId;
    if (id == null) {
      _message('Cet élément de démonstration n’est pas relié au catalogue.');
      return;
    }
    final token = AtlartSession.instance.token;
    if (token == null || !AuthApi.useBackend) {
      _message('Connectez-vous pour enregistrer ce favori.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_isFavorite) {
        await FavoriteApi.remove(token, widget.entityType, id);
      } else {
        await FavoriteApi.add(token, widget.entityType, id);
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } on FavoriteApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _busy ? null : _toggle,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: _busy
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFA7B6B),
                    ),
                  )
                : Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: const Color(0xFFFA7B6B),
                    size: widget.size * 0.5,
                  ),
          ),
        ),
      ),
    );
  }
}
