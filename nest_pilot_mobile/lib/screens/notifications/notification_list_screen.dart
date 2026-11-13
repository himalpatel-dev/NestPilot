import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/module_page_header.dart';

/// Every notification sent to the signed-in user — notices, bills, visitor
/// arrivals and the rest — newest first and grouped by day. Opens on the
/// latest 10; "Show all" pages in the rest as you scroll. Tapping one marks
/// it read and expands its full message.
class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  /// How many the page opens on, whatever their dates; "Show all" reveals
  /// the rest.
  static const int _initialCount = 10;
  static const int _pageSize = 20;

  final NotificationService _service = NotificationService();
  final List<NotificationModel> _items = [];
  final Set<int> _expanded = {};

  int _total = 0;
  int _unread = 0;
  bool _unreadOnly = false;
  bool _showAll = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String? _loadMoreError;

  // Bumped by every reload so a page requested before a refresh is dropped.
  int _requestId = 0;

  bool get _hasMore => _items.length < _total;

  List<NotificationModel> get _visible =>
      _unreadOnly ? _items.where((n) => !n.isRead).toList() : _items;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _reload() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _showAll = false;
      _error = null;
      _loadMoreError = null;
    });
    try {
      final res = await _service.getNotifications(limit: _initialCount);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.notifications);
        _expanded.clear();
        _total = res.count;
        _unread = res.unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = _errorText(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _loadMoreError != null) {
      return;
    }
    final requestId = _requestId;
    setState(() => _isLoadingMore = true);
    try {
      final res = await _service.getNotifications(
        limit: _pageSize,
        offset: _items.length,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        // New arrivals shift the offsets, so skip rows already shown.
        final seen = _items.map((n) => n.id).toSet();
        _items.addAll(res.notifications.where((n) => !seen.contains(n.id)));
        // An empty page means the total was stale — stop asking for more.
        _total = res.notifications.isEmpty ? _items.length : res.count;
        _unread = res.unreadCount;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadMoreError = _errorText(e);
        _isLoadingMore = false;
      });
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _onTap(NotificationModel n) {
    setState(() {
      if (!_expanded.remove(n.id)) _expanded.add(n.id);
    });
    if (!n.isRead) _markRead(n);
  }

  Future<void> _markRead(NotificationModel n) async {
    _setRead(n.id, true);
    try {
      await _service.markAsRead(n.id.toString());
    } catch (_) {
      // Bring the dot back rather than claim a read the server never saved.
      if (mounted) _setRead(n.id, false);
    }
  }

  void _setRead(int id, bool read) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1 || _items[i].isRead == read) return;
    setState(() {
      _items[i] = _items[i].copyWith(isRead: read);
      _unread = read ? (_unread > 0 ? _unread - 1 : 0) : _unread + 1;
    });
  }

  Future<void> _markAllRead() async {
    final wasUnread = {
      for (final n in _items)
        if (!n.isRead) n.id,
    };
    final previousUnread = _unread;
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        if (!_items[i].isRead) _items[i] = _items[i].copyWith(isRead: true);
      }
      _unread = 0;
    });
    try {
      await _service.markAsRead('all');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          if (wasUnread.contains(_items[i].id)) {
            _items[i] = _items[i].copyWith(isRead: false);
          }
        }
        _unread = previousUnread;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(e))));
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final read = _total - _unread;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      // Header and filters stay pinned; only the notifications scroll.
      body: Column(
        children: [
          ModulePageHeader(
            title: 'Notifications',
            description: 'Updates from your society, all in one place',
            icon: Icons.notifications_rounded,
            iconColor: AppColors.accentPurple,
            stats: [
              ModuleHeaderStat('$_unread', 'UNREAD'),
              ModuleHeaderStat('${read < 0 ? 0 : read}', 'READ'),
              ModuleHeaderStat('$_total', 'TOTAL'),
            ],
            showSearch: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _buildToolbar(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              color: AppColors.white,
              backgroundColor: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: _buildSlivers(bottomPad),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  'All · $_total',
                  !_unreadOnly,
                  () => setState(() => _unreadOnly = false),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  'Unread · $_unread',
                  _unreadOnly,
                  () => setState(() => _unreadOnly = true),
                ),
              ],
            ),
          ),
        ),
        if (!_isLoading && _unread > 0) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _markAllRead,
            behavior: HitTestBehavior.opaque,
            child: const Row(
              children: [
                Icon(
                  Icons.done_all_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: 4),
                Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildSlivers(double bottomPad) {
    if (_isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: NestLoader()),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _messageBox(
                icon: Icons.error_outline,
                title: 'Could not load notifications',
                subtitle: _error,
                actionLabel: 'Retry',
                onAction: _reload,
              ),
            ),
          ),
        ),
      ];
    }

    final visible = _visible;
    // Unread ones may still sit on a later page — offer "Show all" (or keep
    // paging) instead of declaring the list empty.
    final waitingForUnread = _unreadOnly && _unread > 0 && _hasMore;
    if (visible.isEmpty && !waitingForUnread) {
      return [SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())];
    }

    // A day label before the first card of each day.
    final rows = <Widget>[];
    String? lastDay;
    for (final n in visible) {
      final day = _dayLabel(n.createdAt.toLocal());
      if (day != lastDay) {
        rows.add(_dayHeader(day, first: lastDay == null));
        lastDay = day;
      }
      rows.add(
        Padding(padding: const EdgeInsets.only(bottom: 10), child: _card(n)),
      );
    }

    final showFooter = _hasMore || _loadMoreError != null;
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => i < rows.length ? rows[i] : _buildFooter(),
            childCount: rows.length + (showFooter ? 1 : 0),
          ),
        ),
      ),
    ];
  }

  Widget _dayHeader(String label, {required bool first}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, first ? 4 : 14, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _card(NotificationModel n) {
    final style = _typeStyle(n.type);
    final unread = !n.isRead;
    final expanded = _expanded.contains(n.id);

    return GestureDetector(
      onTap: () => _onTap(n),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread
                ? style.color.withValues(alpha: 0.40)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: unread ? 0.08 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                style.icon,
                color: Color.lerp(style.color, AppColors.black, 0.15),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          maxLines: expanded ? null : 2,
                          overflow: expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: unread
                                ? FontWeight.w800
                                : FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: const BoxDecoration(
                            color: AppColors.accentRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    maxLines: expanded ? null : 2,
                    overflow: expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _pill(style.label, style.color),
                      const Spacer(),
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _timeLabel(n.createdAt.toLocal()),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_loadMoreError != null) {
      return Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() => _loadMoreError = null);
            _loadMore();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Could not load more — tap to retry'),
        ),
      );
    }
    if (!_showAll) return _showAllButton();
    // Once "Show all" is on, the footer is only built as it scrolls near the
    // viewport, so reaching it is what pulls the next page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMore();
    });
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: NestLoader(size: 28, showDots: false)),
    );
  }

  void _onShowAll() {
    setState(() => _showAll = true);
    _loadMore();
  }

  // White bordered row, the same surface as the profile's action rows.
  Widget _showAllButton() {
    final remaining = _total - _items.length;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: _onShowAll,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  remaining > 0 ? 'Show all · $remaining more' : 'Show all',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _unreadOnly
                    ? Icons.mark_email_read_outlined
                    : Icons.notifications_off_outlined,
                color: Color.lerp(AppColors.accentPurple, AppColors.black, 0.2),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _unreadOnly ? "You're all caught up" : 'No notifications yet',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _unreadOnly
                  ? 'There is nothing new to read.'
                  : 'Notices, bills, visitor arrivals and other updates '
                        'will show up here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Same chip as the Complaints / Notices / User Management filters.
  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Same message box as the User Management list.
  Widget _messageBox({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textHint, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared bits ─────────────────────────────────────────────────────────────

String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

typedef _TypeStyle = ({IconData icon, Color color, String label});

// Icon and colour of the module each notification comes from — the same ones
// its tile uses on the dashboard.
_TypeStyle _typeStyle(String type) {
  switch (type.toUpperCase()) {
    case 'NOTICE':
      return (
        icon: Icons.campaign_outlined,
        color: ModuleColors.notices,
        label: 'Notice',
      );
    case 'COMPLAINT':
      return (
        icon: Icons.report_problem_outlined,
        color: ModuleColors.complaints,
        label: 'Complaint',
      );
    case 'BILL':
      return (
        icon: Icons.receipt_long_outlined,
        color: ModuleColors.bills,
        label: 'Bill',
      );
    case 'PAYMENT':
      return (
        icon: Icons.payments_outlined,
        color: AppColors.accentGreen,
        label: 'Payment',
      );
    case 'EVENT':
      return (
        icon: Icons.event_outlined,
        color: ModuleColors.events,
        label: 'Event',
      );
    case 'POLL':
      return (
        icon: Icons.how_to_vote_outlined,
        color: ModuleColors.polls,
        label: 'Poll',
      );
    case 'VISITOR':
      return (
        icon: Icons.person_pin_circle_outlined,
        color: ModuleColors.visitors,
        label: 'Visitor',
      );
    default:
      return (
        icon: Icons.notifications_none_rounded,
        color: AppColors.primary,
        label: 'Update',
      );
  }
}

/// "Today", "Yesterday", a weekday within the last week, else the date.
String _dayLabel(DateTime t) {
  final now = DateTime.now();
  // Compare calendar days in UTC so a DST shift can't turn 23h into 0 days.
  final days = DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime.utc(t.year, t.month, t.day)).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return DateFormat('EEEE').format(t);
  return DateFormat(t.year == now.year ? 'd MMMM' : 'd MMMM yyyy').format(t);
}

/// "Just now" / "12m ago" / "3h ago" for recent ones, else the clock time
/// (the day label above already says which day).
String _timeLabel(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  final sameDay =
      t.year == now.year && t.month == now.month && t.day == now.day;
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (sameDay && diff.inHours < 12) return '${diff.inHours}h ago';
  return DateFormat('h:mm a').format(t);
}

// Same pill as the User Management list.
Widget _pill(String label, Color color) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 150),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}
