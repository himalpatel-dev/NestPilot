import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import 'package:intl/intl.dart';

class VisitorReportScreen extends StatefulWidget {
  const VisitorReportScreen({super.key});

  @override
  State<VisitorReportScreen> createState() => _VisitorReportScreenState();
}

class _VisitorReportScreenState extends State<VisitorReportScreen> {
  final CommunityService _service = CommunityService();
  List<dynamic> _allVisitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    try {
      final data = await _service.getAllSocietyVisitors();
      setState(() {
        _allVisitors = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Logs'),
        actions: [
          IconButton(onPressed: _fetchReport, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allVisitors.isEmpty
          ? const Center(child: Text('No visitor records found'))
          : ListView.builder(
              itemCount: _allVisitors.length,
              itemBuilder: (context, index) {
                final log = _allVisitors[index];
                final visitor = log['Visitor'];
                final house = log['House'];
                final approver = log['approver'];

                final entryTime = log['entry_time'] != null
                    ? DateFormat(
                        'MMM dd, hh:mm a',
                      ).format(DateTime.parse(log['entry_time']))
                    : 'Not entered';
                final exitTime = log['exit_time'] != null
                    ? DateFormat(
                        'hh:mm a',
                      ).format(DateTime.parse(log['exit_time']))
                    : 'N/A';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(
                          log['status'],
                        ).withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: _getStatusColor(log['status']),
                        ),
                      ),
                      title: Text(
                        visitor?['name'] ?? 'Unknown Visitor',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Flat: ${house?['house_no'] ?? 'N/A'} • Status: ${log['status'].toString().replaceAll('_', ' ')}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Mobile',
                                visitor?['mobile'] ?? 'N/A',
                              ),
                              _buildDetailRow('Entry Time', entryTime),
                              _buildDetailRow('Exit Time', exitTime),
                              if (approver != null)
                                _buildDetailRow(
                                  'Approved By',
                                  approver['full_name'],
                                ),
                              if (log['purpose'] != null)
                                _buildDetailRow('Purpose', log['purpose']),
                              if (log['vehicle_number'] != null)
                                _buildDetailRow(
                                  'Vehicle',
                                  log['vehicle_number'],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
