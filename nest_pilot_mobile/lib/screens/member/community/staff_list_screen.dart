import 'package:flutter/material.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:intl/intl.dart';

import 'package:nest_pilot_mobile/services/auth_service.dart';
import 'package:nest_pilot_mobile/config/roles.dart';
import '../../../models/user_model.dart';
import '../../secretary/staff_add_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final CommunityService _service = CommunityService();
  final AuthService _authService = AuthService();
  List<ServiceStaff> _staff = [];
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = await _authService.getMe();
    if (mounted) setState(() => _currentUser = user);
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    try {
      final staff = await _service.getAllStaff();
      if (mounted) {
        setState(() {
          _staff = staff;
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

  void _showAttendance(ServiceStaff staff) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          StaffAttendanceSheet(staffId: staff.id, staffName: staff.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser?.role == UserRoles.societyAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Help')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
          ? const Center(child: Text('No daily help added yet'))
          : ListView.builder(
              itemCount: _staff.length,
              itemBuilder: (context, index) {
                final s = _staff[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: s.profileImage != null
                          ? NetworkImage(s.profileImage!)
                          : null,
                      child: s.profileImage == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(s.name),
                    subtitle: Text('${s.role} • ${s.mobile}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _showAttendance(s),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StaffAddScreen(),
                  ),
                );
                if (res == true) _fetchStaff();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class StaffAttendanceSheet extends StatefulWidget {
  final int staffId;
  final String staffName;

  const StaffAttendanceSheet({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<StaffAttendanceSheet> createState() => _StaffAttendanceSheetState();
}

class _StaffAttendanceSheetState extends State<StaffAttendanceSheet> {
  final CommunityService _service = CommunityService();
  List<StaffAttendance> _attendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      final data = await _service.getStaffAttendance(widget.staffId);
      if (mounted) {
        setState(() {
          _attendance = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAttendance(String type) async {
    try {
      await _service.markStaffAttendance(widget.staffId, type);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Marked $type successfully')));
        _fetchAttendance();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance: ${widget.staffName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _markAttendance('IN'),
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Mark Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _markAttendance('OUT'),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Mark Exit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Text(
            'History',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendance.isEmpty
                ? const Center(child: Text('No attendance records'))
                : ListView.builder(
                    itemCount: _attendance.length,
                    itemBuilder: (context, index) {
                      final a = _attendance[index];
                      return ListTile(
                        title: Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(DateTime.parse(a.date)),
                        ),
                        subtitle: Text(
                          'In: ${a.inTime != null ? DateFormat('hh:mm a').format(DateTime.parse(a.inTime!)) : '-'}  '
                          'Out: ${a.outTime != null ? DateFormat('hh:mm a').format(DateTime.parse(a.outTime!)) : '-'}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
