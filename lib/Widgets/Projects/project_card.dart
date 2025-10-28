import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';
import '../../General/app_colors.dart';
import '../../General/category_icons.dart';
import '../../General/date_formatter.dart';
import '../../Model/category_model.dart';
import '../../Model/project_model.dart';
import '../../Model/project_subtask_model.dart';
import '../../Model/project_note_model.dart';
import '../../Provider/projects_provider.dart';
import '../Common/base_card.dart';
import '../Common/add_item_dialog.dart';
import '../Common/linkify_text.dart';

class ProjectCard extends BaseCard {
  final ProjectModel project;
  final CategoryModel? category;
  final int taskCount;
  final int completedTaskCount;
  final int noteCount;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required super.itemId,
    required this.project,
    this.category,
    this.taskCount = 0,
    this.completedTaskCount = 0,
    this.noteCount = 0,
    this.onTap,
    this.onPin,
    this.onArchive,
    this.onDelete,
  });

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemDialog(
        title: 'edit_project'.tr(),
        icon: Icons.edit,
        titleLabel: 'project_title'.tr(),
        titleHint: 'enter_project_title'.tr(),
        titleRequired: true,
        initialTitle: project.title,
        descriptionLabel: 'description'.tr(),
        descriptionHint: 'enter_project_description'.tr(),
        descriptionRequired: false,
        initialDescription: project.description,
        descriptionMaxLines: 3,
        descriptionMinLines: 1,
        showCancelButton: true,
        onSave: (title, description) async {
          if (title != null && title.isNotEmpty) {
            try {
              final projectsProvider = Provider.of<ProjectsProvider>(context, listen: false);

              final updatedProject = project.copyWith(
                title: title,
                description: description ?? '',
              );

              final success = await projectsProvider.updateProject(updatedProject);

              if (success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ProjectUpdateSuccess'.tr()),
                    backgroundColor: AppColors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ProjectUpdateError'.tr()),
                    backgroundColor: AppColors.red,
                  ),
                );
              }

              LogService.debug('✅ Project updated successfully: $title');
            } catch (e) {
              LogService.error('❌ Error updating project: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ProjectUpdateError'.tr()),
                    backgroundColor: AppColors.red,
                  ),
                );
              }
            }
          }
        },
        isEditing: true,
      ),
    );
  }

  @override
  List<SlidableAction>? buildStartActions(BuildContext context) {
    return [
      SlidableAction(
        onPressed: (_) {
          LogService.debug('✏️ Project ${project.id} - Edit operation started');
          _showEditDialog(context);
        },
        backgroundColor: AppColors.blue,
        padding: const EdgeInsets.all(0),
        foregroundColor: AppColors.white,
        icon: Icons.edit,
        label: 'edit'.tr(),
      ),
    ];
  }

  @override
  List<SlidableAction> buildActions(BuildContext context) {
    return [
      if (onPin != null)
        SlidableAction(
          onPressed: (_) => onPin!(),
          backgroundColor: AppColors.green,
          padding: const EdgeInsets.all(0),
          foregroundColor: AppColors.white,
          icon: project.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          label: project.isPinned ? 'unpin'.tr() : 'pin'.tr(),
        ),
      if (onArchive != null)
        SlidableAction(
          onPressed: (_) => onArchive!(),
          padding: const EdgeInsets.all(0),
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          icon: project.isArchived ? Icons.unarchive : Icons.archive,
          label: project.isArchived ? 'unarchive'.tr() : 'archive'.tr(),
        ),
      if (onDelete != null)
        SlidableAction(
          onPressed: (_) => onDelete!(),
          padding: const EdgeInsets.all(0),
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.white,
          icon: Icons.delete,
          label: 'delete'.tr(),
        ),
    ];
  }

  @override
  Widget buildContent(BuildContext context) {
    final categoryColor = category?.color ?? AppColors.grey;

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
        child: InkWell(
          onTap: onTap,
          borderRadius: AppColors.borderRadiusAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and category
                Row(
                  children: [
                    Expanded(
                      child: LinkifyText(
                        text: project.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: category!.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: category!.color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (category!.iconCodePoint != null)
                              Icon(
                                CategoryIcons.getIconByCodePoint(category!.iconCodePoint) ?? Icons.category,
                                size: 16,
                                color: category!.color,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              category!.title,
                              style: TextStyle(
                                fontSize: 12,
                                color: category!.color,
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
                if (project.description.isNotEmpty) ...[
                  LinkifyText(
                    text: project.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onBackground.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Status indicators
                if (project.isPinned)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.push_pin,
                      size: 14,
                      color: AppColors.yellow,
                    ),
                  ),
                if (project.isArchived)
                  Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.archive,
                      size: 14,
                      color: AppColors.orange,
                    ),
                  ),

                const SizedBox(height: 12),

                // Quick action buttons
                Row(
                  children: [
                    // Quick task button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          // Quick subtask ekleme dialog'u
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
                                  try {
                                    final projectsProvider = Provider.of<ProjectsProvider>(context, listen: false);

                                    final subtask = ProjectSubtaskModel(
                                      id: 'subtask_${DateTime.now().millisecondsSinceEpoch}',
                                      projectId: project.id,
                                      title: title,
                                      description: description,
                                      createdAt: DateTime.now(),
                                    );

                                    final success = await projectsProvider.addSubtask(subtask);

                                    if (success && context.mounted) {
                                      Navigator.of(context).pop(); // Dialog'u kapat
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('TaskAddSuccess'.tr()),
                                          backgroundColor: AppColors.green,
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('TaskAddError'.tr()),
                                          backgroundColor: AppColors.red,
                                        ),
                                      );
                                    }

                                    LogService.debug('✅ Subtask added successfully to project "${project.title}": $title');
                                  } catch (e) {
                                    LogService.error('❌ Error adding subtask: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('TaskAddError'.tr()),
                                          backgroundColor: AppColors.red,
                                        ),
                                      );
                                    }
                                  }
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
                                '$completedTaskCount/$taskCount ${'quick_task'.tr()}',
                                style: const TextStyle(
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
                          // Quick project note ekleme dialog'u
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddItemDialog(
                              title: 'add_note'.tr(),
                              icon: Icons.note_add,
                              titleLabel: 'note_title'.tr(),
                              titleHint: 'enter_note_title'.tr(),
                              titleRequired: true,
                              descriptionLabel: 'content'.tr(),
                              descriptionHint: 'enter_note_content'.tr(),
                              descriptionRequired: false,
                              descriptionMaxLines: 5,
                              descriptionMinLines: 3,
                              showCancelButton: true,
                              onSave: (title, description) async {
                                if (title != null && title.isNotEmpty) {
                                  try {
                                    final projectsProvider = Provider.of<ProjectsProvider>(context, listen: false);

                                    final note = ProjectNoteModel(
                                      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
                                      projectId: project.id,
                                      title: title,
                                      content: description,
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    );

                                    final success = await projectsProvider.addProjectNote(note);

                                    if (success && context.mounted) {
                                      Navigator.of(context).pop(); // Dialog'u kapat
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('NoteAddSuccess'.tr()),
                                          backgroundColor: AppColors.green,
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('NoteAddError'.tr()),
                                          backgroundColor: AppColors.red,
                                        ),
                                      );
                                    }

                                    LogService.debug('✅ Note added successfully to project "${project.title}": $title');
                                  } catch (e) {
                                    LogService.error('❌ Error adding note: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('NoteAddError'.tr()),
                                          backgroundColor: AppColors.red,
                                        ),
                                      );
                                    }
                                  }
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
                                '$noteCount ${'quick_note'.tr()}',
                                style: const TextStyle(
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

                // Created date
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatDate(project.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.onBackground.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
