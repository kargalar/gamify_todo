import 'package:flutter/material.dart';
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
import '../../Model/project_note_model.dart';
import '../../Provider/projects_provider.dart';
import '../../Service/logging_service.dart';
import '../Common/add_item_dialog.dart';
import '../Common/linkify_text.dart';
import './add_project_note_bottom_sheet.dart';
import './project_tasks_section.dart';
import './project_notes_section.dart';

class ExpandableProjectCard extends StatefulWidget {
  final ProjectModel project;
  final CategoryModel? category;
  final int taskCount;
  final int completedTaskCount;
  final int noteCount;
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
    this.noteCount = 0,
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
  List<ProjectNoteModel> _notes = [];
  bool _isLoadingDetails = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    if (widget.isExpanded) {
      _expandController.forward();
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
    _notes = await provider.getProjectNotes(widget.project.id);

    // Sort by orderIndex if available, then by createdAt
    _subtasks.sort((a, b) {
      final aOrder = a.orderIndex ?? 0;
      final bOrder = b.orderIndex ?? 0;
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    _notes.sort((a, b) {
      final aOrder = a.orderIndex ?? 0;
      final bOrder = b.orderIndex ?? 0;
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    LogService.debug(
      '📂 ExpandableProjectCard: Loaded ${_subtasks.length} tasks and ${_notes.length} notes for ${widget.project.title}',
    );

    if (mounted) {
      setState(() => _isLoadingDetails = false);
    }
  }

  void _toggleExpand() {
    widget.onExpanded();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = widget.category?.color ?? AppColors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppColors.borderRadiusAll,
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Header (always visible)
            _buildHeader(context, categoryColor),

            // Expanded content (task and notes)
            if (widget.isExpanded)
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
              backgroundColor: AppColors.matteGreen,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              foregroundColor: AppColors.white,
              icon: widget.project.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
          if (widget.onArchive != null)
            SlidableAction(
              onPressed: (_) => widget.onArchive!(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: AppColors.matteOrange,
              borderRadius: BorderRadius.circular(12),
              foregroundColor: AppColors.white,
              icon: widget.project.isArchived ? Icons.unarchive : Icons.archive,
            ),
          if (widget.onDelete != null)
            SlidableAction(
              onPressed: (_) => widget.onDelete!(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: AppColors.matteRed,
              borderRadius: BorderRadius.circular(12),
              foregroundColor: AppColors.white,
              icon: Icons.delete,
            ),
        ],
      ),
      startActionPane: ActionPane(
        extentRatio: 0.4,
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            borderRadius: BorderRadius.circular(12),
            foregroundColor: AppColors.white,
            icon: Icons.edit,
            label: 'edit'.tr(),
          ),
        ],
      ),
      child: InkWell(
        onTap: _toggleExpand,
        onLongPress: widget.onTap,
        borderRadius: AppColors.borderRadiusAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with expand button
              Row(
                children: [
                  Expanded(
                    child: LinkifyText(
                      text: widget.project.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Expand/collapse button
                  GestureDetector(
                    onTap: _toggleExpand,
                    child: AnimatedBuilder(
                      animation: _expandAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _expandAnimation.value * 3.14159,
                          child: Icon(
                            Icons.expand_more,
                            color: categoryColor,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Category badge
                  if (widget.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.category!.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.category!.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.category!.iconCodePoint != null)
                            Icon(
                              CategoryIcons.getIconByCodePoint(widget.category!.iconCodePoint) ?? Icons.category,
                              size: 14,
                              color: widget.category!.color,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            widget.category!.title,
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.category!.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Description
              if (widget.project.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                LinkifyText(
                  text: widget.project.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onBackground.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Status and counts
              const SizedBox(height: 8),
              Row(
                children: [
                  // Pinned indicator
                  if (widget.project.isPinned)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.push_pin,
                        size: 12,
                        color: AppColors.yellow,
                      ),
                    ),

                  // Archived indicator
                  if (widget.project.isArchived)
                    Container(
                      padding: const EdgeInsets.all(3),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.archive,
                        size: 12,
                        color: AppColors.orange,
                      ),
                    ),

                  const Spacer(),

                  // Task count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_box_outlined, size: 11, color: AppColors.green),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.completedTaskCount}/${widget.taskCount}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Note count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.note_outlined, size: 11, color: AppColors.yellow),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.noteCount}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Date
              const SizedBox(height: 6),
              Text(
                widget.project.createdAt.compactDate(),
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.onBackground.withValues(alpha: 0.5),
                ),
              ),

              // Quick action buttons
              const SizedBox(height: 10),
              Row(
                children: [
                  // Quick task button
                  Expanded(
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
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_task,
                              size: 12,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Add Task',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Quick note button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddProjectNoteBottomSheet(
                            onSave: (title, content) async {
                              final provider = Provider.of<ProjectsProvider>(context, listen: false);
                              final note = ProjectNoteModel(
                                id: 'note_${DateTime.now().millisecondsSinceEpoch}',
                                projectId: widget.project.id,
                                title: title,
                                content: content,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              );
                              await provider.addProjectNote(note);
                              await _loadDetails();
                              Helper().getMessage(
                                message: 'Note added successfully',
                                status: StatusEnum.SUCCESS,
                              );
                              LogService.debug('✅ Quick note added: $title');
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.yellow.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.note_add,
                              size: 12,
                              color: AppColors.yellow,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Add Note',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.yellow,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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
        border: Border(
          top: BorderSide(
            color: categoryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Tasks section
            ProjectTasksSection(
              project: widget.project,
              tasks: _subtasks,
              onTasksChanged: _loadDetails,
            ),

            // Notes section
            ProjectNotesSection(
              project: widget.project,
              notes: _notes,
              onNotesChanged: _loadDetails,
            ),

            // Empty state
            if (_subtasks.isEmpty && _notes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No tasks or notes yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
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
      // Refresh project data
      await _loadDetails();
      LogService.debug('✅ ExpandableProjectCard: Project updated, UI refreshed');
    }
  }
}
