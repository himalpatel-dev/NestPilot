import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/notice_complaint.dart';
import '../../services/notice_complaint_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_form_sheet.dart';
import '../../widgets/glare_button.dart';

/// File-a-complaint / edit-a-complaint bottom sheet, shared by the complaint
/// list (create) and the complaint detail page (edit).
///
/// Pass [complaint] to open in edit mode — the fields are prefilled and the
/// save goes to `PUT /complaints/:id` instead of `POST /complaints`. The API
/// only accepts category, description and the photo; status has its own
/// endpoint and priority is not editable server-side.
class ComplaintFormSheet extends StatefulWidget {
  /// The complaint being edited, or null when filing a new one.
  final Complaint? complaint;

  /// Called after a successful save. Carries the updated complaint when
  /// editing, null when creating (the create endpoint returns no body worth
  /// reading — the caller refetches instead).
  final void Function(Complaint? updated) onSaved;

  const ComplaintFormSheet({super.key, this.complaint, required this.onSaved});

  @override
  State<ComplaintFormSheet> createState() => _ComplaintFormSheetState();
}

class _ComplaintFormSheetState extends State<ComplaintFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descCtrl;

  final ComplaintService _complaintService = ComplaintService();

  /// A photo picked in this sheet. Null means "leave the existing one alone" —
  /// the backend only overwrites `image_path` when a file is uploaded, so
  /// there is no way to clear a photo once it is set.
  String? _selectedImagePath;
  bool _isLoading = false;

  // Inline error state — modal sheets hide snackbars behind them, so API
  // failures are surfaced in the sheet instead.
  String? _apiError;

  bool get _isEdit => widget.complaint != null;

  @override
  void initState() {
    super.initState();
    _categoryCtrl = TextEditingController(
      text: widget.complaint?.category ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.complaint?.description ?? '',
    );
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String get _selectedFileName =>
      _selectedImagePath!.split(RegExp(r'[\\/]')).last;

  /// The photo already on the complaint, if any.
  String? get _existingImageUrl {
    final path = widget.complaint?.imagePath;
    if (path == null || path.isEmpty) return null;
    return path.startsWith('http') ? path : '${AppConfig.baseUrl}$path';
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _selectedImagePath = result.files.single.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      if (_isEdit) {
        final updated = await _complaintService.updateComplaint(
          widget.complaint!.id,
          _categoryCtrl.text.trim(),
          _descCtrl.text.trim(),
          filePath: _selectedImagePath,
        );
        if (!mounted) return;
        if (updated != null) {
          widget.onSaved(updated);
        } else {
          setState(
            () => _apiError = 'Could not save the changes. Please try again.',
          );
        }
      } else {
        final success = await _complaintService.createComplaint(
          _categoryCtrl.text.trim(),
          _descCtrl.text.trim(),
          filePath: _selectedImagePath,
        );
        if (!mounted) return;
        if (success) {
          widget.onSaved(null);
        } else {
          setState(
            () => _apiError = 'Could not file the complaint. Please try again.',
          );
        }
      }
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
      accentColor: ModuleColors.complaints,
      icon: Icons.report_problem_rounded,
      title: _isEdit ? 'Edit Complaint' : 'File a Complaint',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader('Complaint Details'),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.category_outlined,
              label: 'Category',
              field: AppBorderlessField(
                controller: _categoryCtrl,
                hint: 'e.g. Plumbing, Electrical, Security',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Category is required'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.notes_rounded,
              label: 'Description',
              iconAlignment: CrossAxisAlignment.start,
              field: AppBorderlessField(
                controller: _descCtrl,
                hint: 'Describe the issue in detail…',
                maxLines: 5,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            const AppSectionHeader('Photo'),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                _isEdit
                    ? 'Optional — pick a new photo to replace the current one'
                    : 'Optional — a photo helps the team spot the issue faster',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPhotoCard(),
            if (_apiError != null) ...[
              const SizedBox(height: 18),
              AppSheetErrorBanner(_apiError!),
            ],
            const SizedBox(height: 26),
            GlarePrimaryButton(
              text: _isEdit ? 'Save Changes' : 'Submit Complaint',
              trailingIcon: Icons.check_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    final hasImage = _selectedImagePath != null;
    final existingUrl = _existingImageUrl;
    final hasPhoto = hasImage || existingUrl != null;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasPhoto
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
            // The picked photo doubles as the card's icon chip, so the resident
            // can confirm they attached the right shot before submitting.
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_selectedImagePath!),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
            else if (existingUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  existingUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _addPhotoChip(),
                ),
              )
            else
              _addPhotoChip(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasImage
                        ? _selectedFileName
                        : (existingUrl != null
                              ? 'Current photo'
                              : 'Add a photo'),
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
                    hasPhoto ? 'Tap to replace' : 'Tap to browse photos',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            // Only a photo picked in this sheet can be undone — clearing the
            // stored one isn't something the API supports.
            if (hasImage)
              GestureDetector(
                onTap: () => setState(() => _selectedImagePath = null),
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _addPhotoChip() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.add_a_photo_outlined,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }
}
