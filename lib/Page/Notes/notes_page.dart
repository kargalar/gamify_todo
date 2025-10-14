import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Widgets/Notes/note_card.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Widgets/Notes/add_category_dialog.dart';
import 'package:next_level/Widgets/Notes/add_edit_note_bottom_sheet.dart';
import 'package:next_level/Widgets/Common/category_filter_widget.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/Common/standard_app_bar.dart';

/// Notlar ana sayfası
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında notları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: LocaleKeys.MyNotes.tr(),
        isSearching: _isSearching,
        onSearchToggle: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchController.clear();
              provider.clearSearchQuery();
            }
          });
          debugPrint('🔍 Search toggled: $_isSearching');
        },
        showArchivedOnly: provider.showArchivedOnly,
        onArchiveToggle: () {
          provider.toggleArchivedFilter();
          debugPrint('📦 Archive filter toggled: ${provider.showArchivedOnly}');
        },
      ),
      body: Consumer<NotesProvider>(
        builder: (context, provider, _) {
          // Yükleniyor
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Hata
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadNotes(),
                    icon: const Icon(Icons.refresh),
                    label: Text(LocaleKeys.Retry.tr()),
                  ),
                ],
              ),
            );
          }

          // Notlar yok
          if (provider.notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.note_add, size: 100, color: AppColors.grey),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.NoNotesYet.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocaleKeys.AddFirstNote.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Inline arama barı (arama aktifse göster)
              if (_isSearching)
                Container(
                  height: 40,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) {
                      provider.updateSearchQuery(value);
                      debugPrint('🔍 Search query: $value');
                    },
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: LocaleKeys.SearchNotes.tr(),
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.text.withValues(alpha: 0.5),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: AppColors.text.withValues(alpha: 0.5),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                provider.clearSearchQuery();
                                debugPrint('🔍 Search cleared');
                              },
                            )
                          : null,
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                      isDense: true,
                    ),
                  ),
                ),

              // Kategori filtreleme
              CategoryFilterWidget(
                categories: provider.categories,
                selectedCategoryId: provider.selectedCategoryId,
                onCategorySelected: (categoryId) => provider.selectCategory(categoryId as String?),
                itemCounts: provider.noteCounts,
                onCategoryLongPress: (context, category) {
                  showDialog(
                    context: context,
                    builder: (context) => AddCategoryDialog(
                      existingCategories: provider.categories,
                      editingCategory: category,
                      onDeleteCategory: (deletedCategory) {
                        provider.deleteCategory(deletedCategory.id);
                      },
                    ),
                  );
                },
                showIcons: true,
                showColors: true,
                showAddButton: true,
                categoryType: CategoryType.note,
              ),

              // Notlar listesi
              Expanded(
                child: _buildNotesList(context, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Kategori ekleme dialogunu göster
  Future<void> _showAddCategoryDialog(BuildContext context, NotesProvider provider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddCategoryDialog(
        existingCategories: provider.categories,
        onDeleteCategory: (category) {
          _showDeleteCategoryDialog(context, provider, category);
        },
      ),
    );

    if (result != null) {
      debugPrint('✅ NotesPage: Category data received from dialog');

      // Yeni kategori oluştur (NOTE TİPİNDE)
      final newCategory = CategoryModel(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        title: result['name'] as String,
        iconCodePoint: result['iconCodePoint'] as int,
        color: Color(result['colorValue'] as int),
        createdAt: DateTime.now(),
        categoryType: CategoryType.note,
      );

      await provider.addCategory(newCategory);

      debugPrint('✅ NotesPage: New category created - ${newCategory.title}');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.CategoryCreated.tr(args: [newCategory.title])),
          backgroundColor: newCategory.color,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      debugPrint('❌ NotesPage: Category creation cancelled');
    }
  }

  Widget _buildNotesList(BuildContext context, NotesProvider provider) {
    final pinnedNotes = provider.pinnedNotes;
    final unpinnedNotes = provider.unpinnedNotes;

    if (provider.filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.NoteNotFound.tr(),
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        // Sabitlenmiş notlar
        if (pinnedNotes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 16, color: AppColors.grey),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.Pinned.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          ...pinnedNotes.map((note) => _buildNoteCard(context, provider, note)),
          const SizedBox(height: 8),
        ],

        // Diğer notlar
        if (unpinnedNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                LocaleKeys.OtherNotes.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey,
                ),
              ),
            ),
          ...unpinnedNotes.map((note) => _buildNoteCard(context, provider, note)),
        ],

        const SizedBox(height: 80), // FAB için boşluk
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context, NotesProvider provider, NoteModel note) {
    return NoteCard(
      note: note,
      onTap: () => _navigateToEditNote(context, note),
      onLongPress: () => _showNoteOptions(context, provider, note),
      onDelete: () => _confirmDelete(context, provider, note),
    );
  }

  void _showNoteOptions(BuildContext context, NotesProvider provider, NoteModel note) {
    final category = provider.categories.firstWhere(
      (cat) => cat.id == note.categoryId,
      orElse: () => provider.categories.first,
    );
    final categoryColor = Color(category.colorValue);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: categoryColor,
                ),
                title: Text(note.isPinned ? LocaleKeys.Unpin.tr() : LocaleKeys.Pin.tr()),
                onTap: () {
                  Navigator.pop(context);
                  provider.togglePinNote(note.id, !note.isPinned);
                  debugPrint('📌 Note pin toggled: ${note.isPinned}');
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: categoryColor),
                title: Text(LocaleKeys.Edit.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditNote(context, note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(LocaleKeys.Delete.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, provider, note);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, NotesProvider provider, NoteModel note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocaleKeys.DeleteNote.tr()),
          content: Text(LocaleKeys.DeleteNoteConfirmation.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                provider.deleteNote(note.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(LocaleKeys.NoteDeleted.tr())),
                );
                debugPrint('✅ Note ${note.id} deleted');
              },
              child: Text(LocaleKeys.Delete.tr(), style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditNote(BuildContext context, NoteModel note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditNoteBottomSheet(note: note),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, NotesProvider provider, CategoryModel category) {
    final count = provider.noteCounts[category.id] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocaleKeys.DeleteCategory.tr()),
          content: Text(
            count > 0 ? tr(LocaleKeys.DeleteCategoryConfirmation, args: [count.toString()]) : LocaleKeys.DeleteCategoryConfirmation.tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await provider.deleteCategory(category.id);
                if (success) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(LocaleKeys.CategoryDeleted.tr())),
                  );
                  debugPrint('✅ Category ${category.id} deleted');
                } else {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocaleKeys.CategoryDeleteFailed.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                  debugPrint('❌ Category ${category.id} deletion failed');
                }
              },
              child: Text(LocaleKeys.Delete.tr(), style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
