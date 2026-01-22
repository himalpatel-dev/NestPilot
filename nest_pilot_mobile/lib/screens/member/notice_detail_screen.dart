import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notice_complaint.dart';

class NoticeDetailScreen extends StatelessWidget {
  final Notice notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notice Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(notice.createdAt),
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),
            Text(
              notice.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (notice.attachmentUrl != null) ...[
              const SizedBox(height: 32),
              const Text(
                'Attachment',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('View Attachment'),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    // Implement download/open logic
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
