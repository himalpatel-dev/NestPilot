import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_field_card.dart';
import 'event_detail_screen.dart';

class EventManageScreen extends StatefulWidget {
  const EventManageScreen({super.key});

  @override
  State<EventManageScreen> createState() => _EventManageScreenState();
}

class _EventManageScreenState extends State<EventManageScreen> {
  final EventService _service = EventService();
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final events = await _service.getEvents();
      if (mounted) setState(() { _events = events; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CreateEventSheet(
        onCreated: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  Future<void> _deleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
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
                    Icon(Icons.cancel_outlined, color: AppColors.white, size: 22),
                    SizedBox(width: 10),
                    Text('Cancel Event', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Cancel "${event.title}"? This cannot be undone.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                        ),
                        child: const Text('Keep', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Cancel Event', style: TextStyle(fontWeight: FontWeight.w700)),
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
    try {
      await _service.deleteEvent(event.id.toString());
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = PermissionService();
    final canCreate = perms.canCreate(ModuleCodes.events);
    final canDelete = perms.canDelete(ModuleCodes.events);
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
            SliverToBoxAdapter(
              child: AppPageHeader(
                icon: const Icon(Icons.event_outlined, color: AppColors.white, size: 28),
                title: 'Events',
                subtitle: _isLoading
                    ? 'Loading events…'
                    : '${_events.length} event${_events.length == 1 ? '' : 's'}',
                trailing: canCreate
                    ? GestureDetector(
                        onTap: _openCreateSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: AppColors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Add', style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: NestLoader())
            else if (_error != null)
              SliverFillRemaining(child: _buildError())
            else if (_events.isEmpty)
              SliverFillRemaining(child: _buildEmpty(canCreate: canCreate))
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildCard(_events[i], canDelete),
                    childCount: _events.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(EventModel event, bool canDelete) {
    final date = DateFormat('EEE, dd MMM yyyy').format(event.eventDate);
    final timeStr = event.endTime != null
        ? '${event.startTime} – ${event.endTime}'
        : event.startTime;
    final typeColor = _typeColor(event.eventType);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            event.eventType,
                            style: TextStyle(color: typeColor, fontSize: 10.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(date, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(timeStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                        const Text('  ·  ', style: TextStyle(color: AppColors.textMuted)),
                        const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            event.location,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                children: [
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
                  if (canDelete) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _deleteEvent(event),
                      child: const Icon(Icons.cancel_outlined, color: AppColors.accentRed, size: 18),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'MEETING':     return AppColors.accentBlue;
      case 'SOCIAL':      return AppColors.accentPurple;
      case 'CULTURAL':    return AppColors.accentPink;
      case 'SPORTS':      return AppColors.accentGreen;
      case 'MAINTENANCE': return AppColors.accentAmber;
      default:            return AppColors.primary;
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.accentRed, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Text('Retry', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
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
          const Text('No events yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Pull down to refresh', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          if (canCreate) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _openCreateSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                child: const Text('+ Create Event', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
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

  final _types = ['MEETING', 'SOCIAL', 'CULTURAL', 'SPORTS', 'MAINTENANCE', 'OTHER'];

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select event date')));
      return;
    }
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start time')));
      return;
    }
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
        maxAttendees: _maxCtrl.text.trim().isNotEmpty ? int.tryParse(_maxCtrl.text.trim()) : null,
      );
      widget.onCreated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('New Event', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: _dec('Title', Icons.title_rounded),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: _dec('Description (optional)', Icons.description_outlined),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: _dec('Location', Icons.location_on_outlined),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppCardDropdown<String>(
                        value: _eventType,
                        hintText: 'Event Type',
                        items: _types,
                        itemLabel: (t) => t,
                        onChanged: (v) => setState(() => _eventType = v!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _PickerTile(icon: Icons.calendar_today_rounded, label: _eventDate != null ? DateFormat('d MMM yyyy').format(_eventDate!) : 'Event Date', onTap: _pickDate)),
                  const SizedBox(width: 10),
                  Expanded(child: _PickerTile(icon: Icons.access_time_rounded, label: _startTime != null ? _fmt(_startTime!) : 'Start Time', onTap: () => _pickTime(true))),
                  const SizedBox(width: 10),
                  Expanded(child: _PickerTile(icon: Icons.access_time_outlined, label: _endTime != null ? _fmt(_endTime!) : 'End Time', onTap: () => _pickTime(false))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxCtrl,
                decoration: _dec('Max Attendees (optional)', Icons.people_outlined),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
                      : const Text('Create Event', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
