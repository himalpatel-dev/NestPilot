import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notice_complaint.dart';
import '../../models/user_model.dart';
import '../../config/roles.dart';
import '../../services/notice_complaint_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_text_field.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint complaint;
  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ComplaintService _complaintService = ComplaintService();
  final AuthService _authService = AuthService();

  bool _isSubmitting = false;
  UserModel? _currentUser;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.complaint.status;
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getMe();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final success = await _complaintService.addComment(
        widget.complaint.id,
        _commentController.text,
      );
      if (success && mounted) {
        _commentController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment added')));
        // TODO: Refresh comments logic would go here
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final success = await _complaintService.updateStatus(
        widget.complaint.id,
        newStatus,
      );
      if (success && mounted) {
        setState(() => _currentStatus = newStatus);
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Update Status'),
          children: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED'].map((
            status,
          ) {
            return SimpleDialogOption(
              onPressed: () => _updateStatus(status),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status == _currentStatus
                        ? Colors.blue
                        : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser?.role == UserRoles.societyAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Detail')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.complaint.category,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        DateFormat(
                          'dd MMM yyyy',
                        ).format(widget.complaint.createdAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      Text(
                        _currentStatus,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed: _showStatusDialog,
                          tooltip: 'Edit Status',
                        ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    widget.complaint.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.complaint.imagePath != null) ...[
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.complaint.imagePath!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text(
                    'Comments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (widget.complaint.comments.isEmpty)
                    const Text(
                      'No comments yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ...widget.complaint.comments.map((c) => _buildCommentItem(c)),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(ComplaintComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM, hh:mm a').format(comment.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.message),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _commentController,
              label: 'Add a comment...',
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _isSubmitting ? null : _addComment,
            icon: _isSubmitting
                ? const CircularProgressIndicator()
                : const Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
