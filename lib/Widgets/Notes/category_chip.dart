import 'package:flutter/material.dart';
import 'package:next_level/Enum/note_category_enum.dart';

/// Kategori seçimi için chip widget
class CategoryChip extends StatelessWidget {
  final NoteCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final int? noteCount;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.noteCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: isSelected ? Colors.white : category.color,
            ),
            const SizedBox(width: 6),
            Text(category.displayName),
            if (noteCount != null && noteCount! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withValues(alpha: 0.3) 
                      : category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$noteCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : category.color,
                  ),
                ),
              ),
            ],
          ],
        ),
        selectedColor: category.color,
        backgroundColor: category.color.withValues(alpha: 0.1),
        checkmarkColor: Colors.white,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : category.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? category.color : category.color.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}
