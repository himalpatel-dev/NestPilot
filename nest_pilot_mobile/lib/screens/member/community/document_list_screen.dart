import 'package:flutter/material.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:nest_pilot_mobile/services/auth_service.dart';
import 'package:nest_pilot_mobile/config/roles.dart';
import 'package:nest_pilot_mobile/config/app_config.dart';
import '../../../models/user_model.dart';
import '../../secretary/document_upload_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final CommunityService _service = CommunityService();
  final AuthService _authService = AuthService();
  List<Document> _documents = [];
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
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      final docs = await _service.getDocuments();
      if (mounted) {
        setState(() {
          _documents = docs;
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

  Future<void> _deleteDocument(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteDocument(id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document deleted')));
      _fetchDocuments();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openDocument(String url) async {
    final fullUrl = url.startsWith('http') ? url : '${AppConfig.baseUrl}$url';
    final uri = Uri.parse(fullUrl);

    // Check if we can launch. On Android/iOS this opens the browser or PDF viewer.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch document: $fullUrl')),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'BY_LAWS':
        return Icons.gavel;
      case 'MEETING_MINUTES':
        return Icons.groups;
      case 'AUDIT_REPORT':
        return Icons.pie_chart;
      case 'FORM':
        return Icons.assignment;
      default:
        return Icons.description;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'BY_LAWS':
        return Colors.brown;
      case 'MEETING_MINUTES':
        return Colors.blue;
      case 'AUDIT_REPORT':
        return Colors.green;
      case 'FORM':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser?.role == UserRoles.societyAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? const Center(child: Text('No documents found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => _openDocument(doc.fileUrl),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                doc.category,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(doc.category),
                              color: _getCategoryColor(doc.category),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        doc.category.replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    if (doc.isPrivate) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.lock,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doc.createdAt.split('T')[0],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAdmin)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteDocument(doc.id),
                            )
                          else
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentUploadScreen(),
                  ),
                );
                if (res == true) _fetchDocuments();
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
    );
  }
}
