import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../General/app_colors.dart';
import '../../Model/project_model.dart';
import '../../Model/project_note_model.dart';
import '../../Provider/projects_provider.dart';
import '../../Service/logging_service.dart';
import './add_project_note_bottom_sheet.dart';

class ProjectNotesSection extends StatefulWidget {
  final ProjectModel project;
  final List<ProjectNoteModel> notes;
  final VoidCallback onNotesChanged;

  const ProjectNotesSection({
    super.key,
    required this.project,
    required this.notes,
    required this.onNotesChanged,
  });

  @override
  State<ProjectNotesSection> createState() => _ProjectNotesSectionState();
}

class _ProjectNotesSectionState extends State<ProjectNotesSection> {
  late List<ProjectNoteModel> _notes;
  ProjectNoteModel? _deletedNote;
  // ignore: unused_field
  int? _deletedNoteIndex;

  @override
  void initState() {
    super.initState();
    _notes = List.from(widget.notes);
  }

  @override
  void didUpdateWidget(ProjectNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _notes = List.from(widget.notes);
  }

  Future<void> _copyAllNotes() {
    if (_notes.isEmpty) {
      LogService.error('⚠️ No notes to copy');
      return Future.value();
    }

    final bulletList = _notes.map((note) {
      String result = '📌 ${note.title ?? "Untitled"}';
      if (note.content != null && note.content!.isNotEmpty) {
        result += '\n    ${note.content}';
      }
      return result;
    }).join('\n\n');

    return Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_notes.length} notes copied'),
            backgroundColor: AppColors.green,
          ),
        );
      }
      LogService.debug('✅ ${_notes.length} notes copied to clipboard');
    });
  }

  void _copyOnlyTitledNotes() {
    final titled = _notes.where((n) => n.title != null && n.title!.isNotEmpty).toList();
    if (titled.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No titled notes'),
            backgroundColor: AppColors.text.withValues(alpha: 0.7),
          ),
        );
      }
      LogService.error('⚠️ No titled notes to copy');
      return;
    }

    final bulletList = titled.map((note) => '📌 ${note.title}').join('\n');

    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${titled.length} note titles copied'),
            backgroundColor: AppColors.green,
          ),
        );
      }
      LogService.debug('✅ ${titled.length} note titles copied');
    });
  }

  Future<void> _clearAllNotes() async {
    final provider = context.read<ProjectsProvider>();
    for (final note in _notes) {
      await provider.deleteProjectNote(note.id);
    }
    widget.onNotesChanged();
    LogService.debug('🗑️ All notes deleted');
  }

  @override
  Widget build(BuildContext context) {
    if (_notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.note_outlined, size: 14, color: AppColors.yellow),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: AppColors.text.withValues(alpha: 0.6)),
                onSelected: (value) async {
                  switch (value) {
                    case 'copy_all':
                      await _copyAllNotes();
                      break;
                    case 'copy_titled':
                      _copyOnlyTitledNotes();
                      break;
                    case 'clear_all':
                      await _clearAllNotes();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy_all',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 16),
                        SizedBox(width: 12),
                        Text('Copy all notes'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy_titled',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 16),
                        SizedBox(width: 12),
                        Text('Copy titles only'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, size: 16, color: AppColors.red),
                        SizedBox(width: 12),
                        Text('Delete all notes', style: TextStyle(color: AppColors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          proxyDecorator: (child, index, animation) {
            return Material(
              color: Colors.transparent,
              child: child,
            );
          },
          onReorder: (oldIndex, newIndex) async {
            if (oldIndex < newIndex) newIndex -= 1;

            setState(() {
              final item = _notes.removeAt(oldIndex);
              _notes.insert(newIndex, item);
            });

            final provider = context.read<ProjectsProvider>();
            for (int i = 0; i < _notes.length; i++) {
              _notes[i].orderIndex = i;
              await provider.updateProjectNote(_notes[i]);
            }

            if (mounted) {
              setState(() {});
              widget.onNotesChanged();
            }

            LogService.debug('✅ Notes reordered in ${widget.project.title}');
          },
          children: _notes.asMap().entries.map((entry) {
            final index = entry.key;
            final note = entry.value;
            return _buildNoteItem(context, note, index);
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildNoteItem(BuildContext context, ProjectNoteModel note, int index) {
    return ReorderableDelayedDragStartListener(
      key: ValueKey(note.id),
      index: index,
      child: Slidable(
        key: ValueKey(note.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          dismissible: DismissiblePane(
            dismissThreshold: 0.3,
            closeOnCancel: true,
            confirmDismiss: () async {
              return true;
            },
            onDismissed: () async {
              // Store deleted note for undo
              _deletedNote = note;
              _deletedNoteIndex = _notes.indexOf(note);

              final provider = context.read<ProjectsProvider>();
              await provider.deleteProjectNote(note.id);
              widget.onNotesChanged();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Note deleted'),
                    backgroundColor: AppColors.red,
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppColors.white,
                      onPressed: () async {
                        if (_deletedNote != null) {
                          final provider = context.read<ProjectsProvider>();
                          await provider.addProjectNote(_deletedNote!);
                          widget.onNotesChanged();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Note restored'),
                                backgroundColor: AppColors.green,
                              ),
                            );
                          }
                          LogService.debug('↩️ Note restored: ${_deletedNote!.title}');
                          _deletedNote = null;
                          _deletedNoteIndex = null;
                        }
                      },
                    ),
                  ),
                );
              }
              LogService.debug('🗑️ Note deleted: ${note.title}');
            },
          ),
          children: [
            SlidableAction(
              onPressed: (_) async {
                // Store deleted note for undo
                _deletedNote = note;
                _deletedNoteIndex = _notes.indexOf(note);

                final provider = context.read<ProjectsProvider>();
                await provider.deleteProjectNote(note.id);
                widget.onNotesChanged();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Note deleted'),
                      backgroundColor: AppColors.red,
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: AppColors.white,
                        onPressed: () async {
                          if (_deletedNote != null) {
                            final provider = context.read<ProjectsProvider>();
                            await provider.addProjectNote(_deletedNote!);
                            widget.onNotesChanged();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Note restored'),
                                  backgroundColor: AppColors.green,
                                ),
                              );
                            }
                            LogService.debug('↩️ Note restored: ${_deletedNote!.title}');
                            _deletedNote = null;
                            _deletedNoteIndex = null;
                          }
                        },
                      ),
                    ),
                  );
                }
                LogService.debug('🗑️ Note deleted: ${note.title}');
              },
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
              icon: Icons.delete,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddProjectNoteBottomSheet(
                initialTitle: note.title,
                initialContent: note.content,
                onSave: (title, content) async {
                  final provider = context.read<ProjectsProvider>();
                  note.title = title;
                  note.content = content;
                  note.updatedAt = DateTime.now();
                  await provider.updateProjectNote(note);
                  widget.onNotesChanged();
                  LogService.debug('✅ Note updated: $title');
                },
              ),
            );
          },
          child: Container(
            key: ValueKey(note.id),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.panelBackground2,
                  AppColors.panelBackground2.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.yellow.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.sticky_note_2,
                    size: 12,
                    color: AppColors.yellow,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.title != null && note.title!.isNotEmpty)
                        Text(
                          note.title!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      if (note.content != null && note.content!.isNotEmpty)
                        Text(
                          note.content!,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.text.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
