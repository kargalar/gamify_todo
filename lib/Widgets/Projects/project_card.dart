import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:intl/intl.dart';

/// Renkli ve kategorili proje kartı widget'ı
class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Future<int> Function()? getSubtaskCount;
  final Future<int> Function()? getNoteCount;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onDelete,
    this.getSubtaskCount,
    this.getNoteCount,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM, HH:mm').format(project.updatedAt);
    final provider = context.watch<ProjectsProvider>();
    final category = project.categoryId != null ? provider.getCategoryById(project.categoryId) : null;

    // Kategori rengi veya default renk
    final categoryColor = category != null ? Color(category.colorValue) : AppColors.main;

    final categoryIcon = category != null ? IconData(category.iconCodePoint, fontFamily: 'MaterialIcons') : Icons.folder_outlined;

    return Slidable(
      key: ValueKey(project.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            onPressed: (context) async {
              final slidableProvider = Provider.of<ProjectsProvider>(context, listen: false);
              await slidableProvider.toggleArchiveProject(project.id);
            },
            backgroundColor: AppColors.orange,
            icon: project.isArchived ? Icons.unarchive : Icons.archive,
            label: project.isArchived ? 'Geri Al' : 'Arşivle',
          ),
          SlidableAction(
            onPressed: (context) async {
              if (onDelete != null) {
                onDelete!();
              }
            },
            backgroundColor: AppColors.red,
            icon: Icons.delete,
            label: 'Sil',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withValues(alpha: 0.12),
              categoryColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Title + Pin
                  Row(
                    children: [
                      // Kategori ikonu
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          size: 22,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title + Category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (project.isPinned)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.push_pin,
                                      size: 15,
                                      color: AppColors.yellow,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    project.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (category != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: categoryColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (project.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      project.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.text.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Footer: Stats + Date
                  Row(
                    children: [
                      // Subtask count
                      if (getSubtaskCount != null)
                        FutureBuilder<int>(
                          future: getSubtaskCount!(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data! > 0) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: categoryColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_box_outlined,
                                      size: 14,
                                      color: categoryColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${snapshot.data}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: categoryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      // Note count
                      if (getNoteCount != null)
                        FutureBuilder<int>(
                          future: getNoteCount!(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data! > 0) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: categoryColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.note_outlined,
                                      size: 14,
                                      color: categoryColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${snapshot.data}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: categoryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      const Spacer(),

                      // Date
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.panelBackground2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.text.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
