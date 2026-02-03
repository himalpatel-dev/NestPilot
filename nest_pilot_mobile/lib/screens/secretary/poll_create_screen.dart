import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class PollCreateScreen extends StatefulWidget {
  const PollCreateScreen({super.key});

  @override
  State<PollCreateScreen> createState() => _PollCreateScreenState();
}

class _PollCreateScreenState extends State<PollCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    // Check options
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 options are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = CommunityService();
      await service.createPoll({
        'question': _questionController.text,
        'description': _descController.text,
        'end_date': _selectedDate.toIso8601String(),
        'options': options,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll created successfully')),
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
      appBar: AppBar(title: const Text('Create Poll')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _questionController,
                label: 'Question',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descController,
                label: 'Description (Optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text(
                'Options',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ..._optionControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: controller,
                          label: 'Option ${index + 1}',
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeOption(index),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Create Poll',
                isLoading: _isLoading,
                onPressed: _createPoll,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
