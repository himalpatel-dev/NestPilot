import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notice_complaint_service.dart';
import '../../models/notice_complaint.dart';
import '../../widgets/status_widgets.dart';
import 'notice_detail_screen.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final NoticeService _noticeService = NoticeService();
  List<Notice> _notices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notices = await _noticeService.getNotices();
      setState(() {
        _notices = notices;
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
      appBar: AppBar(title: const Text('Notices')),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
          ? ErrorWidgetView(message: _error!, onRetry: _fetchNotices)
          : _notices.isEmpty
          ? const EmptyWidget(
              message: 'No notices published yet',
              icon: Icons.campaign_outlined,
            )
          : RefreshIndicator(
              onRefresh: _fetchNotices,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notices.length,
                itemBuilder: (context, index) {
                  final notice = _notices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        notice.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(notice.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NoticeDetailScreen(notice: notice),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
