import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Widgets/Notes/note_card.dart';
import 'package:next_level/Page/Notes/add_edit_note_page.dart';
import 'package:next_level/General/app_colors.dart';

/// Notlar ana sayfası
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notlarım',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // Arama butonu
          Consumer<NotesProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.searchQuery.isEmpty ? Icons.search : Icons.search_off,
                ),
                onPressed: () {
                  if (provider.searchQuery.isEmpty) {
                    _showSearchDialog(context, provider);
                  } else {
                    provider.clearSearchQuery();
                    _searchController.clear();
                  }
                },
              );
            },
          ),
        ],
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
                    const Icon(Icons.all_inclusive, size: 16),
                    const SizedBox(width: 6),
                    const Text('Tümü'),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.notes.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                selectedColor: AppColors.text,
                backgroundColor: AppColors.panelBackground,
                checkmarkColor: Colors.white,
                onSelected: (_) => provider.selectCategory(null),
                labelStyle: TextStyle(
                  color: AppColors.text,
                  fontWeight: provider.selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                ),
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
              );
            }),
          ],
        ),
      ),
    );
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

  Widget _buildNoteCard(BuildContext context, NotesProvider provider, note) {
    return NoteCard(
      note: note,
      onTap: () => _navigateToEditNote(context, note),
      onLongPress: () => _showNoteOptions(context, provider, note),
    );
  }

  void _showNoteOptions(BuildContext context, NotesProvider provider, note) {
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
                  color: note.categoryEnum.color,
                ),
                title: Text(note.isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle'),
                onTap: () {
                  Navigator.pop(context);
                  provider.togglePinNote(note.id, !note.isPinned);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: note.categoryEnum.color),
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

  void _confirmDelete(BuildContext context, NotesProvider provider, note) {
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
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Not Ara'),
          content: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Başlık, içerik veya etiket...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              provider.updateSearchQuery(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.clearSearchQuery();
                _searchController.clear();
                Navigator.pop(context);
              },
              child: const Text('Temizle'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditNote(BuildContext context, note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNotePage(note: note),
      ),
    );
  }
}
