import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/General/date_formatter.dart';
import 'package:next_level/Widgets/Common/base_card.dart';

/// Compact and simple note card widget (with Slidable actions)
class NoteCard extends BaseCard {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onPinToggle,
    this.onDelete,
    this.onEdit,
  }) : super(itemId: note.id.toString());

  @override
  List<SlidableAction> buildActions(BuildContext context) {
    return [
      // Edit action
      if (onEdit != null)
        SlidableAction(
          padding: const EdgeInsets.all(0),
          onPressed: (context) {
            LogService.debug('✏️ Note ${note.id} - Edit operation started');
            onEdit!();
          },
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
          icon: Icons.edit,
          label: 'Edit'.tr(),
        ),
      // Pin action
      SlidableAction(
        padding: const EdgeInsets.all(0),
        onPressed: (context) async {
          LogService.debug('📌 Note ${note.id} - Pin toggle: ${note.isPinned} -> ${!note.isPinned}');
          final provider = context.read<NotesProvider>();
          final success = await provider.togglePinNote(note.id, !note.isPinned);
          if (success) {
            LogService.debug('✅ Note ${note.id} - Pin status changed');
          } else {
            LogService.error('❌ Note ${note.id} - Pin operation failed');
          }
        },
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.white,
        icon: note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        label: note.isPinned ? 'unpin'.tr() : 'pin'.tr(),
      ),
      SlidableAction(
        padding: const EdgeInsets.all(0),
        onPressed: (context) async {
          LogService.debug('📦 Note ${note.id} - Archive toggle started');
          final provider = context.read<NotesProvider>();
          final success = await provider.toggleArchiveNote(note.id);
          if (success) {
            LogService.debug('✅ Note ${note.id} - Archive status changed');
          } else {
            LogService.error('❌ Note ${note.id} - Archive operation failed');
          }
        },
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        icon: note.isArchived ? Icons.unarchive : Icons.archive,
        label: note.isArchived ? 'unarchive'.tr() : 'archive'.tr(),
      ),
      SlidableAction(
        padding: const EdgeInsets.all(0),
        onPressed: (context) async {
          LogService.debug('🗑️ Note ${note.id} - Delete operation started');
          if (onDelete != null) {
            onDelete!();
            LogService.debug('✅ Note ${note.id} - Deleted');
          } else {
            LogService.error('⚠️ Note ${note.id} - onDelete callback null');
          }
        },
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        icon: Icons.delete,
        label: 'delete'.tr(),
      ),
    ];
  }

  @override
  Widget buildContent(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        // Kategori bilgisini Provider'dan al
        final category = provider.getCategoryById(note.categoryId);
        final categoryColor = category != null ? category.color : AppColors.grey;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and category
                    Row(
                      children: [
                        // Category indicator
                        if (category != null) ...[
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Title
                        Expanded(
                          child: Text(
                            note.title.isNotEmpty ? note.title : 'UntitledNote'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                              decoration: note.isArchived ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Pin göstergesi
                        if (note.isPinned) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.push_pin,
                            size: 16,
                            color: categoryColor,
                          ),
                        ],
                      ],
                    ),
                    // İçerik önizlemesi
                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        note.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.text,
                          decoration: note.isArchived ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Zaman damgası
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(note.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.withValues(alpha: 0.65),
                      ),
                    ),
                    if (note.isArchived) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Archived',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormatter.formatDate(date);
    }
  }
}
