import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

/// Reusable description editor component
/// Can be used for tasks, notes, projects, subtasks, etc.
/// Supports auto-save, timer tracking, character count, and copy functionality
class DescriptionEditor extends StatefulWidget {
  const DescriptionEditor({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.showTimer = false,
    this.timerDuration,
    this.onTimerReset,
    this.title,
  });

  /// Text controller for the description field
  final TextEditingController controller;

  /// Callback when description text changes (for auto-save)
  final Function(String) onChanged;

  /// Optional focus node for tracking focus state
  final FocusNode? focusNode;

  /// Whether to show the timer widget
  final bool showTimer;

  /// Current timer duration (if showTimer is true)
  final Duration? timerDuration;

  /// Callback when timer reset is tapped (if showTimer is true)
  final VoidCallback? onTimerReset;

  /// Optional custom title for the app bar
  final String? title;

  @override
  State<DescriptionEditor> createState() => _DescriptionEditorState();
}

class _DescriptionEditorState extends State<DescriptionEditor> {
  @override
  void initState() {
    super.initState();
    // If a focus node is provided, request focus after build
    if (widget.focusNode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.focusNode!.requestFocus();
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _copyDescription() {
    final description = widget.controller.text;
    if (description.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: description));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.CopiedDescription.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
        debugPrint('✅ Description copied to clipboard');
      }
    } else {
      debugPrint('⚠️ No description to copy');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          widget.title ?? LocaleKeys.Description.tr(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
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
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: widget.focusNode == null, // Auto-focus if no focus node provided
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
                    contentPadding: const EdgeInsets.only(
                      left: 16,
                      top: 10,
                      bottom: 12,
                    ),
                  ),
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.none,
                  onChanged: (value) {
                    setState(() {}); // Update UI to reflect changes
                    widget.onChanged(value); // Trigger callback
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Character count, timer, and copy button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.panelBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Timer (if enabled)
                      if (widget.showTimer && widget.timerDuration != null) ...[
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.text.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Time: ${_formatDuration(widget.timerDuration!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.onTimerReset != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onTimerReset,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.panelBackground,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.text.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.text.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                      ],

                      // Character count
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Characters: ${widget.controller.text.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  // Copy button
                  GestureDetector(
                    onTap: _copyDescription,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.text.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppColors.text.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            LocaleKeys.Copy.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.text.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
