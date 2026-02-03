import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../widgets/status_widgets.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final AdminService _adminService = AdminService();
  List<UserModel> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final members = await _adminService.getSocietyMembers();
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Residents Directory')),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
          ? ErrorWidgetView(message: _error!, onRetry: _fetchMembers)
          : _members.isEmpty
          ? const EmptyWidget(
              message: 'No members found',
              icon: Icons.group_off,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final user = _members[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(user.fullName[0].toUpperCase()),
                    ),
                    title: Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flat: ${user.flatNumber ?? 'N/A'}'),
                        const SizedBox(height: 2),
                        Text(
                          '${user.role.replaceAll('SOCIETY_', '').replaceAll('_', ' ')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {
                            // Launcher link
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
