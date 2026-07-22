import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/nest_loader.dart';
import '../../../widgets/app_field_card.dart';
import '../../../widgets/app_form_sheet.dart';
import '../../../widgets/glare_button.dart';
import '../../../widgets/module_page_header.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:nest_pilot_mobile/services/permission_service.dart';
import 'package:nest_pilot_mobile/config/modules.dart';

class PollListScreen extends StatefulWidget {
  const PollListScreen({super.key});

  @override
  State<PollListScreen> createState() => _PollListScreenState();
}

class _PollListScreenState extends State<PollListScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();

  List<Poll> _polls = [];
  bool _isLoading = true;
  String _query = '';

  List<Poll> get _filteredPolls {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _polls;
    return _polls.where((p) => p.question.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchPolls();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPolls() async {
    try {
      final polls = await _service.getActivePolls();
      if (mounted) {
        setState(() {
          _polls = polls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _vote(int pollId, int optionId) async {
    try {
      await _service.votePoll(pollId, optionId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vote recorded!')));
      _fetchPolls();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showResults(int pollId) async {
    try {
      final data = await _service.getPollResults(pollId);
      final results = (data['results'] as List);
      final totalVotes = results.fold<int>(
        0,
        (sum, item) => sum + (item['count'] as int),
      );
      final totalMembers = data['totalMembers'] ?? 0;
      final participation = totalMembers > 0
          ? (totalVotes / totalMembers * 100).toStringAsFixed(1)
          : '0.0';

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Poll Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['question'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total Votes',
                                totalVotes.toString(),
                              ),
                              _buildStatItem(
                                'Total Members',
                                totalMembers.toString(),
                              ),
                              _buildStatItem(
                                'Participation',
                                '$participation%',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...results.map((r) {
                          final count = r['count'] as int;
                          final percentage = totalVotes > 0
                              ? (count / totalVotes)
                              : 0.0;
                          final percentageText =
                              '${(percentage * 100).toStringAsFixed(1)}%';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r['option'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      percentageText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  children: [
                                    Container(
                                      height: 12,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: percentage,
                                      child: Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.blue,
                                              Colors.lightBlueAccent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$count votes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching results: $e')));
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Per-module perms: can_manage on POLLS distinguishes poll creators (admins)
    // from voters. Voters fall through to the default vote UI.
    final canManage = PermissionService().canManage(ModuleCodes.polls);
    final canCreate = canManage;
    final now = DateTime.now();
    final active = _polls
        .where((p) => DateTime.parse(p.endDate).isAfter(now))
        .length;
    final ended = _polls.length - active;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          ModulePageHeader(
            title: 'Polls',
            description: 'Vote & see community decisions',
            icon: Icons.how_to_vote_outlined,
            iconColor: ModuleColors.polls,
            stats: [
              ModuleHeaderStat('$active', 'ACTIVE'),
              ModuleHeaderStat('$ended', 'ENDED'),
              ModuleHeaderStat('${_polls.length}', 'TOTAL'),
            ],
            showSearch: true,
            searchHint: 'Search polls...',
            searchController: _searchController,
            onSearchChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: NestLoader())
                : _filteredPolls.isEmpty
                ? const Center(child: Text('No active polls'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filteredPolls.length,
                    itemBuilder: (context, index) {
                      final poll = _filteredPolls[index];
                      final hasVoted =
                          poll.votes != null && poll.votes!.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: canManage
                                        ? const EdgeInsets.only(right: 32)
                                        : EdgeInsets.zero,
                                    child: Text(
                                      poll.question,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (poll.description != null) ...[
                                    const SizedBox(height: 8),
                                    Text(poll.description!),
                                  ],
                                  const SizedBox(height: 16),
                                  if (canManage) ...[
                                    const Text(
                                      'Admin View - Monitor Voting',
                                      style: TextStyle(
                                        color: Colors.blueGrey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => _showResults(poll.id),
                                      icon: const Icon(Icons.bar_chart),
                                      label: const Text('View Live Results'),
                                    ),
                                  ] else if (hasVoted) ...[
                                    const Text(
                                      'You have voted',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => _showResults(poll.id),
                                      icon: const Icon(Icons.bar_chart),
                                      label: const Text('View Results'),
                                    ),
                                  ] else ...[
                                    ...poll.options!.map(
                                      (opt) => RadioListTile<int>(
                                        title: Text(opt.optionText),
                                        value: opt.id,
                                        groupValue: null,
                                        onChanged: (val) =>
                                            _vote(poll.id, val!),
                                      ),
                                    ),
                                  ],
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Ends on: ${poll.endDate.split('T')[0]}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (canManage)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _openEditSheet(poll),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentIndigo
                                            .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: AppColors.accentIndigo,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _openCreateSheet,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _openCreateSheet() {
    showAppFormSheet(
      context: context,
      builder: (ctx) => _CreatePollSheet(
        onCreated: () {
          Navigator.pop(ctx);
          _fetchPolls();
        },
      ),
    );
  }

  void _openEditSheet(Poll poll) {
    showAppFormSheet(
      context: context,
      builder: (ctx) => _CreatePollSheet(
        editing: poll,
        onCreated: () {
          Navigator.pop(ctx);
          _fetchPolls();
        },
      ),
    );
  }
}

// ─── Create poll sheet ────────────────────────────────────────────────────────

class _CreatePollSheet extends StatefulWidget {
  final VoidCallback onCreated;
  final Poll? editing;

  const _CreatePollSheet({required this.onCreated, this.editing});

  @override
  State<_CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<_CreatePollSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _questionCtrl = TextEditingController(
    text: widget.editing?.question,
  );
  late final _descCtrl = TextEditingController(
    text: widget.editing?.description,
  );
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  late DateTime? _endDate = widget.editing != null
      ? DateTime.tryParse(widget.editing!.endDate)
      : null;
  bool _dateErr = false;
  bool _isLoading = false;
  String? _apiError;

  bool get _isEditing => widget.editing != null;

  void _addOption() =>
      setState(() => _optionCtrls.add(TextEditingController()));

  void _removeOption(int index) {
    if (_optionCtrls.length <= 2) return;
    setState(() => _optionCtrls.removeAt(index).dispose());
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: appPickerTheme,
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() {
      _dateErr = _endDate == null;
      _apiError = null;
    });
    if (!formOk || _endDate == null) return;

    // Options are locked once a poll exists — votes reference option_id, so
    // editing never touches them, only question/description/end date.
    List<String> options = const [];
    if (!_isEditing) {
      options = _optionCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (options.length < 2) {
        setState(() => _apiError = 'At least 2 options are required');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        await CommunityService().updatePoll(widget.editing!.id, {
          'question': _questionCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'end_date': _endDate!.toIso8601String(),
        });
      } else {
        await CommunityService().createPoll({
          'question': _questionCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'end_date': _endDate!.toIso8601String(),
          'options': options,
        });
      }
      widget.onCreated();
    } catch (e) {
      if (mounted) {
        setState(
          () => _apiError = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      accentColor: ModuleColors.polls,
      icon: _isEditing ? Icons.edit_rounded : Icons.how_to_vote_rounded,
      title: _isEditing ? 'Edit Poll' : 'New Poll',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader('Poll Details'),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.help_outline_rounded,
              label: 'Question',
              field: AppBorderlessField(
                controller: _questionCtrl,
                hint: 'e.g. Should we install new gym equipment?',
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Question is required'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.description_outlined,
              label: 'Description',
              iconAlignment: CrossAxisAlignment.start,
              field: AppBorderlessField(
                controller: _descCtrl,
                hint: 'Optional details about the poll…',
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 24),
            const AppSectionHeader('Options'),
            const SizedBox(height: 14),
            if (_isEditing) ...[
              // Locked — votes already cast reference these by option_id, so
              // editing never touches them, only question/description/date.
              ...?widget.editing!.options?.map(
                (opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opt.optionText,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ..._optionCtrls.asMap().entries.map((entry) {
                final index = entry.key;
                final ctrl = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppFieldCard(
                          icon: Icons.circle_outlined,
                          label: 'Option ${index + 1}',
                          field: AppBorderlessField(
                            controller: ctrl,
                            hint: 'Enter option',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ),
                      if (_optionCtrls.length > 2) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeOption(index),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.accentRed.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.accentRed,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              GestureDetector(
                onTap: _addOption,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: ModuleColors.polls,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Add Option',
                      style: TextStyle(
                        color: ModuleColors.polls,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const AppSectionHeader('Schedule'),
            const SizedBox(height: 14),
            AppPickerCard(
              icon: Icons.event_outlined,
              label: 'Ends On',
              value: _endDate != null
                  ? DateFormat('EEE, d MMM yyyy').format(_endDate!)
                  : null,
              hint: 'Select end date',
              error: _dateErr,
              onTap: _pickEndDate,
            ),
            if (_apiError != null) ...[
              const SizedBox(height: 18),
              AppSheetErrorBanner(_apiError!),
            ],
            const SizedBox(height: 26),
            GlarePrimaryButton(
              text: _isEditing ? 'Update Poll' : 'Create Poll',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
