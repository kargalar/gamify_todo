import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Widgets/Common/base_card.dart';

/// Kompakt ve sade not kartı widget'ı (Slidable actions ile)
class NoteCard extends BaseCard {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onPinToggle;
  final VoidCallback? onDelete;

  NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    this.onPinToggle,
    this.onDelete,
  }) : super(itemId: note.id.toString());

  @override
  List<SlidableAction> buildActions(BuildContext context) {
    final provider = context.read<NotesProvider>();
    final category = provider.getCategoryById(note.categoryId);
    final categoryColor = category != null ? category.color : AppColors.grey;

    return [
      SlidableAction(
        onPressed: (context) async {
          debugPrint('📌 Note ${note.id} - Pin toggle: ${note.isPinned} -> ${!note.isPinned}');
          final success = await provider.togglePinNote(note.id, !note.isPinned);
          if (success) {
            debugPrint('✅ Note ${note.id} - Pin durumu değiştirildi');
          } else {
            debugPrint('❌ Note ${note.id} - Pin işlemi başarısız');
          }
        },
        backgroundColor: note.isPinned ? AppColors.grey : categoryColor,
        icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
        label: note.isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle',
        padding: const EdgeInsets.symmetric(horizontal: 5),
      ),
      SlidableAction(
        onPressed: (context) async {
          debugPrint('📦 Note ${note.id} - Archive toggle başladı');
          final success = await provider.toggleArchiveNote(note.id);
          if (success) {
            debugPrint('✅ Note ${note.id} - Archive durumu değiştirildi');
          } else {
            debugPrint('❌ Note ${note.id} - Archive işlemi başarısız');
          }
        },
        backgroundColor: AppColors.orange,
        icon: note.isArchived ? Icons.unarchive : Icons.archive,
        label: note.isArchived ? 'Geri Al' : 'Arşivle',
        padding: const EdgeInsets.symmetric(horizontal: 5),
      ),
      SlidableAction(
        onPressed: (context) async {
          debugPrint('🗑️ Note ${note.id} - Silme işlemi başladı');
          if (onDelete != null) {
            onDelete!();
            debugPrint('✅ Note ${note.id} - Silindi');
          } else {
            debugPrint('⚠️ Note ${note.id} - onDelete callback null');
          }
        },
        backgroundColor: AppColors.red,
        icon: Icons.delete,
        label: 'Sil',
        padding: const EdgeInsets.symmetric(horizontal: 5),
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
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve kategori
                    Row(
                      children: [
                        // Kategori göstergesi
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
                        // Başlık
                        Expanded(
                          child: Text(
                            note.title.isNotEmpty ? note.title : 'Başlıksız Not',
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
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.text.withValues(alpha: 0.65),
                        ),
                        const SizedBox(width: 4),
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
                              'Arşivlenmiş',
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
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
