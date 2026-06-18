import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_field_card.dart';


class EventManageScreen extends StatefulWidget {
  const EventManageScreen({super.key});

  @override
  State<EventManageScreen> createState() => _EventManageScreenState();
}

class _EventManageScreenState extends State<EventManageScreen> {
  final EventService _service = EventService();
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final events = await _service.getEvents();
      if (mounted) setState(() => _events = events);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Cancel Event',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Cancel "${event.title}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Event', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteEvent(event.id.toString());
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = PermissionService();
    final canCreate = perms.canCreate(ModuleCodes.events);
    final canDelete = perms.canDelete(ModuleCodes.events);
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Events',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: _openCreateSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+ Add Event',
                    style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _events.isEmpty
              ? _buildEmpty(canCreate: canCreate)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.white,
                  backgroundColor: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _EventCard(
                      event: _events[i],
                      onDelete: canDelete ? () => _deleteEvent(_events[i]) : null,
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty({required bool canCreate}) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'No events yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            if (canCreate) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openCreateSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      );
}

// ── Event card ──────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onDelete;

  const _EventCard({required this.event, this.onDelete});

  Color get _typeColor {
    switch (event.eventType) {
      case 'MEETING':    return AppColors.accentBlue;
      case 'SOCIAL':     return AppColors.accentPurple;
      case 'CULTURAL':   return AppColors.accentPink;
      case 'SPORTS':     return AppColors.accentGreen;
      case 'MAINTENANCE': return AppColors.accentAmber;
      default:           return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(event.eventDate);
    final timeStr = event.endTime != null
        ? '${event.startTime} – ${event.endTime}'
        : event.startTime;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event.eventType,
                  style: TextStyle(
                    color: _typeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.cancel_outlined, color: AppColors.accentRed, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.description!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          _InfoRow(Icons.calendar_today_rounded, dateStr),
          const SizedBox(height: 4),
          _InfoRow(Icons.access_time_rounded, timeStr),
          const SizedBox(height: 4),
          _InfoRow(Icons.location_on_outlined, event.location),
          if (event.maxAttendees != null) ...[
            const SizedBox(height: 4),
            _InfoRow(
              Icons.people_outlined,
              '${event.attendeeCount} / ${event.maxAttendees} registered',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event date')),
      );
      return;
    }
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start time')),
      );
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
        maxAttendees: _maxCtrl.text.trim().isNotEmpty
            ? int.tryParse(_maxCtrl.text.trim())
            : null,
      );
      widget.onCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

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
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'New Event',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
              // Event type dropdown
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined,
                        color: AppColors.primary, size: 20),
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
              // Date + time row
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.calendar_today_rounded,
                      label: _eventDate != null
                          ? DateFormat('d MMM yyyy').format(_eventDate!)
                          : 'Event Date',
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.access_time_rounded,
                      label: _startTime != null ? _fmt(_startTime!) : 'Start Time',
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.access_time_outlined,
                      label: _endTime != null ? _fmt(_endTime!) : 'End Time',
                      onTap: () => _pickTime(false),
                    ),
                  ),
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
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                        )
                      : const Text(
                          'Create Event',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
