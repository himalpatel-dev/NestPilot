import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/modules.dart';
import '../../models/community_models.dart';
import '../../services/community_service.dart';
import '../../services/permission_service.dart';
import '../../services/session_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/module_page_header.dart';

/// Unified Visitor Hub & Log Screen for Members, Residents, and Admins.
/// Combines Guest Pass Invites, Approval Controls, and Historical Visitor Reports.
class VisitorManagementScreen extends StatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  State<VisitorManagementScreen> createState() =>
      _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();

  List<VisitorLog> _logs = [];
  bool _isLoading = true;
  String _query = '';
  String _selectedStatusFilter = 'ALL';

  // Form Controllers for Invite Sheet
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _purposeController = TextEditingController();
  String _selectedType = 'GUEST';

  final List<String> _statusFilters = [
    'ALL',
    'INSIDE',
    'WAITING',
    'PRE-APPROVED',
    'EXITED',
    'DENIED',
  ];

  List<VisitorLog> get _filteredLogs {
    final q = _query.trim().toLowerCase();
    return _logs.where((l) {
      final matchesQuery = q.isEmpty ||
          (l.visitor?.name ?? '').toLowerCase().contains(q) ||
          (l.visitor?.type ?? '').toLowerCase().contains(q) ||
          (l.purpose ?? '').toLowerCase().contains(q) ||
          (l.vehicleNumber ?? '').toLowerCase().contains(q);

      bool matchesStatus = true;
      switch (_selectedStatusFilter) {
        case 'INSIDE':
          matchesStatus = l.status == 'INSIDE';
          break;
        case 'WAITING':
          matchesStatus = l.status == 'WAITING_APPROVAL';
          break;
        case 'PRE-APPROVED':
          matchesStatus = l.status == 'PRE_APPROVED';
          break;
        case 'EXITED':
          matchesStatus = l.status == 'EXITED';
          break;
        case 'DENIED':
          matchesStatus = l.status == 'DENIED';
          break;
        default:
          matchesStatus = true;
      }

      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _setupSocket();
  }

  @override
  void dispose() {
    SocketService().off('visitor_update');
    _searchController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _setupSocket() {
    SocketService().on('visitor_update', (data) {
      if (mounted) {
        _fetchLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor updates received')),
        );
      }
    });
  }

  Future<void> _fetchLogs() async {
    try {
      final role = SessionService().currentUser?.role;
      final canManageGate = PermissionService().canManage(ModuleCodes.gateControl);
      final isStaffOrAdmin = role == 'SUPER_ADMIN' ||
          role == 'SOCIETY_ADMIN' ||
          canManageGate;

      List<VisitorLog> logs;

      // Society-wide logs are fetched for admins/secretaries or gate security roles.
      // Members get their own household's visitor logs.
      if (isStaffOrAdmin) {
        final rawData = await _service.getAllSocietyVisitors();
        logs = rawData.map((json) => VisitorLog.fromJson(json)).toList();
      } else {
        logs = await _service.getMyVisitors();
      }

      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading visitors: $e')));
      }
    }
  }

  Future<void> _inviteGuest() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'type': _selectedType,
        'purpose': _purposeController.text.trim(),
      };

      final result = await _service.inviteGuest(data);

      if (mounted) {
        Navigator.pop(context); // Close invite sheet
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppColors.accentGreen),
                SizedBox(width: 8),
                Text('Guest Invited!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share this 6-digit passcode with your guest to enter at the gate:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    result['pass_code'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        _nameController.clear();
        _mobileController.clear();
        _purposeController.clear();
        _fetchLogs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _respondToVisitor(int logId, String status) async {
    try {
      await _service.respondToVisitor(logId, status);
      _fetchLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visitor status updated to ${status.replaceAll('_', ' ')}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'INSIDE':
        return AppColors.accentGreen;
      case 'WAITING_APPROVAL':
        return AppColors.accentAmber;
      case 'DENIED':
        return AppColors.accentRed;
      case 'EXITED':
        return AppColors.textMuted;
      case 'PRE_APPROVED':
        return AppColors.accentBlue;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService().canManage(ModuleCodes.visitors);
    final insideCount = _logs.where((l) => l.status == 'INSIDE').length;
    final waitingCount =
        _logs.where((l) => l.status == 'WAITING_APPROVAL').length;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: RefreshIndicator(
        onRefresh: _fetchLogs,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: Column(
          children: [
            ModulePageHeader(
              title: 'Visitors Hub',
              description: 'Invite guests, approve gate entries & view history',
              icon: Icons.person_pin_circle_outlined,
              iconColor: ModuleColors.visitors,
              stats: [
                ModuleHeaderStat('$insideCount', 'INSIDE'),
                ModuleHeaderStat('$waitingCount', 'WAITING'),
                ModuleHeaderStat('${_logs.length}', 'TOTAL'),
              ],
              showSearch: true,
              searchHint: 'Search visitor, purpose, flat...',
              searchController: _searchController,
              onSearchChanged: (v) => setState(() => _query = v),
            ),
            // Horizontal Filter Chips
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statusFilters.length,
                itemBuilder: (context, index) {
                  final filter = _statusFilters[index];
                  final isSelected = _selectedStatusFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        filter.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      backgroundColor: AppColors.white,
                      selectedColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedStatusFilter = filter);
                      },
                    ),
                  );
                },
              ),
            ),
            Expanded(child: _buildLogList(canManage: canManage)),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openInviteSheet,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text(
                'Invite Guest',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildLogList({required bool canManage}) {
    if (_isLoading) return const Center(child: NestLoader());

    final logs = _filteredLogs;
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.person_pin_circle_outlined,
              size: 56,
              color: AppColors.border,
            ),
            SizedBox(height: 12),
            Text(
              'No visitor records found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Pull down to refresh or invite a new guest',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isWaiting = log.status == 'WAITING_APPROVAL';
        final name = log.visitor?.name ?? 'Unknown';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';
        final statusColor = _getStatusColor(log.status);

        String entryTimeFormatted = 'Not recorded';
        if (log.entryTime != null) {
          try {
            entryTimeFormatted = DateFormat(
              'MMM dd · hh:mm a',
            ).format(DateTime.parse(log.entryTime!));
          } catch (_) {}
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWaiting ? AppColors.accentAmber : AppColors.border,
              width: isWaiting ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(
              context,
            ).copyWith(dividerColor: AppColors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        log.status.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (log.visitor?.type != null &&
                        log.visitor!.type.isNotEmpty)
                      Text(
                        '· ${log.visitor!.type}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      '· $entryTimeFormatted',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: (isWaiting && canManage)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accentGreen,
                            size: 28,
                          ),
                          onPressed:
                              () => _respondToVisitor(log.id, 'APPROVED'),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            color: AppColors.accentRed,
                            size: 28,
                          ),
                          onPressed: () => _respondToVisitor(log.id, 'DENIED'),
                        ),
                      ],
                    )
                  : (log.passCode != null && log.status == 'PRE_APPROVED')
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.accentBlue.withValues(
                                alpha: 0.30,
                              ),
                            ),
                          ),
                          child: Text(
                            log.passCode!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppColors.accentBlue,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : null,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      if (log.visitor?.mobile != null)
                        _detailRow(
                          Icons.phone_outlined,
                          'Mobile',
                          log.visitor!.mobile,
                          AppColors.accentBlue,
                        ),
                      if (log.purpose != null && log.purpose!.isNotEmpty)
                        _detailRow(
                          Icons.notes_rounded,
                          'Purpose',
                          log.purpose!,
                          AppColors.accentAmber,
                        ),
                      if (log.vehicleNumber != null &&
                          log.vehicleNumber!.isNotEmpty)
                        _detailRow(
                          Icons.directions_car_outlined,
                          'Vehicle',
                          log.vehicleNumber!,
                          AppColors.primary,
                        ),
                      _detailRow(
                        Icons.login_rounded,
                        'Entry Time',
                        entryTimeFormatted,
                        AppColors.accentGreen,
                      ),
                      if (log.exitTime != null)
                        _detailRow(
                          Icons.logout_rounded,
                          'Exit Time',
                          DateFormat(
                            'MMM dd · hh:mm a',
                          ).format(DateTime.parse(log.exitTime!)),
                          AppColors.accentRed,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openInviteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (sheetCtx, setSheetState) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Invite Guest',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Guest Name',
                      hintText: 'Full name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      hintText: '10-digit mobile number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().length < 10)
                            ? 'Enter valid 10-digit mobile'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  AppFieldCard(
                    icon: Icons.badge_rounded,
                    label: 'Visitor Type',
                    field: AppCardDropdown<String>(
                      value: _selectedType,
                      items: const ['GUEST', 'DELIVERY', 'CAB', 'SERVICE'],
                      itemLabel: (t) => t,
                      onChanged: (v) =>
                          setSheetState(() => _selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose (Optional)',
                      hintText: 'e.g. Dinner, Package, Maintenance',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _inviteGuest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Generate Pass Code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
