import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../config/roles.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'super_admin/society_create_screen.dart';
import 'super_admin/stubs.dart';
import 'secretary/pending_members_screen.dart';
import 'secretary/notice_create_screen.dart';
import 'secretary/bill_create_screen.dart';
import 'secretary/bills_manage_screen.dart';
import 'secretary/payment_mark_screen.dart';
import 'secretary/amenity_management_screen.dart';
import 'secretary/vehicle_management_screen.dart';
import 'secretary/member_list_screen.dart';
import 'member/notice_list_screen.dart';
import 'security/security_dashboard_screen.dart';
import 'security/current_visitors_screen.dart';
import 'common/visitor_report_screen.dart';
import 'member/complaint_list_screen.dart';
import 'member/bills_list_screen.dart';
import 'member/ledger_screen.dart';
import 'member/community/visitor_management_screen.dart';
import 'member/community/vehicle_list_screen.dart';
import 'member/community/amenity_booking_screen.dart';
import 'member/community/staff_list_screen.dart';
import 'member/community/poll_list_screen.dart';
import 'member/community/document_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NestPilot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = await AuthService().getMe();
          if (user != null && mounted) {
            setState(() {
              // In a real app, we'd update the parent or use a provider.
              // For MVP, we'll just refresh the current state if possible.
              // Since 'user' is passed in constructor, we might need to
              // handle this differently if we want it to persist.
            });
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (widget.user.role == UserRoles.superAdmin)
                _buildSuperAdminMenu(),
              if (widget.user.role == UserRoles.societyAdmin)
                _buildSocietyAdminMenu(),
              if (widget.user.role == UserRoles.member) _buildMemberMenu(),
              if (widget.user.role == UserRoles.securityGuard)
                _buildSecurityGuardMenu(),
              if (widget.user.role != UserRoles.superAdmin &&
                  widget.user.role != UserRoles.societyAdmin &&
                  widget.user.role != UserRoles.member &&
                  widget.user.role != UserRoles.securityGuard)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No actions available for role: ${widget.user.role}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    debugPrint('Building Dashboard for role: ${widget.user.role}');
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                widget.user.fullName.isNotEmpty
                    ? widget.user.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.user.role,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    widget.user.mobile,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperAdminMenu() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMenuCard(
          'Create Society',
          Icons.business,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SocietyCreateScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Add Building',
          Icons.apartment,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BuildingCreateScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Add Flat',
          Icons.door_front_door,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FlatCreateScreen()),
          ),
        ),
        _buildMenuCard(
          'Flats List',
          Icons.list_alt,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FlatsListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSocietyAdminMenu() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMenuCard(
          'Pending Members',
          Icons.person_add_alt,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingMembersScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Residents',
          Icons.contacts,
          Colors.indigo,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MemberListScreen()),
          ),
        ),
        _buildMenuCard(
          'Create Notice',
          Icons.campaign,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoticeCreateScreen()),
          ),
        ),
        _buildMenuCard(
          'Create Bill',
          Icons.add_card,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BillCreateScreen()),
          ),
        ),
        _buildMenuCard(
          'Manage Bills',
          Icons.receipt_long,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BillsManageScreen()),
          ),
        ),
        _buildMenuCard(
          'Record Payment',
          Icons.payments,
          Colors.teal,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentMarkScreen()),
          ),
        ),
        _buildMenuCard(
          'Complaints',
          Icons.report_problem,
          Colors.red,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ComplaintListScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Amenities',
          Icons.pool,
          Colors.cyan,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AmenityManagementScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Polls',
          Icons.poll,
          Colors.orangeAccent,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PollListScreen()),
          ),
        ),
        _buildMenuCard(
          'Visitor Logs',
          Icons.group_work,
          Colors.deepPurple,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VisitorReportScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Vehicles',
          Icons.directions_car,
          Colors.blueGrey,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VehicleManagementScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Documents',
          Icons.folder,
          Colors.amber,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DocumentListScreen()),
          ),
        ),
        _buildMenuCard(
          'Daily Help',
          Icons.cleaning_services,
          Colors.brown,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StaffListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberMenu() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMenuCard(
          'Notices',
          Icons.campaign,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoticeListScreen()),
          ),
        ),
        _buildMenuCard(
          'Bills',
          Icons.receipt_long,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BillsListScreen()),
          ),
        ),
        _buildMenuCard(
          'Complaints',
          Icons.report_problem,
          Colors.red,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ComplaintListScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Ledger',
          Icons.account_balance_wallet,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LedgerScreen()),
          ),
        ),
        _buildMenuCard(
          'Visitors',
          Icons.group,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VisitorManagementScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Vehicles',
          Icons.directions_car,
          Colors.blueGrey,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VehicleListScreen()),
          ),
        ),
        _buildMenuCard(
          'Amenities',
          Icons.pool,
          Colors.cyan,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AmenityBookingScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Daily Help',
          Icons.cleaning_services,
          Colors.brown,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StaffListScreen()),
          ),
        ),
        _buildMenuCard(
          'Polls',
          Icons.poll,
          Colors.indigo,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PollListScreen()),
          ),
        ),
        _buildMenuCard(
          'Documents',
          Icons.folder,
          Colors.amber,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DocumentListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityGuardMenu() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMenuCard(
          'Visitor Entry',
          Icons.door_front_door,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecurityDashboardScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Visitor Logs',
          Icons.history,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VisitorReportScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Visitors Inside',
          Icons.group,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CurrentVisitorsScreen(),
            ),
          ),
        ),
        _buildMenuCard(
          'Daily Help',
          Icons.cleaning_services,
          Colors.brown,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StaffListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
