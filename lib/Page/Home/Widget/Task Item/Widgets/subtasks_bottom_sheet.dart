import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/subtask_dialog.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/subtask_item.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

class SubtasksBottomSheet extends StatefulWidget {
  final TaskModel taskModel;

  const SubtasksBottomSheet({
    super.key,
    required this.taskModel,
  });

  @override
  State<SubtasksBottomSheet> createState() => _SubtasksBottomSheetState();
}

class _SubtasksBottomSheetState extends State<SubtasksBottomSheet> {
  bool hasClipboardData = false;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      // Try to parse
      final parsed = _parseSubtasksFromText(data.text!);
      setState(() {
        hasClipboardData = parsed.isNotEmpty;
      });
    } else {
      setState(() {
        hasClipboardData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final subtasks = widget.taskModel.subtasks ?? [];

    // Sort subtasks: incomplete first, completed last
    final sortedSubtasks = List<SubTaskModel>.from(subtasks)
      ..sort((a, b) {
        if (a.isCompleted && !b.isCompleted) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;
        return 0;
      });

    final displayedSubtasks = widget.taskModel.showSubtasks ? sortedSubtasks : sortedSubtasks.where((subtask) => !subtask.isCompleted).toList();
    final completedCount = subtasks.where((subtask) => subtask.isCompleted).length;
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 16), // Remove excessive bottom padding
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: const Border(
              top: BorderSide(color: AppColors.dirtyWhite),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.text.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with title and toggle button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          color: AppColors.main,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        ClickableTooltip(
                          title: LocaleKeys.Subtasks.tr(),
                          // TODO: localization
                          bulletPoints: const ["Tap checkbox to mark subtask as done", "Long press to edit a subtask", "Swipe left to delete a subtask"],
                          child: Text(
                            LocaleKeys.Subtasks.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Subtask count badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.main.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$completedCount/${subtasks.length}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.main,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // three dot menu
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'copy all subtasks',
                          child: const Row(
                            children: [
                              Icon(Icons.content_copy, size: 18),
                              SizedBox(width: 8),
                              Text('Copy All Subtasks'),
                            ],
                          ),
                          onTap: () {
                            _copyAllSubtasks();
                          },
                        ),
                        PopupMenuItem(
                          value: 'copy incomplete subtasks',
                          child: const Row(
                            children: [
                              Icon(Icons.content_copy, size: 18),
                              SizedBox(width: 8),
                              Text('Copy Incomplete Subtasks'),
                            ],
                          ),
                          onTap: () {
                            _copyIncompleteSubtasks();
                          },
                        ),
                        if (hasClipboardData)
                          PopupMenuItem(
                            value: 'paste subtasks',
                            child: const Row(
                              children: [
                                Icon(Icons.content_paste, size: 18),
                                SizedBox(width: 8),
                                Text('Paste Subtasks'),
                              ],
                            ),
                            onTap: () {
                              _pasteSubtasks();
                            },
                          ),
                        if (subtasks.isNotEmpty)
                          PopupMenuItem(
                            value: 'clear all subtasks',
                            child: const Row(
                              children: [
                                Icon(Icons.clear_all, size: 18),
                                SizedBox(width: 8),
                                Text('Clear All Subtasks'),
                              ],
                            ),
                            onTap: () {
                              _clearAllSubtasks();
                            },
                          ),
                      ],
                    ),
                    // Show/Hide completed subtasks toggle
                    if (completedCount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: InkWell(
                          onTap: () {
                            taskProvider.toggleTaskSubtaskVisibility(widget.taskModel);
                          },
                          child: Icon(
                            widget.taskModel.showSubtasks ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: AppColors.text.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Subtasks list or empty state
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: subtasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_box_outline_blank_rounded,
                                color: AppColors.text.withValues(alpha: 0.3),
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "No subtasks",
                                style: TextStyle(
                                  color: AppColors.text.withValues(alpha: 0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: displayedSubtasks.length,
                          itemBuilder: (context, index) {
                            final subtask = displayedSubtasks[index];
                            return SubtaskItem(
                              subtask: subtask,
                              taskModel: widget.taskModel,
                              onEdit: () => _showSubtaskDialog(subtask),
                              onDelete: () => _removeSubtask(subtask),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ), // Floating Add Button - positioned to stay on top
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              _showSubtaskDialog(null);
            },
            backgroundColor: AppColors.main,
            foregroundColor: Colors.white,
            elevation: 8,
            heroTag: "add_subtask_fab", // Unique hero tag to avoid conflicts
            child: const Icon(
              Icons.add_rounded,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  void _removeSubtask(SubTaskModel subtask) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.removeSubtask(widget.taskModel, subtask);
    setState(() {});
  }

  void _showSubtaskDialog(SubTaskModel? subtask) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => SubtaskDialog(
        subtask: subtask,
        onSave: (title, description) {
          final taskProvider = Provider.of<TaskProvider>(context, listen: false);

          if (subtask == null) {
            // Add new subtask
            taskProvider.addSubtask(widget.taskModel, title, description);
          } else {
            // Update existing subtask
            taskProvider.updateSubtask(widget.taskModel, subtask, title, description);
          }
        },
      ),
    );
  }

  void _copyAllSubtasks() {
    final subtasks = widget.taskModel.subtasks ?? [];
    if (subtasks.isEmpty) return;

    // Create bullet list with completed/incomplete status and descriptions
    final bulletList = subtasks.map((subtask) {
      final status = subtask.isCompleted ? '✓' : '○';
      String result = '$status ${subtask.title}';

      // Add description if it exists and is not empty
      if (subtask.description != null && subtask.description!.isNotEmpty) {
        result += '\n    ${subtask.description}';
      }

      return result;
    }).join('\n');

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      // Update UI to show paste button
      setState(() {
        hasClipboardData = true;
      });
      // Show confirmation snackbar
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subtasks copied to clipboard'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.main,
        ),
      );
    });
  }

  void _copyIncompleteSubtasks() {
    final subtasks = widget.taskModel.subtasks ?? [];
    final incomplete = subtasks.where((s) => !s.isCompleted).toList();
    if (incomplete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No incomplete subtasks to copy'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.text.withValues(alpha: 0.1),
        ),
      );
      return;
    }

    final bulletList = incomplete.map((subtask) {
      String result = '○ ${subtask.title}';
      if (subtask.description != null && subtask.description!.isNotEmpty) {
        result += '\n    ${subtask.description}';
      }
      return result;
    }).join('\n');

    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      setState(() {
        hasClipboardData = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incomplete subtasks copied to clipboard'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.main,
        ),
      );
    });
  }

  List<SubTaskModel> _parseSubtasksFromText(String text) {
    final lines = text.split('\n');
    final List<SubTaskModel> parsedSubtasks = [];
    int id = 0; // Generate new ids

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check if line starts with status
      if (line.startsWith('✓ ') || line.startsWith('○ ')) {
        final isCompleted = line.startsWith('✓ ');
        final title = line.substring(2).trim();
        String? description;

        // Check next line for description
        if (i + 1 < lines.length && lines[i + 1].startsWith('    ')) {
          description = lines[i + 1].substring(4).trim();
          i++; // Skip description line
        }

        parsedSubtasks.add(SubTaskModel(
          id: id++,
          title: title,
          isCompleted: isCompleted,
          description: description,
        ));
      }
    }

    return parsedSubtasks;
  }

  Future<void> _pasteSubtasks() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) return;

    final parsedSubtasks = _parseSubtasksFromText(data.text!);
    if (parsedSubtasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid subtasks found in clipboard'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    for (final parsed in parsedSubtasks) {
      taskProvider.addSubtask(widget.taskModel, parsed.title, parsed.description ?? '');
      // Set completion status if needed
      if (parsed.isCompleted) {
        final addedSubtask = widget.taskModel.subtasks!.last;
        addedSubtask.isCompleted = true;
        widget.taskModel.save();
      }
    }

    _checkClipboard(); // Re-check clipboard after paste

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${parsedSubtasks.length} subtasks pasted'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.main,
      ),
    );
  }

  void _clearAllSubtasks() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final count = widget.taskModel.subtasks?.length ?? 0;
    taskProvider.clearSubtasks(widget.taskModel);
    setState(() {}); // Refresh UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count subtasks cleared'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.red,
      ),
    );
  }
}
