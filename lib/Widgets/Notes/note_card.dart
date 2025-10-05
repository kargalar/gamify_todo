import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/General/app_colors.dart';

/// Kompakt ve sade not kartı widget'ı (Slidable actions ile)
class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onPinToggle;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    this.onPinToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        // Kategori bilgisini Provider'dan al
        final category = provider.getCategoryById(note.categoryId);
        final categoryColor = category != null ? Color(category.colorValue) : AppColors.grey;

        return Slidable(
          key: ValueKey(note.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.4,
            children: [
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
            ],
          ),
          child: Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Sol taraf: Kategori ikonu
                    if (category != null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                          size: 18,
                          color: categoryColor,
                        ),
                      ),

                    const SizedBox(width: 12),

                    // Orta: Başlık ve tarih
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Başlık satırı
                          Row(
                            children: [
                              if (note.isPinned)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.push_pin,
                                    size: 12,
                                    color: AppColors.yellow,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // İçerik önizlemesi (varsa)
                          if (note.content.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              note.content,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.text.withValues(alpha: 0.6),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Sağ taraf: Kategori adı (küçük badge)
                    if (category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: categoryColor,
                          ),
                        ),
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
}
