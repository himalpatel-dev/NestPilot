import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/nest_loader.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:nest_pilot_mobile/services/socket_service.dart';
import 'package:nest_pilot_mobile/services/permission_service.dart';
import 'package:nest_pilot_mobile/config/modules.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_field_card.dart';
import '../../../widgets/module_page_header.dart';

class VisitorManagementScreen extends StatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  State<VisitorManagementScreen> createState() =>
      _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  final CommunityService _service = CommunityService();
  List<VisitorLog> _logs = [];
  bool _isLoading = true;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _purposeController = TextEditingController();
  String _selectedType = 'GUEST';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _setupSocket();
  }

  @override
  void dispose() {
    SocketService().off('visitor_update');
    _nameController.dispose();
    _mobileController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _setupSocket() {
    SocketService().on('visitor_update', (data) {
      if (mounted) {
        _fetchLogs(); // Refresh list to get latest status and details
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Visitor list updated')));
      }
    });
  }

  Future<void> _fetchLogs() async {
    try {
      final logs = await _service.getMyVisitors();
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
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _inviteGuest() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'type': _selectedType,
        'purpose': _purposeController.text,
      };

      final result = await _service.inviteGuest(data);

      // Show Pass Code
      if (mounted) {
        Navigator.pop(context); // close the invite sheet
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Guest Invited!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this code with your guest:'),
                const SizedBox(height: 10),
                Text(
                  result['pass_code'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _nameController.clear();
        _mobileController.clear();
        _purposeController.clear();
        _fetchLogs(); // Refresh list
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _respondToVisitor(int logId, String status) async {
    try {
      await _service.respondToVisitor(logId, status);
      _fetchLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visitor ${status.toLowerCase()} successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'INSIDE':
        return Colors.green;
      case 'WAITING_APPROVAL':
        return Colors.orange;
      case 'DENIED':
        return Colors.red;
      case 'EXITED':
        return Colors.grey;
      case 'PRE_APPROVED':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // One shared list screen: anyone with view (or manage) sees the history;
    // the floating add button + approve/deny actions need manage.
    final canManage = PermissionService().canManage(ModuleCodes.visitors);
    final inside = _logs.where((l) => l.status == 'INSIDE').length;
    final waiting = _logs.where((l) => l.status == 'WAITING_APPROVAL').length;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          ModulePageHeader(
            title: 'Visitors',
            description: 'Invite guests & view history',
            icon: Icons.person_pin_circle_outlined,
            iconColor: ModuleColors.visitors,
            stats: [
              ModuleHeaderStat('$inside', 'INSIDE'),
              ModuleHeaderStat('$waiting', 'WAITING'),
              ModuleHeaderStat('${_logs.length}', 'TOTAL'),
            ],
          ),
          Expanded(child: _buildHistoryList(canManage: canManage)),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: _openInviteSheet,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.person_add_rounded),
            )
          : null,
    );
  }

  Widget _buildHistoryList({required bool canManage}) {
    if (_isLoading) return const Center(child: NestLoader());
    if (_logs.isEmpty)
      return const Center(child: Text('No visitor history found'));

    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final isWaiting = log.status == 'WAITING_APPROVAL';

        return Card(
          elevation: isWaiting ? 4 : 1,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(log.status).withOpacity(0.1),
              child: Icon(Icons.person, color: _getStatusColor(log.status)),
            ),
            title: Text(
              log.visitor?.name ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(log.visitor?.type ?? ''),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(log.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.status.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(log.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (log.entryTime != null)
                  Text(
                    'Entry: ${DateFormat('MMM dd, hh:mm a').format(DateTime.parse(log.entryTime!))}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: isWaiting && canManage
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () => _respondToVisitor(log.id, 'APPROVED'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _respondToVisitor(log.id, 'DENIED'),
                      ),
                    ],
                  )
                : log.passCode != null && log.status == 'PRE_APPROVED'
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.passCode!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  void _openInviteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (sheetCtx, setSheetState) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Invite Guest',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Guest Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.length < 10 ? 'Invalid mobile' : null,
                  ),
                  const SizedBox(height: 16),
                  AppFieldCard(
                    icon: Icons.badge_rounded,
                    label: 'Visitor Type',
                    field: AppCardDropdown<String>(
                      value: _selectedType,
                      items: const ['GUEST', 'DELIVERY', 'CAB', 'SERVICE'],
                      itemLabel: (t) => t,
                      onChanged: (v) => setSheetState(() => _selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _inviteGuest,
                      child: const Text('Generate Pass Code'),
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
