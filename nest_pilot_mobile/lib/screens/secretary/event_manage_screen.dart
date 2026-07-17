import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/module_page_header.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_form_sheet.dart';
import '../../widgets/glare_button.dart';
import 'event_detail_screen.dart';

class EventManageScreen extends StatefulWidget {
  const EventManageScreen({super.key});

  @override
  State<EventManageScreen> createState() => _EventManageScreenState();
}

class _EventManageScreenState extends State<EventManageScreen> {
  final EventService _service = EventService();
  final TextEditingController _searchController = TextEditingController();
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  List<EventModel> get _filteredEvents {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _events;
    return _events
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.location.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final events = await _service.getEvents();
      if (mounted)
        setState(() {
          _events = eventsInDisplayOrder(events);
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  void _openCreateSheet() {
    showAppFormSheet(
      context: context,
      builder: (ctx) => _CreateEventSheet(
        onCreated: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService().canManage(ModuleCodes.events);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_isLoading)
              const SliverFillRemaining(child: NestLoader())
            else if (_error != null)
              SliverFillRemaining(child: _buildError())
            else if (_filteredEvents.isEmpty)
              SliverFillRemaining(child: _buildEmpty(canCreate: canManage))
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildCard(_filteredEvents[i]),
                    childCount: _filteredEvents.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      // Creating an event is a manage-only action — the list itself is
      // shared with view-only roles.
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: _openCreateSheet,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final upcoming = _events.where((e) => e.isUpcoming(now)).length;
    final thisMonth = _events
        .where(
          (e) => e.eventDate.year == now.year && e.eventDate.month == now.month,
        )
        .length;

    return ModulePageHeader(
      title: 'Events',
      description: 'Celebrations & community programmes',
      icon: Icons.event_outlined,
      iconColor: ModuleColors.events,
      stats: [
        ModuleHeaderStat('$upcoming', 'UPCOMING'),
        ModuleHeaderStat('$thisMonth', 'THIS MONTH'),
        ModuleHeaderStat('${_events.length}', 'TOTAL'),
      ],
      showSearch: true,
      searchHint: 'Search events...',
      searchController: _searchController,
      onSearchChanged: (v) => setState(() => _query = v),
    );
  }

  Widget _buildCard(EventModel event) {
    final date = DateFormat('EEE, dd MMM yyyy').format(event.eventDate);
    final timeStr = event.endTime != null
        ? '${event.startTime} – ${event.endTime}'
        : event.startTime;
    final typeColor = _typeColor(event.eventType);
    final statusChips = _statusChips(event);

    return GestureDetector(
      onTap: () async {
        // Detail pops `true` when it deleted the event — reload so the row it
        // just removed doesn't linger in the list. An RSVP reports itself via
        // onChanged instead, since it leaves the row in place.
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event, onChanged: _load),
          ),
        );
        if (deleted == true) _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon square
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.event_outlined, color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            event.eventType,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      // Bottom-aligned so the chips line up with the last meta
                      // line rather than floating against the date.
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const Text(
                                    '  ·  ',
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      event.location,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Bottom-right, under the type badge. Non-flex, so the
                        // chips keep their intrinsic width and the meta lines
                        // ellipsize into whatever is left.
                        if (statusChips.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Wrap(spacing: 6, children: statusChips),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                children: [
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Status chips for a card. A plain future event gets none — the date line
  /// already says all there is to say, so a chip on every card would be noise.
  List<Widget> _statusChips(EventModel event) {
    final phase = event.phase();
    final chips = <Widget>[];

    switch (phase) {
      case EventPhase.live:
        chips.add(_chip('LIVE NOW', AppColors.accentGreen));
      case EventPhase.over:
        chips.add(_chip('OVER', AppColors.textMuted));
      case EventPhase.today:
        chips.add(_chip('TODAY', AppColors.accentAmber));
      case EventPhase.upcoming:
        break;
    }

    // Capacity stops mattering once the event is done.
    if (event.isFull && phase != EventPhase.over) {
      chips.add(_chip('FULL', AppColors.accentRed));
    }

    return chips;
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'MEETING':
        return AppColors.accentBlue;
      case 'SOCIAL':
        return AppColors.accentPurple;
      case 'CULTURAL':
        return AppColors.accentPink;
      case 'SPORTS':
        return AppColors.accentGreen;
      case 'MAINTENANCE':
        return AppColors.accentAmber;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.accentRed,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty({required bool canCreate}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_outlined, color: AppColors.border, size: 56),
          const SizedBox(height: 12),
          const Text(
            'No events yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pull down to refresh',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Create event bottom sheet ────────────────────────────────────────────────

class _CreateEventSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateEventSheet({required this.onCreated});

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _eventType = 'MEETING';
  bool _isLoading = false;

  // Inline validation / error state — modal sheets hide snackbars behind them,
  // so date/time and API errors are surfaced in the sheet instead.
  bool _dateErr = false;
  bool _timeErr = false;
  String? _apiError;

  final _types = [
    'MEETING',
    'SOCIAL',
    'CULTURAL',
    'SPORTS',
    'MAINTENANCE',
    'OTHER',
  ];

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: appPickerTheme,
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: appPickerTheme,
    );
    if (picked != null)
      setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() {
      _dateErr = _eventDate == null;
      _timeErr = _startTime == null;
      _apiError = null;
    });
    if (!formOk || _eventDate == null || _startTime == null) return;

    setState(() => _isLoading = true);
    try {
      await EventService().createEvent(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        eventDate: DateFormat('yyyy-MM-dd').format(_eventDate!),
        startTime: _fmt(_startTime!),
        endTime: _endTime != null ? _fmt(_endTime!) : null,
        location: _locationCtrl.text.trim(),
        eventType: _eventType,
        maxAttendees: _maxCtrl.text.trim().isNotEmpty
            ? int.tryParse(_maxCtrl.text.trim())
            : null,
      );
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
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  String _typeLabel(String t) =>
      t.isEmpty ? t : '${t[0]}${t.substring(1).toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      accentColor: ModuleColors.events,
      icon: Icons.event_rounded,
      title: 'New Event',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader('Event Details'),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.title_rounded,
              label: 'Title',
              field: AppBorderlessField(
                controller: _titleCtrl,
                hint: 'e.g. Annual General Meeting',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.description_outlined,
              label: 'Description',
              iconAlignment: CrossAxisAlignment.start,
              field: AppBorderlessField(
                controller: _descCtrl,
                hint: 'Optional details about the event…',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.category_outlined,
              label: 'Event Type',
              field: AppCardDropdown<String>(
                value: _eventType,
                items: _types,
                itemLabel: _typeLabel,
                onChanged: (v) => setState(() => _eventType = v!),
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.location_on_outlined,
              label: 'Location',
              field: AppBorderlessField(
                controller: _locationCtrl,
                hint: 'e.g. Community Hall',
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Location is required'
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            const AppSectionHeader('Schedule'),
            const SizedBox(height: 14),
            AppPickerCard(
              icon: Icons.calendar_month_rounded,
              label: 'Date',
              value: _eventDate != null
                  ? DateFormat('EEE, d MMM yyyy').format(_eventDate!)
                  : null,
              hint: 'Select event date',
              error: _dateErr,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppPickerCard(
                    icon: Icons.access_time_rounded,
                    label: 'Start',
                    value: _startTime?.format(context),
                    hint: 'Start time',
                    error: _timeErr,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPickerCard(
                    icon: Icons.access_time_outlined,
                    label: 'End',
                    value: _endTime?.format(context),
                    hint: 'Optional',
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.people_outline_rounded,
              label: 'Max Attendees',
              field: AppBorderlessField(
                controller: _maxCtrl,
                hint: 'Optional — blank for unlimited',
                keyboardType: TextInputType.number,
              ),
            ),
            if (_apiError != null) ...[
              const SizedBox(height: 18),
              AppSheetErrorBanner(_apiError!),
            ],
            const SizedBox(height: 26),
            GlarePrimaryButton(
              text: 'Create Event',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
