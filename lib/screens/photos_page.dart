import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'information_page.dart';
import 'publish_common.dart';

class PhotosPage extends StatefulWidget {
  const PhotosPage({super.key, this.draft});

  final ArtworkDraft? draft;

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  static const int _maxPhotos = 6;

  late final ArtworkDraft _draft = widget.draft ?? ArtworkDraft();
  final ImagePicker _picker = ImagePicker();

  bool _isPicking = false;

  List<String> get _photos => _draft.photoPaths;

  Future<void> _pickPhotos() async {
    if (_isPicking) return;

    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      _showMessage('Vous pouvez ajouter jusqu’à $_maxPhotos photos.');
      return;
    }

    setState(() => _isPicking = true);

    try {
      final List<XFile> files;

      if (remaining == 1) {
        final file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 2000,
          imageQuality: 85,
        );
        files = file == null ? <XFile>[] : <XFile>[file];
      } else {
        files = await _picker.pickMultiImage(
          maxWidth: 2000,
          imageQuality: 85,
        );
      }

      if (!mounted || files.isEmpty) return;

      final paths = files
          .map((file) => file.path)
          .where((path) => !_photos.contains(path))
          .take(remaining)
          .toList();

      if (paths.isNotEmpty) {
        setState(() => _photos.addAll(paths));
      }

      if (files.length > remaining) {
        _showMessage('Vous pouvez ajouter jusqu’à $_maxPhotos photos.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Impossible d’ouvrir la galerie. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _makeMainPhoto(int index) {
    if (index == 0) return;
    setState(() => _photos.insert(0, _photos.removeAt(index)));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _next() {
    if (_photos.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InformationPage(draft: _draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublishScaffold(
      title: 'Photos',
      step: 1,
      onNext: _photos.isEmpty ? null : _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel("Photos de l'œuvre"),
          const SizedBox(height: 26),
          _buildPhotoGrid(),
          const SizedBox(height: 34),
          _buildUploadZone(),
          const SizedBox(height: 20),
          _buildTip(),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final size = (constraints.maxWidth - gap * 2) / 3;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < _photos.length; i++)
              _PhotoTile(
                size: size,
                path: _photos[i],
                isMain: i == 0,
                onTap: () => _makeMainPhoto(i),
                onRemove: () => _removePhoto(i),
              ),
            if (_photos.length < _maxPhotos)
              GestureDetector(
                onTap: _pickPhotos,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: DashedBox(
                    color: const Color(0xFF9CC3EA),
                    fill: Colors.white.withValues(alpha: 0.7),
                    radius: 14,
                    child: Center(
                      child: _isPicking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.add,
                              color: Color(0xFF9CC3EA),
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _pickPhotos,
      child: SizedBox(
        height: 128,
        width: double.infinity,
        child: DashedBox(
          color: AppColors.dashed,
          fill: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.upload_outlined,
                color: Color(0xFFD9A08A),
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                _isPicking ? 'Ouverture de la galerie…' : 'Ajouter des photos',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'JPEG, PNG — appuyez pour parcourir',
                style: const TextStyle(
                  color: AppColors.hint,
                  fontFamily: 'Inter',
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline,
              size: 12,
              color: AppColors.tipText,
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              "Choisissez une photo principale nette et bien éclairée — "
              "c'est elle qui apparaîtra dans les résultats de recherche.",
              style: TextStyle(
                color: AppColors.tipText,
                fontSize: 9,
                height: 1.4,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.size,
    required this.path,
    required this.isMain,
    required this.onTap,
    required this.onRemove,
  });

  final double size;
  final String path;
  final bool isMain;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(
                    color: Color(0xFFE8EFF6),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.sectionBlue,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isMain)
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '★ Principale',
                    style: TextStyle(
                      color: AppColors.coral,
                      fontSize: 7,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 4,
              top: 4,
              child: Material(
                color: const Color(0xFF2E3B4E),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}