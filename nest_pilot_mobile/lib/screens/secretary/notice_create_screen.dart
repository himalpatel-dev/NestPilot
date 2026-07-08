import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/modules.dart';
import '../../services/notice_complaint_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/module_page_header.dart';
import '../../widgets/no_permission_notice.dart';

class NoticeCreateScreen extends StatefulWidget {
  const NoticeCreateScreen({super.key});

  @override
  State<NoticeCreateScreen> createState() => _NoticeCreateScreenState();
}

class _NoticeCreateScreenState extends State<NoticeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  final NoticeService _noticeService = NoticeService();
  String? _selectedFilePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String get _selectedFileName =>
      _selectedFilePath!.split(RegExp(r'[\\/]')).last;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _selectedFilePath = result.files.single.path);
    }
  }

  Future<void> _createNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success = await _noticeService.createNotice(
        _titleController.text,
        _contentController.text,
        filePath: _selectedFilePath,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notice published')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService().canManage(ModuleCodes.notices);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          ModulePageHeader(
            title: 'New Notice',
            description: 'Publish an announcement to your society',
            icon: Icons.campaign_outlined,
            iconColor: ModuleColors.notices,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader('Notice Details'),
                    const SizedBox(height: 14),
                    AppFieldCard(
                      icon: Icons.title_rounded,
                      label: 'Title',
                      field: AppBorderlessField(
                        controller: _titleController,
                        hint: 'e.g. Water supply maintenance',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Title is required'
                                : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFieldCard(
                      icon: Icons.notes_rounded,
                      label: 'Content',
                      iconAlignment: CrossAxisAlignment.start,
                      field: AppBorderlessField(
                        controller: _contentController,
                        hint: 'Write the full announcement here…',
                        maxLines: 6,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Content is required'
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const AppSectionHeader('Attachment'),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        'Optional — attach a PDF, image or document',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentCard(),
                    const SizedBox(height: 32),
                    if (canManage)
                      GlarePrimaryButton(
                        text: 'Publish Notice',
                        trailingIcon: Icons.campaign_rounded,
                        isLoading: _isLoading,
                        onPressed: _createNotice,
                      )
                    else
                      const NoPermissionNotice(action: 'publish notices'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard() {
    final hasFile = _selectedFilePath != null;

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
                hasFile
                    ? Icons.description_rounded
                    : Icons.attach_file_rounded,
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
                    hasFile ? _selectedFileName : 'Attach a file',
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
                onTap: () => setState(() => _selectedFilePath = null),
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
