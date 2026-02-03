import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/notice_complaint_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Notice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Title',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _contentController,
                label: 'Content',
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedFilePath != null
                          ? 'File: ${_selectedFilePath!.split('/').last}'
                          : 'No attachment selected',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Publish Notice',
                isLoading: _isLoading,
                onPressed: _createNotice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
