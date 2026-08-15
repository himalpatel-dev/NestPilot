import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_config.dart';
import '../../config/modules.dart';
import '../../models/notice_complaint.dart';
import '../../services/notice_complaint_service.dart';
import '../../services/permission_service.dart';
import '../../services/session_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_page_header.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint complaint;
  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ComplaintService _complaintService = ComplaintService();

  bool _isSubmitting = false;
  bool _updatingStatus = false;
  late String _currentStatus;
  List<ComplaintComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.complaint.status;
    _comments = List.from(widget.complaint.comments);
    _setupSocket();
  }

  @override
  void dispose() {
    SocketService().off('new_comment');
    SocketService().off('complaint_status_updated'); // Unsubscribe
    _commentController.dispose();
    super.dispose();
  }

  void _setupSocket() {
    SocketService().on('new_comment', (data) {
      if (data != null &&
          data['complaint_id'].toString() == widget.complaint.id) {
        if (mounted) {
          final newComment = ComplaintComment.fromJson(data['comment']);
          if (!_comments.any((c) => c.id == newComment.id)) {
            setState(() {
              _comments.insert(0, newComment);
            });
          }
        }
      }
    });

    SocketService().on('complaint_status_updated', (data) {
      if (data != null &&
          data['complaint_id'].toString() == widget.complaint.id) {
        if (mounted) {
          setState(() {
            _currentStatus = data['status'];
          });
          _toast(
            'Status updated to ${_statusLabel(_currentStatus)}',
            color: _statusColor(_currentStatus),
          );
        }
      }
    });
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final newComment = await _complaintService.addComment(
        widget.complaint.id,
        text,
      );
      if (newComment != null && mounted) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        setState(() {
          _comments.insert(0, newComment);
        });
      }
    } catch (e) {
      if (mounted) _toast(e.toString(), color: AppColors.accentRed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updatingStatus = true);
    try {
      final success = await _complaintService.updateStatus(
        widget.complaint.id,
        newStatus,
      );
      if (!mounted) return;
      setState(() {
        _updatingStatus = false;
        if (success) _currentStatus = newStatus;
      });
      _toast(
        success
            ? 'Status updated to ${_statusLabel(newStatus)}'
            : 'Could not update the status',
        color: success ? _statusColor(newStatus) : AppColors.accentRed,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingStatus = false);
      _toast(e.toString(), color: AppColors.accentRed);
    }
  }

  void _toast(String message, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: color ?? AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ─── Status / category helpers (mirrored from the list so a complaint keeps
  //     the same colour and wording everywhere) ────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'RESOLVED':
        return AppColors.accentGreen;
      case 'IN_PROGRESS':
        return AppColors.accentAmber;
      case 'REJECTED':
        return AppColors.accentRed;
      default: // OPEN
        return AppColors.accentBlue;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'RESOLVED':
        return Icons.check_circle_rounded;
      case 'IN_PROGRESS':
        return Icons.autorenew_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      default: // OPEN
        return Icons.error_outline_rounded;
    }
  }

  String _statusLabel(String status) => status.replaceAll('_', ' ');

  String _statusHint(String status) {
    switch (status) {
      case 'RESOLVED':
        return 'Issue has been fixed';
      case 'IN_PROGRESS':
        return 'Someone is working on it';
      case 'REJECTED':
        return 'Closed without action';
      default: // OPEN
        return 'Reported and awaiting review';
    }
  }

  /// How many tracker steps (RAISED → IN PROGRESS → RESOLVED) are completed
  /// for a given status.
  int _stepsDone(String status) {
    switch (status) {
      case 'RESOLVED':
        return 3;
      case 'IN_PROGRESS':
        return 2;
      default: // OPEN / REJECTED
        return 1;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'PLUMBING':
        return Icons.water_drop_outlined;
      case 'ELECTRICAL':
        return Icons.bolt_outlined;
      case 'CARPENTRY':
        return Icons.handyman_outlined;
      case 'CLEANING':
        return Icons.cleaning_services_outlined;
      case 'SECURITY':
        return Icons.shield_outlined;
      case 'LIFT':
        return Icons.elevator_outlined;
      default:
        return Icons.report_problem_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'PLUMBING':
        return AppColors.accentBlue;
      case 'ELECTRICAL':
        return AppColors.accentAmber;
      case 'CARPENTRY':
        return AppColors.accentBrown;
      case 'CLEANING':
        return AppColors.accentTeal;
      case 'SECURITY':
        return AppColors.accentIndigo;
      default:
        return AppColors.accentRed;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return AppColors.accentRed;
      case 'LOW':
        return AppColors.accentGreen;
      default: // MEDIUM
        return AppColors.accentAmber;
    }
  }

  /// Stable per-author avatar tint, so the same resident keeps one colour
  /// down the comment thread.
  Color _avatarColor(String name) {
    const palette = [
      AppColors.accentIndigo,
      AppColors.accentTeal,
      AppColors.accentPurple,
      AppColors.accentOrange,
      AppColors.accentBlue,
      AppColors.accentPink,
    ];
    if (name.isEmpty) return palette.first;
    return palette[name.codeUnits.fold(0, (a, b) => a + b) % palette.length];
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final time = DateFormat('hh:mm a').format(d);
    if (day == today) return 'Today · $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · $time';
    }
    return '${DateFormat('d MMM').format(d)} · $time';
  }

  String? get _imageUrl {
    final path = widget.complaint.imagePath;
    if (path == null || path.isEmpty) return null;
    return path.startsWith('http') ? path : '${AppConfig.baseUrl}$path';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService().canManage(ModuleCodes.complaints);
    final imageUrl = _imageUrl;
    final commentsClosed =
        _currentStatus == 'RESOLVED' || _currentStatus == 'REJECTED';

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          AppPageHeader(
            icon: Icons.report_problem_outlined,
            title: 'Complaint',
            accentColor: ModuleColors.complaints,
            subtitle: 'Raised ${_dateLabel(widget.complaint.createdAt)}',
          ),

          // Sits outside the scroll view so the gap under the fixed header
          // survives scrolling instead of collapsing with the content.
          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryCard(canManage),
                  const SizedBox(height: 16),
                  _descriptionCard(),
                  if (imageUrl != null) ...[
                    const SizedBox(height: 16),
                    _photoCard(imageUrl),
                  ],
                  const SizedBox(height: 22),
                  _commentsHeader(),
                  const SizedBox(height: 14),
                  if (_comments.isEmpty)
                    _emptyComments(commentsClosed)
                  else
                    for (final c in _comments) _commentCard(c),
                ],
              ),
            ),
          ),

          commentsClosed ? _closedComposer() : _composer(),
        ],
      ),
    );
  }

  // ─── Summary card — category, status, tracker, meta ─────────────────────────

  Widget _summaryCard(bool canManage) {
    final complaint = widget.complaint;
    final categoryColor = _categoryColor(complaint.category);
    final statusColor = _statusColor(_currentStatus);

    return _card(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _categoryIcon(complaint.category),
                  color: categoryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.category.toUpperCase(),
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Status pill — the row doubles as the manage-only status editor.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(_currentStatus),
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _statusLabel(_currentStatus),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (canManage)
                GestureDetector(
                  onTap: _updatingStatus ? null : _showStatusDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_updatingStatus)
                          const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _updatingStatus ? 'Updating…' : 'Change',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),
          _progressTracker(),
          const SizedBox(height: 18),

          _infoRow(
            icon: Icons.calendar_month_rounded,
            color: AppColors.accentIndigo,
            label: 'Raised on',
            value: DateFormat(
              'dd MMM yyyy · hh:mm a',
            ).format(complaint.createdAt),
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.flag_rounded,
            color: _priorityColor(complaint.priority),
            label: 'Priority',
            value: complaint.priority,
          ),
        ],
      ),
    );
  }

  // ─── Progress tracker: RAISED → IN PROGRESS → RESOLVED ────────────────────

  Widget _progressTracker() {
    const steps = ['RAISED', 'IN PROGRESS', 'RESOLVED'];
    final done = _stepsDone(_currentStatus);
    final rejected = _currentStatus == 'REJECTED';
    final activeColor = rejected ? AppColors.accentRed : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 9, left: 4, right: 4),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: i < done ? activeColor : AppColors.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                Icon(
                  i < done
                      ? (rejected
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline_rounded)
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: i < done ? activeColor : AppColors.textHint,
                ),
                const SizedBox(height: 5),
                Text(
                  steps[i],
                  style: TextStyle(
                    color: i < done ? activeColor : AppColors.textHint,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Description ────────────────────────────────────────────────────────────

  Widget _descriptionCard() {
    return _card(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Issue Details', ModuleColors.complaints),
          const SizedBox(height: 18),
          Text(
            widget.complaint.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15.5,
              height: 1.85,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Photo ──────────────────────────────────────────────────────────────────

  Widget _photoCard(String url) {
    return _card(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('Attached Photo', AppColors.accentIndigo),
              const Spacer(),
              const Text(
                'Tap to enlarge',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _openPhoto(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 210,
                        color: AppColors.cardBackground,
                        alignment: Alignment.center,
                        child: const NestLoader(size: 40, showDots: false),
                      ),
                errorBuilder: (_, _, _) => Container(
                  height: 210,
                  color: AppColors.cardBackground,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 34,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Photo unavailable',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPhoto(String url) {
    showDialog(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.92),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: SizedBox.expand(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      size: 60,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Comments ───────────────────────────────────────────────────────────────

  Widget _commentsHeader() {
    return Row(
      children: [
        _sectionTitle('Comments', ModuleColors.complaints),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ModuleColors.complaints.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_comments.length}',
            style: const TextStyle(
              color: ModuleColors.complaints,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyComments(bool closed) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.forum_outlined,
              size: 24,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No comments yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            closed
                ? 'This complaint was closed without any discussion.'
                : 'Start the conversation — updates you post appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentCard(ComplaintComment comment) {
    final color = _avatarColor(comment.userName);
    final initial = comment.userName.isNotEmpty
        ? comment.userName[0].toUpperCase()
        : '?';
    final isMine =
        SessionService().currentUser?.fullName.trim().toLowerCase() ==
        comment.userName.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 13, 16, 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMine
              ? ModuleColors.complaints.withValues(alpha: 0.25)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: color,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
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
                        comment.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ModuleColors.complaints.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: ModuleColors.complaints,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _dateLabel(comment.createdAt),
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment.message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Composer ───────────────────────────────────────────────────────────────

  Widget _composer() {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              // The global inputDecorationTheme injects a grey fill and an
              // outline border, so every state is overridden here to keep the
              // pill clean.
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _isSubmitting ? null : _addComment(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: 'Write a comment…',
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Rebuilds on every keystroke so the send button dims until there is
          // something to post.
          ListenableBuilder(
            listenable: _commentController,
            builder: (context, _) {
              final canSend =
                  _commentController.text.trim().isNotEmpty && !_isSubmitting;
              return GestureDetector(
                onTap: canSend ? _addComment : null,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: canSend ? ModuleColors.complaints : AppColors.border,
                    shape: BoxShape.circle,
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: ModuleColors.complaints.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 19,
                          color: canSend ? AppColors.white : AppColors.textHint,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _closedComposer() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final color = _statusColor(_currentStatus);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.lock_outline_rounded, size: 18, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comments are closed',
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This complaint is marked ${_statusLabel(_currentStatus).toLowerCase()}.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status picker ──────────────────────────────────────────────────────────

  Future<void> _showStatusDialog() async {
    const options = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED'];

    final selected = await showDialog<String>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.15),
                blurRadius: 28,
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
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                color: ModuleColors.complaints,
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.40),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.published_with_changes_rounded,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Update Status',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Where does this complaint stand now?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  children: [
                    for (final status in options) ...[
                      _statusOption(ctx, status),
                      if (status != options.last) const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && selected != _currentStatus) {
      await _updateStatus(selected);
    }
  }

  Widget _statusOption(BuildContext ctx, String status) {
    final color = _statusColor(status);
    final selected = status == _currentStatus;

    return GestureDetector(
      onTap: () => Navigator.pop(ctx, status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.35) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(_statusIcon(status), size: 17, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: selected ? color : AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusHint(status),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 19, color: color),
          ],
        ),
      ),
    );
  }

  // ─── Shared bits ────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, Color accent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
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
        Expanded(
          child: Column(
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
