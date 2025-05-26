import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/add_store_item_providerr.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

class DescriptionEditor extends StatefulWidget {
  const DescriptionEditor({
    super.key,
    this.isStore = false,
  });

  final bool isStore;

  @override
  State<DescriptionEditor> createState() => _DescriptionEditorState();
}

class _DescriptionEditorState extends State<DescriptionEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final dynamic _provider;
  String _initialText = '';

  @override
  void initState() {
    super.initState();

    // Get the appropriate provider
    _provider = widget.isStore ? context.read<AddStoreItemProvider>() : context.read<AddTaskProvider>();

    // Use the existing controller and focus node from provider
    _controller = _provider.descriptionController;
    _focusNode = _provider.descriptionFocus;

    // Store initial text for comparison
    _initialText = _controller.text;

    // Auto-focus the text field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _saveAndClose() {
    // Notify provider of changes
    _provider.notifyListeners();
    Navigator.of(context).pop();
  }

  void _cancelAndClose() {
    // Restore original text if user cancels
    _controller.text = _initialText;
    _provider.notifyListeners();
    Navigator.of(context).pop();
  }

  bool get _hasChanges => _controller.text != _initialText;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_hasChanges) {
            _showDiscardDialog();
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              if (_hasChanges) {
                _showDiscardDialog();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            LocaleKeys.Description.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saveAndClose,
              child: Text(
                LocaleKeys.Save.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Description input area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: LocaleKeys.EnterDescription.tr(),
                      hintStyle: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.4),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onChanged: (value) {
                      setState(() {}); // Update UI to reflect changes
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Character count and tips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Characters: ${_controller.text.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withValues(alpha: 0.6),
                          ),
                        ),
                        if (_hasChanges)
                          const Text(
                            'Unsaved changes',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.orange2,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add details, notes, or instructions for this task',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.text.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.Warning.tr()),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.Cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _cancelAndClose(); // Close editor and discard changes
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
