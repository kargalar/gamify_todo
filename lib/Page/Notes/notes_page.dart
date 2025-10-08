import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Widgets/Notes/note_card.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/note_category_model.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Widgets/Notes/add_category_dialog.dart';
import 'package:next_level/Widgets/Notes/add_edit_note_bottom_sheet.dart';
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
        title: 'Notlarım',
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
                    label: const Text('Yeniden Dene'),
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
                    'Henüz not eklemediniz',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sağ alttaki + butonuna basarak\nilk notunuzu ekleyin',
                    style: TextStyle(
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
                      hintText: 'Başlık veya içerik ara...',
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
              _buildCategoryFilter(context, provider),

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

  Widget _buildCategoryFilter(BuildContext context, NotesProvider provider) {
    final noteCounts = provider.noteCounts;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Tümü
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: provider.selectedCategory == null,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      size: 16,
                      color: provider.selectedCategory == null ? Colors.white : AppColors.text,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tümü',
                      style: TextStyle(
                        color: provider.selectedCategory == null ? Colors.white : AppColors.text,
                        fontWeight: provider.selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: provider.selectedCategory == null ? Colors.white.withValues(alpha: 0.3) : AppColors.panelBackground2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.notes.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: provider.selectedCategory == null ? Colors.white : AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                selectedColor: AppColors.text,
                backgroundColor: AppColors.panelBackground,
                checkmarkColor: Colors.white,
                onSelected: (_) => provider.selectCategory(null),
              ),
            ),

            // Kategoriler
            ...provider.categories.map((category) {
              final count = noteCounts[category.id] ?? 0;
              // Sadece notu olan kategorileri göster
              if (count == 0 && provider.selectedCategoryId != category.id) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onLongPress: () => _showDeleteCategoryDialog(context, provider, category),
                  child: FilterChip(
                    selected: provider.selectedCategoryId == category.id,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(category.name),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    selectedColor: Color(category.colorValue).withValues(alpha: 0.3),
                    backgroundColor: AppColors.panelBackground,
                    checkmarkColor: Color(category.colorValue),
                    onSelected: (_) => provider.selectCategory(
                      provider.selectedCategoryId == category.id ? null : category.id,
                    ),
                    labelStyle: TextStyle(
                      color: AppColors.text,
                      fontWeight: provider.selectedCategoryId == category.id ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),

            // Yeni Kategori Ekle butonu
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildAddCategoryButton(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  /// Yeni kategori ekleme butonu
  Widget _buildAddCategoryButton(BuildContext context, NotesProvider provider) {
    return ActionChip(
      label: Icon(
        Icons.add_circle_outline,
        size: 20,
        color: AppColors.main,
      ),
      onPressed: () => _showAddCategoryDialog(context, provider),
      backgroundColor: AppColors.panelBackground,
      side: BorderSide(
        color: AppColors.main,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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

      // Yeni kategori oluştur
      final newCategory = NoteCategoryModel(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: result['name'] as String,
        iconCodePoint: result['iconCodePoint'] as int,
        colorValue: result['colorValue'] as int,
        createdAt: DateTime.now(),
      );

      await provider.addCategory(newCategory);

      debugPrint('✅ NotesPage: New category created - ${newCategory.name}');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newCategory.name} kategorisi oluşturuldu'),
          backgroundColor: Color(newCategory.colorValue),
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
              'Not bulunamadı',
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.push_pin, size: 16, color: AppColors.grey),
                SizedBox(width: 6),
                Text(
                  'Sabitlenmiş',
                  style: TextStyle(
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Diğer Notlar',
                style: TextStyle(
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
                title: Text(note.isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle'),
                onTap: () {
                  Navigator.pop(context);
                  provider.togglePinNote(note.id, !note.isPinned);
                  debugPrint('📌 Note pin toggled: ${note.isPinned}');
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: categoryColor),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditNote(context, note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Sil'),
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
          title: const Text('Notu Sil'),
          content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                provider.deleteNote(note.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not silindi')),
                );
                debugPrint('✅ Note ${note.id} deleted');
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
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

  void _showDeleteCategoryDialog(BuildContext context, NotesProvider provider, NoteCategoryModel category) {
    final count = provider.noteCounts[category.id] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kategoriyi Sil'),
          content: Text(
            count > 0 ? 'Bu kategoriye ait $count not var. Kategori silinirse bu notlar kategorisiz kalacak. Devam etmek istiyor musunuz?' : 'Bu kategoriyi silmek istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await provider.deleteCategory(category.id);
                if (success) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori silindi')),
                  );
                  debugPrint('✅ Category ${category.id} deleted');
                } else {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategori silinemedi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  debugPrint('❌ Category ${category.id} deletion failed');
                }
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
