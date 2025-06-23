import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:file_picker/file_picker.dart';

class AddTaskProvider with ChangeNotifier {
  // Widget variables
  TaskModel? editTask;
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  // Focus nodes for managing keyboard focus
  final FocusNode taskNameFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();
  final FocusNode locationFocus = FocusNode();
  final FocusNode subtaskFocus = FocusNode();

  TimeOfDay? selectedTime;
  DateTime? selectedDate = DateTime.now();
  bool isNotificationOn = false;
  bool isAlarmOn = false;
  int targetCount = 1;
  Duration taskDuration = const Duration(hours: 0, minutes: 0);
  TaskTypeEnum selectedTaskType = TaskTypeEnum.CHECKBOX;
  List<int> selectedDays = [];
  List<TraitModel> selectedTraits = [];
  int priority = 3;
  List<SubTaskModel> subtasks = [];
  int? categoryId;
  int? earlyReminderMinutes; // Erken hatırlatma süresi (dakika cinsinden)

  // File attachments
  List<String> attachmentPaths = [];

  // Undo functionality for deleted subtasks
  final Map<int, SubTaskModel> _deletedSubtasks = {};
  final Map<int, Timer> _undoTimers = {};

  void updateTime(TimeOfDay? time) {
    selectedTime = time;

    notifyListeners();
  }

  void updatePriority(int value) {
    priority = value;

    notifyListeners();
  }

  void updateTargetCount(int value) {
    targetCount = value;

    notifyListeners();
  }

  void updateTraitSelection() {
    notifyListeners();
  }

  void addSubtask(SubTaskModel subtask) {
    subtasks.add(subtask);
    notifyListeners();
  }

  void updateSubtask(int index, SubTaskModel updatedSubtask) {
    if (index >= 0 && index < subtasks.length) {
      subtasks[index] = updatedSubtask;
      notifyListeners();
    }
  }

  void removeSubtask(int index, {bool showUndo = true}) {
    if (index >= 0 && index < subtasks.length) {
      final subtask = subtasks[index];

      if (showUndo) {
        // Store the subtask and its index for potential undo
        _deletedSubtasks[index] = subtask;

        // Remove from UI immediately
        subtasks.removeAt(index);
        notifyListeners(); // Show undo snackbar
        Helper().getUndoMessage(
          message: "Subtask deleted",
          onUndo: () => _undoRemoveSubtask(index, subtask),
          statusColor: AppColors.red,
          statusWord: "deleted",
        );

        // Set timer for permanent deletion
        _undoTimers[index] = Timer(const Duration(seconds: 3), () {
          _permanentlyRemoveSubtask(index);
        });
      } else {
        // Direct removal without undo
        subtasks.removeAt(index);
        notifyListeners();
      }
    }
  }

  // Permanently remove a subtask
  void _permanentlyRemoveSubtask(int index) {
    _deletedSubtasks.remove(index);
    _undoTimers.remove(index);
  }

  // Undo subtask removal
  void _undoRemoveSubtask(int originalIndex, SubTaskModel subtask) {
    final timer = _undoTimers.remove(originalIndex);
    _deletedSubtasks.remove(originalIndex);

    if (timer != null) {
      timer.cancel();

      // Insert the subtask back at its original position or at the end if position is no longer valid
      if (originalIndex <= subtasks.length) {
        subtasks.insert(originalIndex, subtask);
      } else {
        subtasks.add(subtask);
      }

      notifyListeners();
    }
  }

  void clearSubtasks() {
    subtasks.clear();
    notifyListeners();
  }

  void toggleSubtaskCompletion(int index) {
    if (index >= 0 && index < subtasks.length) {
      subtasks[index].isCompleted = !subtasks[index].isCompleted;
      notifyListeners();
    }
  }

  void loadSubtasksFromTask(TaskModel task) {
    if (task.subtasks != null) {
      subtasks = List.from(task.subtasks!);
    } else {
      subtasks = [];
    }
    notifyListeners();
  }

  void updateCategory(int? id) {
    categoryId = id;
    notifyListeners();
  }

  void updateEarlyReminderMinutes(int? minutes) {
    earlyReminderMinutes = minutes;
    notifyListeners();
  }

  // Bildirim durumu değiştiğinde tüm bağımlı widget'ları güncelle
  void refreshNotificationStatus() {
    notifyListeners();
  }

  void updateLocation() {
    notifyListeners();
  }

  // Method to unfocus all text fields
  void unfocusAll() {
    try {
      if (taskNameFocus.hashCode != 0) {
        taskNameFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }

    try {
      if (descriptionFocus.hashCode != 0) {
        descriptionFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }

    try {
      if (locationFocus.hashCode != 0) {
        locationFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }

    try {
      if (subtaskFocus.hashCode != 0) {
        subtaskFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }
  }

  // Dispose focus nodes when provider is disposed
  void disposeFocusNodes() {
    try {
      if (taskNameFocus.hashCode != 0) {
        taskNameFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }

    try {
      if (descriptionFocus.hashCode != 0) {
        descriptionFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }

    try {
      if (locationFocus.hashCode != 0) {
        locationFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }

    try {
      if (subtaskFocus.hashCode != 0) {
        subtaskFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }
  }

  // File attachment methods
  Future<String> _getApplicationDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${directory.path}/task_attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir.path;
  }

  Future<String> _copyFileToAppDirectory(String originalPath) async {
    try {
      final file = File(originalPath);
      if (!await file.exists()) {
        throw Exception('Source file does not exist');
      }

      final appDir = await _getApplicationDirectory();
      final fileName = path.basename(originalPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final newPath = path.join(appDir, newFileName);

      final copiedFile = await file.copy(newPath);
      return copiedFile.path;
    } catch (e) {
      debugPrint('Error copying file: $e');
      rethrow;
    }
  }

  Future<void> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowedExtensions: null,
      );

      if (result != null) {
        List<String> selectedPaths = result.paths.where((path) => path != null).cast<String>().toList();

        // Dosyaları uygulama dizinine kopyala
        for (String originalPath in selectedPaths) {
          try {
            String copiedPath = await _copyFileToAppDirectory(originalPath);
            attachmentPaths.add(copiedPath);
          } catch (e) {
            debugPrint('Failed to copy file $originalPath: $e');
            // Kopyalama başarısız olursa orijinal path'i kullan
            attachmentPaths.add(originalPath);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  Future<void> pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null) {
        List<String> selectedPaths = result.paths.where((path) => path != null).cast<String>().toList();

        // Resimleri uygulama dizinine kopyala
        for (String originalPath in selectedPaths) {
          try {
            String copiedPath = await _copyFileToAppDirectory(originalPath);
            attachmentPaths.add(copiedPath);
          } catch (e) {
            debugPrint('Failed to copy image $originalPath: $e');
            // Kopyalama başarısız olursa orijinal path'i kullan
            attachmentPaths.add(originalPath);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void removeAttachment(int index) async {
    if (index >= 0 && index < attachmentPaths.length) {
      final filePath = attachmentPaths[index];

      // Eğer dosya uygulama dizinindeyse sil
      try {
        final appDir = await _getApplicationDirectory();
        if (filePath.startsWith(appDir)) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }

      attachmentPaths.removeAt(index);
      notifyListeners();
    }
  }

  void clearAttachments() async {
    // Tüm dosyaları sil
    try {
      final appDir = await _getApplicationDirectory();
      for (String filePath in attachmentPaths) {
        if (filePath.startsWith(appDir)) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing attachments: $e');
    }

    attachmentPaths.clear();
    notifyListeners();
  }

  void loadAttachmentsFromTask(TaskModel task) {
    if (task.attachmentPaths != null) {
      attachmentPaths = List.from(task.attachmentPaths!);
    } else {
      attachmentPaths = [];
    }
    notifyListeners();
  }

  // Task'ı kalıcı olarak silerken dosyaları da sil
  Future<void> deleteTaskAttachments() async {
    try {
      final appDir = await _getApplicationDirectory();
      for (String filePath in attachmentPaths) {
        if (filePath.startsWith(appDir)) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting task attachments: $e');
    }
  }

  @override
  void dispose() {
    // Cancel any pending undo timers
    for (final timer in _undoTimers.values) {
      timer.cancel();
    }
    _undoTimers.clear();
    _deletedSubtasks.clear();

    // Dispose controllers and focus nodes safely
    try {
      taskNameController.dispose();
    } catch (e) {
      // Controller may already be disposed
    }

    try {
      descriptionController.dispose();
    } catch (e) {
      // Controller may already be disposed
    }

    try {
      locationController.dispose();
    } catch (e) {
      // Controller may already be disposed
    }

    disposeFocusNodes();
    super.dispose();
  }
}
