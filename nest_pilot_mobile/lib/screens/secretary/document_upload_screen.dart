import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/community_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();

  String _selectedCategory = 'OTHER';
  String? _selectedFilePath;
  String? _selectedFileName;
  List<int>? _selectedFileBytes;
  bool _isPrivate = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'BY_LAWS',
    'MEETING_MINUTES',
    'AUDIT_REPORT',
    'FORM',
    'OTHER',
  ];

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = CommunityService();
      await service.uploadDocument(
        {
          'title': _titleController.text,
          'category': _selectedCategory,
          'is_private': _isPrivate.toString(),
        },
        filePath: _selectedFilePath,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Document Title',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Private Document'),
                subtitle: const Text('Visible only to Admins/Owners?'),
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFileName ?? 'Select File',
                          style: TextStyle(
                            color: _selectedFileName != null
                                ? Colors.black
                                : Colors.grey,
                            fontWeight: _selectedFileName != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Upload',
                isLoading: _isLoading,
                onPressed: _upload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
