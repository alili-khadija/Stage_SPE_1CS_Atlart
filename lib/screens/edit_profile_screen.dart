import 'package:flutter/material.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/profile_shared_widgets.dart';

/// "Modifier le profil" : nom, bio, localisation, téléphone et liens
/// réseaux sociaux. Les valeurs initiales viennent du profil courant ;
/// remplace les valeurs par défaut ci-dessous par celles de l'utilisateur
/// connecté dès que le modèle de compte est branché.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.initialName = '',
    this.initialBio = '',
    this.initialLocation = '',
    this.initialPhone = '',
    this.initialInstagram = '',
    this.initialLinkedin = '',
    this.initialPinterest = '',
  });

  final String initialName;
  final String initialBio;
  final String initialLocation;
  final String initialPhone;
  final String initialInstagram;
  final String initialLinkedin;
  final String initialPinterest;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _bio = TextEditingController(text: widget.initialBio);
  late final _location = TextEditingController(text: widget.initialLocation);
  late final _phone = TextEditingController(text: widget.initialPhone);
  late final _instagram = TextEditingController(text: widget.initialInstagram);
  late final _linkedin = TextEditingController(text: widget.initialLinkedin);
  late final _pinterest = TextEditingController(text: widget.initialPinterest);

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _bio, _location, _phone, _instagram, _linkedin, _pinterest]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pop((
      name: _name.text.trim(),
      bio: _bio.text.trim(),
      location: _location.text.trim(),
      phone: _phone.text.trim(),
      instagram: _instagram.text.trim(),
      linkedin: _linkedin.text.trim(),
      pinterest: _pinterest.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      appBar: const ProfileSubPageHeader(title: 'Modifier le profil'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                children: [
                  Center(
                    child: Column(
                      children: [
                        InitialsAvatar(
                          name: widget.initialName.isEmpty ? '?' : widget.initialName,
                          radius: 39,
                        ),
                        const SizedBox(height: 9),
                        GestureDetector(
                          onTap: () {}, // TODO: sélecteur d'image (image_picker)
                          child: const Text(
                            'Changer la photo',
                            style: TextStyle(
                              color: AtlartPalette.coral,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _EditField(label: 'Nom', controller: _name),
                  _EditField(label: 'Bio', controller: _bio, multiline: true, hint: 'Le contexte ou l\'histoire derrière cette création...'),
                  _EditField(label: 'Localisation', controller: _location),
                  _EditField(label: 'Numéro de téléphone', controller: _phone, keyboardType: TextInputType.phone),
                  _EditField(label: 'Instagram', controller: _instagram, keyboardType: TextInputType.url),
                  _EditField(label: 'LinkedIn', controller: _linkedin, keyboardType: TextInputType.url),
                  _EditField(label: 'Pinterest', controller: _pinterest, keyboardType: TextInputType.url),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PillButton(label: 'Enregistrer', loading: _saving, onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.multiline = false,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool multiline;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9.5,
                letterSpacing: 0.5,
                color: AtlartPalette.blueTextLight,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            TextField(
              controller: controller,
              maxLines: multiline ? 3 : 1,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AtlartPalette.navy,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AtlartPalette.blueTextLight,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}