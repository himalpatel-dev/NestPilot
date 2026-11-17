import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nest_pilot_mobile/config/modules.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:nest_pilot_mobile/services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_page_header.dart';
import 'poll_voters_sheet.dart';

class PollDetailScreen extends StatefulWidget {
  final Poll poll;
  const PollDetailScreen({super.key, required this.poll});

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  final CommunityService _service = CommunityService();

  late bool _hasVoted =
      widget.poll.votes != null && widget.poll.votes!.isNotEmpty;
  bool _voting = false;
  bool _deleting = false;

  Map<String, dynamic>? _results;
  bool _loadingResults = false;
  String? _resultsError;

  bool get _isEnded =>
      DateTime.parse(widget.poll.endDate).isBefore(DateTime.now());
  bool get _canManage => PermissionService().canManage(ModuleCodes.polls);

  @override
  void initState() {
    super.initState();
    if (_canManage || _hasVoted) _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _loadingResults = true;
      _resultsError = null;
    });
    try {
      final data = await _service.getPollResults(widget.poll.id);
      if (!mounted) return;
      setState(() {
        _results = data;
        _loadingResults = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultsError = e.toString().replaceFirst('Exception: ', '');
        _loadingResults = false;
      });
    }
  }

  Future<void> _vote(int optionId) async {
    if (_voting) return;
    setState(() => _voting = true);
    try {
      await _service.votePoll(widget.poll.id, optionId);
      if (!mounted) return;
      setState(() => _hasVoted = true);
      await _loadResults();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  /// Deletes the poll and pops `true` so the list knows to refetch.
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                color: AppColors.accentRed,
                child: const Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: AppColors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Delete Poll',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Delete "${widget.poll.question}"? This cannot be undone.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: const Text(
                          'Keep',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRed,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await _service.deletePoll(widget.poll.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final canManage = _canManage;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final endDate = DateFormat(
      'EEE, dd MMM yyyy',
    ).format(DateTime.parse(poll.endDate));

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Stack(
        children: [
          Column(
            children: [
              AppPageHeader(
                icon: Icons.how_to_vote_outlined,
                title: 'Poll',
                accentColor: ModuleColors.polls,
                subtitle: _isEnded ? 'Ended' : 'Active',
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    bottomPad + (canManage ? 116 : 40),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Info card ──────────────────────────────────────────
                      _card(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              poll.question,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.3,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (poll.description != null &&
                                poll.description!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                poll.description!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14.5,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            _infoRow(
                              icon: Icons.event_outlined,
                              color: AppColors.accentIndigo,
                              label: 'Ends On',
                              value: endDate,
                            ),
                          ],
                        ),
                      ),

                      // ── Vote or results ─────────────────────────────────────
                      const SizedBox(height: 16),
                      if (canManage || _hasVoted)
                        _resultsCard()
                      else if (!_isEnded)
                        _votingCard()
                      else
                        _card(
                          padding: const EdgeInsets.all(20),
                          child: const Text(
                            'This poll has ended.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Floating delete ───────────────────────────────────────────────
          if (canManage) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: bottomPad + 104,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.cardBackground.withValues(alpha: 0),
                        AppColors.cardBackground.withValues(alpha: 0.9),
                        AppColors.cardBackground,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPad + 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentRed.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _deleting ? null : _confirmDelete,
                    icon: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.delete_outline, size: 20),
                    label: Text(_deleting ? 'Deleting…' : 'Delete Poll'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.accentRed.withValues(
                        alpha: 0.6,
                      ),
                      disabledForegroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _votingCard() {
    return _card(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: ModuleColors.polls,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Cast your vote',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_voting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          ...?widget.poll.options?.map(
            (opt) => RadioListTile<int>(
              title: Text(opt.optionText),
              value: opt.id,
              groupValue: null,
              onChanged: _voting ? null : (val) => _vote(val!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsCard() {
    return _card(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: ModuleColors.polls,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _canManage ? 'Live Results' : 'You voted — Results',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_hasVoters)
                GestureDetector(
                  onTap: () => _openVoters(null),
                  behavior: HitTestBehavior.opaque,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups_2_outlined,
                        size: 16,
                        color: ModuleColors.polls,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'All voters',
                        style: TextStyle(
                          color: ModuleColors.polls,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: ModuleColors.polls,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingResults)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: NestLoader()),
            )
          else if (_resultsError != null)
            Text(
              _resultsError!,
              style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
            )
          else if (_results != null)
            _resultsBody(_results!),
        ],
      ),
    );
  }

  Widget _resultsBody(Map<String, dynamic> data) {
    final results = data['results'] as List;
    final totalVotes = results.fold<int>(
      0,
      (sum, item) => sum + (item['count'] as int),
    );
    final totalMembers = data['totalMembers'] ?? 0;
    final participation = totalMembers > 0
        ? (totalVotes / totalMembers * 100).toStringAsFixed(1)
        : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ModuleColors.polls.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total Votes', totalVotes.toString()),
              _statItem('Total Members', totalMembers.toString()),
              _statItem('Participation', '$participation%'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < results.length; i++)
          _optionResult(
            results[i] as Map<String, dynamic>,
            index: i,
            totalVotes: totalVotes,
          ),
      ],
    );
  }

  Widget _optionResult(
    Map<String, dynamic> r, {
    required int index,
    required int totalVotes,
  }) {
    final count = r['count'] as int;
    final percentage = totalVotes > 0 ? (count / totalVotes) : 0.0;
    final percentageText = '${(percentage * 100).toStringAsFixed(1)}%';
    // `voters` is only sent to POLLS managers; residents get counts alone.
    final voters = (r['voters'] as List?)?.cast<Map<String, dynamic>>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  r['option'],
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                percentageText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: ModuleColors.polls,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: ModuleColors.polls,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$count ${count == 1 ? 'vote' : 'votes'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (voters != null && voters.isNotEmpty)
                _voterPreview(voters, onTap: () => _openVoters(index)),
            ],
          ),
        ],
      ),
    );
  }

  /// True once results carry voter details (POLLS managers only) and at
  /// least one vote exists.
  bool get _hasVoters {
    final results = _results?['results'];
    if (results is! List) return false;
    return results.any(
      (r) => ((r as Map)['voters'] as List?)?.isNotEmpty ?? false,
    );
  }

  /// Opens the voters sheet, preselecting [optionIndex] (null = all options).
  void _openVoters(int? optionIndex) {
    final results = _results?['results'];
    if (results is! List) return;
    showPollVotersSheet(
      context,
      question: widget.poll.question,
      results: results,
      initialOption: optionIndex,
    );
  }

  /// Compact "who voted" strip for one option: up to three overlapping
  /// avatars, a "+N" bubble for the rest, and a View pill. It stays the same
  /// size however many people voted; the full list lives in the sheet.
  Widget _voterPreview(
    List<Map<String, dynamic>> voters, {
    required VoidCallback onTap,
  }) {
    const size = 26.0;
    const step = 18.0;
    final shown = voters.take(3).toList();
    final extra = voters.length - shown.length;
    final bubbles = shown.length + (extra > 0 ? 1 : 0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size + (bubbles - 1) * step,
            height: size,
            child: Stack(
              children: [
                for (int i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * step,
                    child: PollVoterAvatar(
                      name: shown[i]['name']?.toString() ?? '',
                      size: size,
                      ringed: true,
                    ),
                  ),
                if (extra > 0)
                  Positioned(
                    left: shown.length * step,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: ModuleColors.polls,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        extra > 99 ? '99+' : '+$extra',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
            decoration: BoxDecoration(
              color: ModuleColors.polls.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View',
                  style: TextStyle(
                    color: ModuleColors.polls,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: ModuleColors.polls,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: ModuleColors.polls,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
