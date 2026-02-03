import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../widgets/status_widgets.dart';

class PendingMembersScreen extends StatefulWidget {
  const PendingMembersScreen({super.key});

  @override
  State<PendingMembersScreen> createState() => _PendingMembersScreenState();
}

class _PendingMembersScreenState extends State<PendingMembersScreen> {
  final AdminService _adminService = AdminService();
  List<UserModel> _pendingUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  Future<void> _fetchPendingUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _adminService.getPendingUsers();
      setState(() {
        _pendingUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApproval(String userId, bool approve) async {
    try {
      final success = approve
          ? await _adminService.approveUser(userId)
          : await _adminService.rejectUser(userId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'User approved' : 'User rejected')),
        );
        _fetchPendingUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
          ? ErrorWidgetView(message: _error!, onRetry: _fetchPendingUsers)
          : _pendingUsers.isEmpty
          ? const EmptyWidget(
              message: 'No pending approvals',
              icon: Icons.group_outlined,
            )
          : RefreshIndicator(
              onRefresh: _fetchPendingUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingUsers.length,
                itemBuilder: (context, index) {
                  final user = _pendingUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${user.mobile}\nFlat: ${user.flatNumber ?? 'N/A'}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () => _handleApproval(user.id, true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _handleApproval(user.id, false),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
