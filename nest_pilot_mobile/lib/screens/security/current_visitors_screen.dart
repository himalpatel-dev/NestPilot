import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import 'package:intl/intl.dart';

class CurrentVisitorsScreen extends StatefulWidget {
  const CurrentVisitorsScreen({super.key});

  @override
  State<CurrentVisitorsScreen> createState() => _CurrentVisitorsScreenState();
}

class _CurrentVisitorsScreenState extends State<CurrentVisitorsScreen> {
  final CommunityService _service = CommunityService();
  List<dynamic> _insideVisitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInside();
  }

  Future<void> _fetchInside() async {
    try {
      final data = await _service.getInsideVisitors();
      setState(() {
        _insideVisitors = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markExit(int logId) async {
    try {
      // Assuming logExit takes a map with logId and gate
      await _service.logVisitorExit({
        'visitor_log_id': logId,
        'gate': 'Main Gate',
      });
      _fetchInside();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Visitor exited')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitors Inside')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insideVisitors.isEmpty
          ? const Center(child: Text('No visitors currently inside'))
          : ListView.builder(
              itemCount: _insideVisitors.length,
              itemBuilder: (context, index) {
                final log = _insideVisitors[index];
                final visitor = log['Visitor'];
                final house = log['House'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(visitor['name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('House: ${house?['house_no'] ?? 'N/A'}'),
                        Text(
                          'Entered: ${DateFormat('hh:mm a').format(DateTime.parse(log['entry_time']))}',
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _markExit(log['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Exit'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
