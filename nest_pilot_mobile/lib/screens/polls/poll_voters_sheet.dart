import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_field_card.dart';

/// Darker shade of the polls accent, readable on its own light tints.
final Color _pollsInk = Color.lerp(ModuleColors.polls, AppColors.black, 0.25)!;

/// Initials for a voter avatar: first + last word, or 'U' when blank.
String pollVoterInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Circular initials avatar in the polls accent. [ringed] adds a white ring
/// so overlapping avatars in a stack stay distinct.
class PollVoterAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool ringed;

  const PollVoterAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.ringed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Opaque tint so stacked avatars don't show through each other.
        color: Color.alphaBlend(
          ModuleColors.polls.withValues(alpha: 0.16),
          AppColors.white,
        ),
        shape: BoxShape.circle,
        border: ringed ? Border.all(color: AppColors.white, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        pollVoterInitials(name),
        style: TextStyle(
          color: _pollsInk,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Opens the full, searchable voter list for a poll.
///
/// [results] is the `results` array from the poll results API, where each
/// option carries a `voters` list (sent to POLLS managers only).
/// [initialOption] preselects that option's filter; null shows everyone.
Future<void> showPollVotersSheet(
  BuildContext context, {
  required String question,
  required List results,
  int? initialOption,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _PollVotersSheet(
      question: question,
      results: results,
      initialOption: initialOption,
    ),
  );
}

class _Vote {
  final String name;
  final String? flat;
  final DateTime? votedAt;
  final int optionIndex;

  const _Vote({
    required this.name,
    required this.flat,
    required this.votedAt,
    required this.optionIndex,
  });

  factory _Vote.fromJson(Map<String, dynamic> json, int optionIndex) {
    final name = (json['name'] as String?)?.trim() ?? '';
    final flat = (json['flat'] as String?)?.trim() ?? '';
    return _Vote(
      name: name.isNotEmpty ? name : 'Member',
      flat: flat.isNotEmpty ? flat : null,
      votedAt: DateTime.tryParse(json['voted_at']?.toString() ?? ''),
      optionIndex: optionIndex,
    );
  }
}

class _PollVotersSheet extends StatefulWidget {
  final String question;
  final List results;
  final int? initialOption;

  const _PollVotersSheet({
    required this.question,
    required this.results,
    this.initialOption,
  });

  @override
  State<_PollVotersSheet> createState() => _PollVotersSheetState();
}

class _PollVotersSheetState extends State<_PollVotersSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  late final List<String> _options;

  /// Every vote across all options, newest first.
  late final List<_Vote> _votes;

  /// Selected option filter; null = all options.
  late int? _selected = widget.initialOption;

  @override
  void initState() {
    super.initState();
    _options = [
      for (final r in widget.results) (r as Map)['option']?.toString() ?? '',
    ];
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    _votes = [
      for (int i = 0; i < widget.results.length; i++)
        for (final v in ((widget.results[i] as Map)['voters'] as List? ?? []))
          _Vote.fromJson(v as Map<String, dynamic>, i),
    ]..sort((a, b) => (b.votedAt ?? epoch).compareTo(a.votedAt ?? epoch));
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // Filtering is local (the whole list is already loaded), so no debounce.
  void _onSearchChanged() => setState(() {});

  int _countFor(int option) =>
      _votes.where((v) => v.optionIndex == option).length;

  List<_Vote> get _visible {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _votes.where((v) {
      if (_selected != null && v.optionIndex != _selected) return false;
      if (q.isEmpty) return true;
      return v.name.toLowerCase().contains(q) ||
          (v.flat ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Fill most of the screen but stay clear of the keyboard and status bar.
    final height =
        (media.size.height - media.viewInsets.bottom - media.padding.top - 24)
            .clamp(260.0, media.size.height * 0.85);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: AppSearchField(
                controller: _searchCtrl,
                hint: 'Search name or flat',
              ),
            ),
            _buildFilters(),
            const SizedBox(height: 14),
            Expanded(child: _buildList(media.padding.bottom)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ModuleColors.polls.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.groups_2_outlined, color: _pollsInk, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voters',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.question,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontally scrolling option filters: All, then one per option.
  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterChip(
            label: 'All',
            count: _votes.length,
            selected: _selected == null,
            onTap: () => setState(() => _selected = null),
          ),
          for (int i = 0; i < _options.length; i++) ...[
            const SizedBox(width: 8),
            _filterChip(
              label: _options[i],
              count: _countFor(i),
              selected: _selected == i,
              onTap: () => setState(() => _selected = i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
        decoration: BoxDecoration(
          color: selected ? ModuleColors.polls : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? ModuleColors.polls : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.white.withValues(alpha: 0.25)
                    : ModuleColors.polls.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? AppColors.white : _pollsInk,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(double bottomPad) {
    final visible = _visible;
    if (visible.isEmpty) {
      final q = _searchCtrl.text.trim();
      return AppListEmpty(
        icon: Icons.how_to_vote_outlined,
        message: q.isNotEmpty
            ? 'No voters match "$q"'
            : 'No votes for this option yet',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _voterTile(visible[i]),
    );
  }

  Widget _voterTile(_Vote v) {
    // Under "All" each row names the option picked; within one option it's
    // implied by the filter.
    final showOption = _selected == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          PollVoterAvatar(name: v.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (v.votedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        DateFormat(
                          'd MMM, h:mm a',
                        ).format(v.votedAt!.toLocal()),
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        v.flat ?? 'No flat linked',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (showOption) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ModuleColors.polls.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _options[v.optionIndex],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _pollsInk,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
