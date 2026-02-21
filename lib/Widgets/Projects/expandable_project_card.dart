import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Widgets/add_edit_item_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../../General/app_colors.dart';
import '../../General/category_icons.dart';
import '../../Model/category_model.dart';
import '../../Model/project_model.dart';
import '../../Model/project_subtask_model.dart';
import '../../Provider/projects_provider.dart';
import '../../Service/logging_service.dart';
import '../Common/add_item_dialog.dart';
import '../Common/linkify_text.dart';
import './project_tasks_section.dart';
import 'dart:ui';

class ExpandableProjectCard extends StatefulWidget {
  final ProjectModel project;
  final CategoryModel? category;
  final int taskCount;
  final int completedTaskCount;
  final bool isExpanded;
  final VoidCallback onExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const ExpandableProjectCard({
    super.key,
    required this.project,
    this.category,
    this.taskCount = 0,
    this.completedTaskCount = 0,
    this.isExpanded = false,
    required this.onExpanded,
    this.onTap,
    this.onPin,
    this.onArchive,
    this.onDelete,
  });

  @override
  State<ExpandableProjectCard> createState() => _ExpandableProjectCardState();
}

class _ExpandableProjectCardState extends State<ExpandableProjectCard> with SingleTickerProviderStateMixin {
  List<ProjectSubtaskModel> _subtasks = [];
  bool _isLoadingDetails = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOutCubic),
    );

    if (widget.isExpanded) {
      _expandController.value = 1.0;
      _loadDetails();
    }
  }

  @override
  void didUpdateWidget(ExpandableProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _expandController.forward();
      _loadDetails();
    } else if (!widget.isExpanded && oldWidget.isExpanded) {
      _expandController.reverse();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    if (_isLoadingDetails) return;
    setState(() => _isLoadingDetails = true);

    final provider = context.read<ProjectsProvider>();
    _subtasks = await provider.getProjectSubtasks(widget.project.id);

    // Sort by orderIndex if available, then by createdAt
    _subtasks.sort((a, b) {
      final aOrder = a.orderIndex ?? 0;
      final bOrder = b.orderIndex ?? 0;
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    LogService.debug(
      '📂 ExpandableProjectCard: Loaded ${_subtasks.length} tasks for ${widget.project.title}',
    );

    if (mounted) {
      setState(() => _isLoadingDetails = false);
    }
  }

  void _toggleExpand() {
    widget.onExpanded();
  }

  void _copyAllTasks() {
    if (_subtasks.isEmpty) {
      LogService.error('⚠️ No tasks to copy');
      return;
    }

    final bulletList = _subtasks.map((task) {
      final status = task.isCompleted ? '✓' : '○';
      String result = '$status ${task.title}';
      if (task.description != null && task.description!.isNotEmpty) {
        result += '\n    ${task.description}';
      }
      return result;
    }).join('\n');

    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      Helper().getMessage(message: '${_subtasks.length} tasks copied');
      LogService.debug('✅ ${_subtasks.length} tasks copied to clipboard');
    });
  }

  void _copyIncompleteTasks() {
    final incomplete = _subtasks.where((t) => !t.isCompleted).toList();
    if (incomplete.isEmpty) {
      Helper().getMessage(message: 'No incomplete tasks', status: StatusEnum.INFO);
      LogService.error('⚠️ No incomplete tasks to copy');
      return;
    }

    final bulletList = incomplete.map((task) {
      String result = '○ ${task.title}';
      if (task.description != null && task.description!.isNotEmpty) {
        result += '\n    ${task.description}';
      }
      return result;
    }).join('\n');

    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      Helper().getMessage(message: '${incomplete.length} incomplete tasks copied');
      LogService.debug('✅ ${incomplete.length} incomplete tasks copied');
    });
  }

  Future<void> _toggleShowCompletedTasks() async {
    final provider = context.read<ProjectsProvider>();
    final newShowOnlyIncomplete = widget.project.showOnlyIncompleteTasks != true;

    widget.project.showOnlyIncompleteTasks = newShowOnlyIncomplete;
    await provider.updateProject(widget.project);

    await _loadDetails();

    Helper().getMessage(message: newShowOnlyIncomplete ? 'Completed tasks hidden' : 'All tasks shown');
    LogService.debug('✅ Show only incomplete: $newShowOnlyIncomplete');
  }

  Future<void> _completeAllTasks() async {
    final provider = context.read<ProjectsProvider>();
    for (final task in _subtasks) {
      if (!task.isCompleted) {
        await provider.toggleSubtaskCompleted(task.id);
      }
    }
    await _loadDetails();
    LogService.debug('✅ All tasks completed');
  }

  Future<void> _clearAllTasks() async {
    final provider = context.read<ProjectsProvider>();
    for (final task in _subtasks) {
      await provider.deleteSubtask(task.id);
    }
    await _loadDetails();
    LogService.debug('🗑️ All tasks deleted');
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = widget.category?.color ?? AppColors.main;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background.withValues(alpha: 0.9),
            AppColors.panelBackground.withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                // Highlight Strip
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withValues(alpha: 0.8),
                        categoryColor.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),

                // Header
                _buildHeader(context, categoryColor),

                // Expanded content (tasks)
                AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    return ClipRect(
                      child: Align(
                        heightFactor: _expandAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildExpandedContent(categoryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color categoryColor) {
    return Slidable(
      key: ValueKey(widget.project.id),
      endActionPane: ActionPane(
        extentRatio: 0.6,
        motion: const DrawerMotion(),
        children: [
          if (widget.onPin != null)
            SlidableAction(
              onPressed: (_) => widget.onPin!(),
              backgroundColor: AppColors.matteYellow,
              foregroundColor: AppColors.white,
              icon: widget.project.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
          if (widget.onArchive != null)
            SlidableAction(
              onPressed: (_) => widget.onArchive!(),
              backgroundColor: AppColors.matteOrange,
              foregroundColor: AppColors.white,
              icon: widget.project.isArchived ? Icons.unarchive : Icons.archive,
            ),
          if (widget.onDelete != null)
            SlidableAction(
              onPressed: (_) => widget.onDelete!(),
              backgroundColor: AppColors.matteRed,
              foregroundColor: AppColors.white,
              icon: Icons.delete,
            ),
        ],
      ),
      startActionPane: ActionPane(
        extentRatio: 0.3,
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(
          dismissThreshold: 0.3,
          closeOnCancel: true,
          confirmDismiss: () async {
            _showEditProjectBottomSheet();
            return false;
          },
          onDismissed: () {},
        ),
        children: [
          SlidableAction(
            onPressed: (_) {
              _showEditProjectBottomSheet();
            },
            backgroundColor: AppColors.matteBlue,
            foregroundColor: AppColors.white,
            icon: Icons.edit,
            label: 'edit'.tr(),
          ),
        ],
      ),
      child: InkWell(
        onTap: _toggleExpand,
        onLongPress: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon/Color Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.category?.iconCodePoint != null ? CategoryIcons.getIconByCodePoint(widget.category!.iconCodePoint) : Icons.work_outline,
                      color: categoryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinkifyText(
                          text: widget.project.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.onBackground,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (widget.category != null)
                          Text(
                            widget.category!.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: categoryColor.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Task Actions Menu
                  if (widget.isExpanded)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: AppColors.text.withValues(alpha: 0.6)),
                      onSelected: (value) async {
                        switch (value) {
                          case 'copy_all':
                            _copyAllTasks();
                            break;
                          case 'copy_incomplete':
                            _copyIncompleteTasks();
                            break;
                          case 'toggle_completed':
                            _toggleShowCompletedTasks();
                            break;
                          case 'complete_all':
                            await _completeAllTasks();
                            break;
                          case 'clear_all':
                            await _clearAllTasks();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'copy_all',
                          child: Row(
                            children: [
                              const Icon(Icons.content_copy, size: 18),
                              const SizedBox(width: 8),
                              Text('Copy All'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'copy_incomplete',
                          child: Row(
                            children: [
                              const Icon(Icons.content_copy, size: 18),
                              const SizedBox(width: 8),
                              Text('Copy Incomplete'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_completed',
                          child: Row(
                            children: [
                              const Icon(Icons.visibility, size: 18),
                              const SizedBox(width: 8),
                              Text('Hide Completed'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'complete_all',
                          child: Row(
                            children: [
                              const Icon(Icons.done_all, size: 18),
                              const SizedBox(width: 8),
                              Text('Complete All'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'clear_all',
                          child: Row(
                            children: [
                              const Icon(Icons.clear_all, size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Clear All'.tr(), style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),

                  // Expand Icon
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _expandAnimation.value * 3.14159,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.text.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Description
              if (widget.project.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                LinkifyText(
                  text: widget.project.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.text,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Bottom Meta Row
              Row(
                children: [
                  // Progress Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.text.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 14, color: widget.completedTaskCount == widget.taskCount && widget.taskCount > 0 ? AppColors.green : AppColors.text.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.completedTaskCount}/${widget.taskCount}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.completedTaskCount == widget.taskCount && widget.taskCount > 0 ? AppColors.green : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Action Indicators
                  if (widget.project.isPinned)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.yellow),
                    ),

                  if (widget.project.isArchived)
                    Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.archive_rounded, size: 14, color: AppColors.orange),
                    ),

                  const Spacer(),

                  // Date
                  Text(
                    widget.project.createdAt.compactDate(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Color categoryColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: categoryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Tasks section
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ProjectTasksSection(
              project: widget.project,
              tasks: _subtasks,
              onTasksChanged: _loadDetails,
            ),
          ),

          // Enhanced "Add Task" Button at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddItemDialog(
                    title: 'add_task'.tr(),
                    icon: Icons.add_task,
                    titleLabel: 'task_title'.tr(),
                    titleHint: 'enter_task_title'.tr(),
                    titleRequired: true,
                    descriptionLabel: 'description'.tr(),
                    descriptionHint: 'enter_task_description'.tr(),
                    descriptionRequired: false,
                    descriptionMaxLines: 3,
                    descriptionMinLines: 1,
                    showCancelButton: true,
                    onSave: (title, description) async {
                      if (title != null && title.isNotEmpty) {
                        final provider = Provider.of<ProjectsProvider>(context, listen: false);
                        final subtask = ProjectSubtaskModel(
                          id: 'subtask_${DateTime.now().millisecondsSinceEpoch}',
                          projectId: widget.project.id,
                          title: title,
                          description: description,
                          createdAt: DateTime.now(),
                        );
                        await provider.addSubtask(subtask);
                        await _loadDetails();
                        Helper().getMessage(
                          message: 'Task added successfully',
                          status: StatusEnum.SUCCESS,
                        );
                        LogService.debug('✅ Quick task added: $title');
                      }
                    },
                    isEditing: false,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withValues(alpha: 0.15),
                      categoryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                      color: categoryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Task',
                      style: TextStyle(
                        fontSize: 14,
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProjectBottomSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditItemBottomSheet(
        type: ItemType.project,
        item: widget.project,
      ),
    );

    if (result == true) {
      await _loadDetails();
      LogService.debug('✅ ExpandableProjectCard: Project updated, UI refreshed');
    }
  }
}
