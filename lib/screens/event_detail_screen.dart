import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/atlart_ui_theme.dart';
import '../widgets/atlart_ui_widgets.dart';

class EventProgrammeStep {
  const EventProgrammeStep({
    required this.dayLabel,
    required this.title,
    required this.subtitle,
  });

  final String dayLabel;
  final String title;
  final String subtitle;
}

class EventOrganizer {
  const EventOrganizer({
    required this.name,
    required this.location,
    this.avatarAsset,
  });

  final String name;
  final String location;
  final String? avatarAsset;
}

class EventDetail {
  const EventDetail({
    required this.title,
    required this.badge,
    required this.dateRange,
    required this.location,
    required this.note,
    required this.description,
    required this.remainingPlaces,
    required this.programme,
    required this.organizer,
    this.imageAsset,
  });

  final String title;
  final String badge;
  final String dateRange;
  final String location;
  final String note;
  final String description;
  final int remainingPlaces;
  final List<EventProgrammeStep> programme;
  final EventOrganizer organizer;
  final String? imageAsset;
}

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
    this.onRegister,
  });

  final EventDetail event;

  /// Le parent peut fournir ici la navigation vers son parcours d’inscription.
  final VoidCallback? onRegister;

  void _showRegistrationUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Le parcours d’inscription à cet événement n’est pas encore connecté.',
          ),
        ),
      );
  }

  void _showOrganizerProfile(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(event.organizer.name),
        content: Text(
          'Organisateur · ${event.organizer.location}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.copy_rounded),
          title: const Text('Copier le titre de l’événement'),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: event.title));
            if (!sheetContext.mounted) return;
            Navigator.of(sheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Titre copié.')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Hero(
                  event: event,
                  onMoreTap: () => _showMoreOptions(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: AtlartType.title.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        text: event.dateRange,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: event.location,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        text: event.note,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        event.description,
                        style: AtlartType.subtitle.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 18),
                      _RemainingPlaces(count: event.remainingPlaces),
                      const SizedBox(height: 24),
                      const Text('PROGRAMME', style: AtlartType.stepsLabel),
                      const SizedBox(height: 12),
                      if (event.programme.isEmpty)
                        Text(
                          'Le programme sera bientôt disponible.',
                          style: AtlartType.subtitle,
                        )
                      else
                        for (final step in event.programme) ...[
                          _ProgrammeTile(step: step),
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 8),
                      const Text('ORGANISATEUR', style: AtlartType.stepsLabel),
                      const SizedBox(height: 10),
                      _OrganizerCard(
                        organizer: event.organizer,
                        onViewProfile: () => _showOrganizerProfile(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _BottomButton(
            onPressed: onRegister ??
                () => _showRegistrationUnavailable(context),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.event,
    required this.onMoreTap,
  });

  final EventDetail event;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final imageAsset = event.imageAsset;

    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageAsset != null && imageAsset.isNotEmpty)
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _HeroPlaceholder(),
            )
          else
            const _HeroPlaceholder(),
          Positioned(
            top: topInset + 8,
            left: 16,
            child: const AtlartBack(),
          ),
          Positioned(
            top: topInset + 8,
            right: 16,
            child: _RoundIconButton(
              icon: Icons.more_horiz_rounded,
              onTap: onMoreTap,
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AtlartPalette.coral,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                event.badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AtlartPalette.skyHeader,
            AtlartPalette.cardFill,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 44,
          color: AtlartPalette.blueTextLight,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 19,
            color: AtlartPalette.navy,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AtlartPalette.blueText),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: AtlartType.subtitle)),
      ],
    );
  }
}

class _RemainingPlaces extends StatelessWidget {
  const _RemainingPlaces({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 22,
          child: Stack(
            children: [
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 14.0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AtlartPalette.skyHeader,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          count == 1 ? '1 place restante' : '$count places restantes',
          style: AtlartType.subtitle.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ProgrammeTile extends StatelessWidget {
  const _ProgrammeTile({required this.step});

  final EventProgrammeStep step;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          constraints: const BoxConstraints(minHeight: 28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AtlartPalette.skyHeader,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            step.dayLabel,
            style: const TextStyle(
              color: AtlartPalette.navyDark,
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: AtlartType.stepTitle),
              const SizedBox(height: 2),
              Text(step.subtitle, style: AtlartType.stepSubtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrganizerCard extends StatelessWidget {
  const _OrganizerCard({
    required this.organizer,
    required this.onViewProfile,
  });

  final EventOrganizer organizer;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final avatarAsset = organizer.avatarAsset;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AtlartPalette.cardFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AtlartPalette.skyHeader,
            backgroundImage:
                avatarAsset != null && avatarAsset.isNotEmpty
                    ? AssetImage(avatarAsset)
                    : null,
            child: avatarAsset == null || avatarAsset.isEmpty
                ? const Icon(
                    Icons.person_outline_rounded,
                    color: AtlartPalette.blueText,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organizer.name,
                  style: AtlartType.cardTitle.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  organizer.location,
                  style: AtlartType.cardDesc.copyWith(fontSize: 9.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewProfile,
            child: const Text('Voir le profil'),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AtlartButton(
          label: "S'inscrire",
          onPressed: onPressed,
        ),
      ),
    );
  }
}