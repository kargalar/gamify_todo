import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';

/// Notlar ve Projeler sayfaları için standart AppBar
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSearching;
  final VoidCallback onSearchToggle;
  final bool showArchivedOnly;
  final VoidCallback onArchiveToggle;

  const StandardAppBar({
    super.key,
    required this.title,
    required this.isSearching,
    required this.onSearchToggle,
    required this.showArchivedOnly,
    required this.onArchiveToggle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      actions: [
        // Arama butonu
        IconButton(
          icon: Icon(
            isSearching ? Icons.search_off : Icons.search,
          ),
          onPressed: onSearchToggle,
        ),
        // Arşiv butonu
        IconButton(
          icon: Icon(
            showArchivedOnly ? Icons.unarchive : Icons.archive,
            color: showArchivedOnly ? AppColors.orange : null,
          ),
          onPressed: onArchiveToggle,
        ),
      ],
    );
  }
}
