import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/nest_loader.dart';
import '../../../widgets/app_field_card.dart';
import '../../../widgets/app_form_sheet.dart';
import '../../../widgets/glare_button.dart';
import '../../../widgets/module_page_header.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:nest_pilot_mobile/services/permission_service.dart';
import 'package:nest_pilot_mobile/config/modules.dart';
import 'package:nest_pilot_mobile/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();
  List<Document> _documents = [];
  bool _isLoading = true;
  String _query = '';

  List<Document> get _filteredDocuments {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _documents;
    return _documents
        .where(
          (d) =>
              d.title.toLowerCase().contains(q) ||
              d.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final perms = PermissionService();
    final canUpload = perms.canManage(ModuleCodes.documents);
    final canDelete = perms.canManage(ModuleCodes.documents);

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          ModulePageHeader(
            title: 'Documents',
            description: 'Society files & circulars',
            icon: Icons.folder_open_outlined,
            iconColor: ModuleColors.documents,
            stats: [ModuleHeaderStat('${_documents.length}', 'TOTAL')],
            showSearch: true,
            searchHint: 'Search documents...',
            searchController: _searchController,
            onSearchChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: NestLoader())
                : _filteredDocuments.isEmpty
                ? const Center(child: Text('No documents found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = _filteredDocuments[index];
                      final categoryColor = _getCategoryColor(doc.category);

                      return GestureDetector(
                        onTap: () => _openDocument(doc.fileUrl),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _getCategoryIcon(doc.category),
                                  color: categoryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            doc.title,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (doc.isPrivate) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.lock_outline_rounded,
                                            size: 14,
                                            color: AppColors.textMuted,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        doc.category.replaceAll('_', ' '),
                                        style: TextStyle(
                                          color: categoryColor,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 11,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          doc.createdAt.split('T')[0],
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (canDelete)
                                GestureDetector(
                                  onTap: () => _deleteDocument(doc.id),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentRed.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 14,
                                      color: AppColors.accentRed,
                                    ),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: _openUploadSheet,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
    );
  }

  void _openUploadSheet() {
    showAppFormSheet(
      context: context,
      builder: (ctx) => _UploadDocumentSheet(
        onUploaded: () {
          Navigator.pop(ctx);
          _fetchDocuments();
        },
      ),
    );
  }
}

// ── Upload document bottom sheet ─────────────────────────────────────────────

class _UploadDocumentSheet extends StatefulWidget {
  final VoidCallback onUploaded;
  const _UploadDocumentSheet({required this.onUploaded});

  @override
  State<_UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<_UploadDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  final CommunityService _service = CommunityService();
  String _selectedCategory = 'OTHER';
  String? _selectedFilePath;
  String? _selectedFileName;
  List<int>? _selectedFileBytes;
  bool _isPrivate = false;
  bool _isLoading = false;

  // Inline error state — modal sheets hide snackbars behind them, so API
  // failures are surfaced in the sheet instead.
  String? _apiError;

  final _categories = [
    'BY_LAWS',
    'MEETING_MINUTES',
    'AUDIT_REPORT',
    'FORM',
    'OTHER',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _selectedFileBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFilePath == null && _selectedFileBytes == null) {
      setState(() => _apiError = 'Please select a file');
      return;
    }

    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      await _service.uploadDocument(
        {
          'title': _titleController.text.trim(),
          'category': _selectedCategory,
          'is_private': _isPrivate.toString(),
        },
        filePath: _selectedFilePath,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
      );
      widget.onUploaded();
    } catch (e) {
      if (mounted) {
        setState(
          () => _apiError = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      accentColor: ModuleColors.documents,
      icon: Icons.upload_file_rounded,
      title: 'Upload Document',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader('Document Details'),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.title_rounded,
              label: 'Title',
              field: AppBorderlessField(
                controller: _titleController,
                hint: 'e.g. Society By-laws 2025',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.folder_rounded,
              label: 'Category',
              field: AppCardDropdown<String>(
                value: _selectedCategory,
                items: _categories,
                itemLabel: (c) => c.replaceAll('_', ' '),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
            ),
            const SizedBox(height: 12),
            _buildPrivateToggle(),
            const SizedBox(height: 24),
            const AppSectionHeader('Attachment'),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'Required — the file residents will download',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            _buildAttachmentCard(),
            if (_apiError != null) ...[
              const SizedBox(height: 18),
              AppSheetErrorBanner(_apiError!),
            ],
            const SizedBox(height: 26),
            GlarePrimaryButton(
              text: 'Upload Document',
              trailingIcon: Icons.upload_file_rounded,
              isLoading: _isLoading,
              onPressed: _upload,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRIVATE DOCUMENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Visible only to admins/owners',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPrivate,
            onChanged: (v) => setState(() => _isPrivate = v),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard() {
    final hasFile = _selectedFileName != null;

    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasFile
                ? AppColors.accentIndigo.withValues(alpha: 0.35)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.accentIndigo.withValues(alpha: 0.12)
                    : AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                hasFile ? Icons.description_rounded : Icons.attach_file_rounded,
                size: 18,
                color: hasFile ? AppColors.accentIndigo : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? _selectedFileName! : 'Attach a file',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? 'Tap to replace' : 'Tap to browse files',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile)
              GestureDetector(
                onTap: () => setState(() {
                  _selectedFilePath = null;
                  _selectedFileName = null;
                  _selectedFileBytes = null;
                }),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.accentRed,
                  ),
                ),
              )
            else
              const Icon(
                Icons.upload_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
