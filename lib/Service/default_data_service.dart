import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// İlk yüklemede varsayılan kategoriler ve görevler oluşturan servis
class DefaultDataService {
  static const String _firstLaunchKey = 'is_first_launch';

  /// İlk yükleme kontrolü yapar ve gerekirse varsayılan verileri yükler
  static Future<void> checkAndLoadDefaultData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

      LogService.debug('🔍 DefaultDataService: İlk yükleme kontrolü - isFirstLaunch: $isFirstLaunch');

      if (isFirstLaunch) {
        LogService.debug('🎉 DefaultDataService: İlk yükleme tespit edildi, varsayılan veriler yükleniyor...');
        await _loadDefaultData();
        await prefs.setBool(_firstLaunchKey, false);
        LogService.debug('✅ DefaultDataService: Varsayılan veriler başarıyla yüklendi');
      } else {
        LogService.debug('ℹ️ DefaultDataService: İlk yükleme değil, varsayılan veriler atlandı');
      }
    } catch (e) {
      LogService.error('❌ DefaultDataService: Varsayılan veri yükleme hatası: $e');
    }
  }

  /// Varsayılan kategorileri ve görevleri yükler
  static Future<void> _loadDefaultData() async {
    try {
      // Önce kategorileri oluştur
      final categories = await _createDefaultCategories();
      LogService.debug('✅ DefaultDataService: ${categories.length} kategori oluşturuldu');

      // Traits (Attributes & Skills) oluştur
      final traits = await _createDefaultTraits();
      LogService.debug('✅ DefaultDataService: ${traits.length} trait oluşturuldu');

      // Store items oluştur
      await _createDefaultStoreItems();
      LogService.debug('✅ DefaultDataService: Store items oluşturuldu');

      // Sonra görevleri oluştur
      await _createDefaultTasks(categories);
      LogService.debug('✅ DefaultDataService: Varsayılan görevler oluşturuldu');

      // Projeler oluştur
      await _createDefaultProjects(categories);
      LogService.debug('✅ DefaultDataService: Varsayılan projeler oluşturuldu');

      // Notlar oluştur
      await _createDefaultNotes(categories);
      LogService.debug('✅ DefaultDataService: Varsayılan notlar oluşturuldu');
    } catch (e) {
      LogService.error('❌ DefaultDataService: _loadDefaultData hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan kategorileri oluşturur
  static Future<List<CategoryModel>> _createDefaultCategories() async {
    final categories = <CategoryModel>[];
    final categoryProvider = CategoryProvider();

    try {
      // İş kategorisi
      final workCategory = CategoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Work',
        colorValue: AppColors.blue.value,
        iconCodePoint: Icons.work.codePoint,
        categoryType: CategoryType.task,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(workCategory);
      categories.add(workCategory);
      LogService.debug('✅ DefaultDataService: İş kategorisi oluşturuldu');

      // Kişisel kategorisi
      final personalCategory = CategoryModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        title: 'Personal',
        colorValue: AppColors.green.value,
        iconCodePoint: Icons.person.codePoint,
        categoryType: CategoryType.task,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(personalCategory);
      categories.add(personalCategory);
      LogService.debug('✅ DefaultDataService: Kişisel kategorisi oluşturuldu');

      // Sağlık kategorisi
      final healthCategory = CategoryModel(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        title: 'Health',
        colorValue: AppColors.red.value,
        iconCodePoint: Icons.favorite.codePoint,
        categoryType: CategoryType.task,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(healthCategory);
      categories.add(healthCategory);
      LogService.debug('✅ DefaultDataService: Sağlık kategorisi oluşturuldu');

      // Alışveriş kategorisi
      final shoppingCategory = CategoryModel(
        id: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
        title: 'Shopping',
        colorValue: AppColors.orange.value,
        iconCodePoint: Icons.shopping_cart.codePoint,
        categoryType: CategoryType.task,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(shoppingCategory);
      categories.add(shoppingCategory);
      LogService.debug('✅ DefaultDataService: Alışveriş kategorisi oluşturuldu');

      return categories;
    } catch (e) {
      LogService.error('❌ DefaultDataService: Kategori oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan görevleri oluşturur
  static Future<void> _createDefaultTasks(List<CategoryModel> categories) async {
    final taskProvider = TaskProvider();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    try {
      // Task ID başlangıcı
      int taskId = DateTime.now().millisecondsSinceEpoch;

      // İş kategorisi görevleri
      if (categories.isNotEmpty) {
        final workCategory = categories[0];

        // Email kontrolü
        final emailTask = TaskModel(
          id: taskId++,
          title: 'Check emails',
          description: 'Review and respond to important emails',
          type: TaskTypeEnum.CHECKBOX,
          taskDate: today,
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          categoryId: workCategory.id,
        );
        await ServerManager().addTask(taskModel: emailTask);
        taskProvider.taskList.add(emailTask);
        LogService.debug('✅ DefaultDataService: Email kontrolü görevi oluşturuldu');

        // Toplantıya hazırlık
        final meetingTask = TaskModel(
          id: taskId++,
          title: 'Prepare for meeting',
          description: 'Review presentation and prepare notes',
          type: TaskTypeEnum.CHECKBOX,
          taskDate: today,
          time: const TimeOfDay(hour: 14, minute: 0),
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          priority: 1,
          categoryId: workCategory.id,
          currentDuration: Duration.zero,
          remainingDuration: const Duration(hours: 1),
          isPinned: true,
        );
        await ServerManager().addTask(taskModel: meetingTask);
        taskProvider.taskList.add(meetingTask);
        LogService.debug('✅ DefaultDataService: Toplantı hazırlık görevi oluşturuldu');
      }

      // Kişisel kategorisi görevleri
      if (categories.length > 1) {
        final personalCategory = categories[1];

        // Kitap okuma
        final readingTask = TaskModel(id: taskId++, title: 'Read book', type: TaskTypeEnum.TIMER, taskDate: today, isNotificationOn: false, isAlarmOn: false, status: null, priority: 3, categoryId: personalCategory.id, currentCount: 0, remainingDuration: Duration(minutes: 30));
        await ServerManager().addTask(taskModel: readingTask);
        taskProvider.taskList.add(readingTask);
        LogService.debug('✅ DefaultDataService: Kitap okuma görevi oluşturuldu');

        // Arkadaşı ara
        final callFriendTask = TaskModel(
          id: taskId++,
          title: 'Call Micheal Scott',
          description: null,
          type: TaskTypeEnum.CHECKBOX,
          taskDate: tomorrow,
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          priority: 3,
          categoryId: personalCategory.id,
        );
        await ServerManager().addTask(taskModel: callFriendTask);
        taskProvider.taskList.add(callFriendTask);
        LogService.debug('✅ DefaultDataService: Arkadaş arama görevi oluşturuldu');
      }

      // Sağlık kategorisi görevleri
      if (categories.length > 2) {
        final healthCategory = categories[2];

        // Egzersiz
        final exerciseTask = TaskModel(
          id: taskId++,
          title: 'Morning exercise',
          description: '30 minutes cardio workout',
          type: TaskTypeEnum.TIMER,
          taskDate: today,
          time: const TimeOfDay(hour: 7, minute: 0),
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          categoryId: healthCategory.id,
          currentDuration: Duration.zero,
          remainingDuration: const Duration(minutes: 30),
        );
        await ServerManager().addTask(taskModel: exerciseTask);
        taskProvider.taskList.add(exerciseTask);
        LogService.debug('✅ DefaultDataService: Egzersiz görevi oluşturuldu');

        // Su içme
        final waterTask = TaskModel(
          id: taskId++,
          title: 'Drink water',
          description: 'Drink 8 glasses of water today',
          type: TaskTypeEnum.COUNTER,
          taskDate: today,
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          categoryId: healthCategory.id,
          currentCount: 0,
          targetCount: 8,
        );
        await ServerManager().addTask(taskModel: waterTask);
        taskProvider.taskList.add(waterTask);
        LogService.debug('✅ DefaultDataService: Su içme görevi oluşturuldu');
      }

      // Alışveriş kategorisi görevleri
      if (categories.length > 3) {
        final shoppingCategory = categories[3];

        // Market alışverişi - subtask'larla
        final groceryTask = TaskModel(
          id: taskId++,
          title: 'Buy groceries',
          description: null,
          type: TaskTypeEnum.CHECKBOX,
          taskDate: tomorrow,
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          priority: 2,
          categoryId: shoppingCategory.id,
          subtasks: [
            SubTaskModel(
              id: 1,
              title: 'Milk',
              isCompleted: false,
            ),
            SubTaskModel(
              id: 2,
              title: 'Bread',
              isCompleted: false,
            ),
            SubTaskModel(
              id: 3,
              title: 'Eggs',
              isCompleted: false,
            ),
            SubTaskModel(
              id: 4,
              title: 'Fruits',
              isCompleted: false,
            ),
          ],
        );
        await ServerManager().addTask(taskModel: groceryTask);
        taskProvider.taskList.add(groceryTask);
        LogService.debug('✅ DefaultDataService: Market alışverişi görevi oluşturuldu (4 subtask ile)');
      }

      LogService.debug('✅ DefaultDataService: Tüm varsayılan görevler oluşturuldu');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Görev oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan traits (attributes & skills) oluşturur
  static Future<List<TraitModel>> _createDefaultTraits() async {
    final traits = <TraitModel>[];
    final traitProvider = TraitProvider();

    try {
      int traitId = DateTime.now().millisecondsSinceEpoch;

      // Attributes (Özellikler)
      final wisdomAttribute = TraitModel(
        id: traitId++,
        title: 'Wisdom',
        icon: '🦉',
        color: AppColors.blue,
        type: TraitTypeEnum.ATTRIBUTE,
      );
      traitProvider.addTrait(wisdomAttribute);
      traits.add(wisdomAttribute);
      LogService.debug('✅ DefaultDataService: Wisdom attribute oluşturuldu');

      final powerAttribute = TraitModel(
        id: traitId++,
        title: 'Power',
        icon: '💪',
        color: AppColors.red,
        type: TraitTypeEnum.ATTRIBUTE,
      );
      traitProvider.addTrait(powerAttribute);
      traits.add(powerAttribute);
      LogService.debug('✅ DefaultDataService: Power attribute oluşturuldu');

      final creativityAttribute = TraitModel(
        id: traitId++,
        title: 'Creativity',
        icon: '🎨',
        color: AppColors.purple,
        type: TraitTypeEnum.ATTRIBUTE,
      );
      traitProvider.addTrait(creativityAttribute);
      traits.add(creativityAttribute);
      LogService.debug('✅ DefaultDataService: Creativity attribute oluşturuldu');

      // Skills (Yetenekler)
      final programmingSkill = TraitModel(
        id: traitId++,
        title: 'Programming',
        icon: '💻',
        color: AppColors.green,
        type: TraitTypeEnum.SKILL,
      );
      traitProvider.addTrait(programmingSkill);
      traits.add(programmingSkill);
      LogService.debug('✅ DefaultDataService: Programming skill oluşturuldu');

      final communicationSkill = TraitModel(
        id: traitId++,
        title: 'Communication',
        icon: '💬',
        color: AppColors.blue,
        type: TraitTypeEnum.SKILL,
      );
      traitProvider.addTrait(communicationSkill);
      traits.add(communicationSkill);
      LogService.debug('✅ DefaultDataService: Communication skill oluşturuldu');

      final fitnessSkill = TraitModel(
        id: traitId++,
        title: 'Fitness',
        icon: '🏋️',
        color: AppColors.orange,
        type: TraitTypeEnum.SKILL,
      );
      traitProvider.addTrait(fitnessSkill);
      traits.add(fitnessSkill);
      LogService.debug('✅ DefaultDataService: Fitness skill oluşturuldu');

      return traits;
    } catch (e) {
      LogService.error('❌ DefaultDataService: Trait oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan store items oluşturur
  static Future<void> _createDefaultStoreItems() async {
    final storeProvider = StoreProvider();

    try {
      // Timer item - 1 saat oyun
      final gameHourItem = ItemModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Gaming',
        description: 'Reward yourself with gaming time',
        type: TaskTypeEnum.TIMER,
        addDuration: const Duration(hours: 1),
        currentDuration: Duration.zero,
        credit: 6,
      );
      storeProvider.addItem(gameHourItem);
      LogService.debug('✅ DefaultDataService: 1 Hour Gaming item oluşturuldu');

      // Checkbox item - Atıştırmalık
      final snackItem = ItemModel(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        title: 'Snack',
        description: 'Enjoy your favorite snack',
        type: TaskTypeEnum.COUNTER,
        addCount: 1,
        currentCount: 0,
        credit: 4,
      );
      storeProvider.addItem(snackItem);
      LogService.debug('✅ DefaultDataService: Snack item oluşturuldu');

      // Checkbox item - Film
      final movieItem = ItemModel(
        id: DateTime.now().millisecondsSinceEpoch + 2,
        title: 'Movie',
        description: 'Watch a movie or series episode',
        type: TaskTypeEnum.COUNTER,
        addDuration: const Duration(hours: 2),
        currentDuration: Duration.zero,
        credit: 5,
      );
      storeProvider.addItem(movieItem);
      LogService.debug('✅ DefaultDataService: Movie item oluşturuldu');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Store item oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan projeler oluşturur
  static Future<void> _createDefaultProjects(List<CategoryModel> categories) async {
    final projectsProvider = ProjectsProvider();
    final now = DateTime.now();

    try {
      // İş kategorisinden proje
      if (categories.isNotEmpty) {
        final workProject = ProjectModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Q4 Planning',
          description: 'Quarterly planning and goal setting for the last quarter',
          createdAt: now,
          updatedAt: now,
          colorIndex: 0,
          categoryId: categories[0].id,
        );
        await projectsProvider.addProject(workProject);
        LogService.debug('✅ DefaultDataService: Q4 Planning projesi oluşturuldu');
      }

      // Kişisel kategorisinden proje
      if (categories.length > 1) {
        final personalProject = ProjectModel(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          title: 'Learning Goals',
          description: 'Personal development and learning objectives',
          createdAt: now,
          updatedAt: now,
          colorIndex: 1,
          categoryId: categories[1].id,
          isPinned: true,
        );
        await projectsProvider.addProject(personalProject);
        LogService.debug('✅ DefaultDataService: Learning Goals projesi oluşturuldu');
      }

      // Sağlık kategorisinden proje
      if (categories.length > 2) {
        final healthProject = ProjectModel(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          title: 'Fitness Journey',
          description: 'Track fitness progress and health improvements',
          createdAt: now,
          updatedAt: now,
          colorIndex: 2,
          categoryId: categories[2].id,
        );
        await projectsProvider.addProject(healthProject);
        LogService.debug('✅ DefaultDataService: Fitness Journey projesi oluşturuldu');
      }
    } catch (e) {
      LogService.error('❌ DefaultDataService: Proje oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan notlar oluşturur
  static Future<void> _createDefaultNotes(List<CategoryModel> categories) async {
    final notesProvider = NotesProvider();

    try {
      // İş kategorisinden not
      if (categories.isNotEmpty) {
        await notesProvider.addNote(
          title: 'Meeting Notes',
          content: 'Key points from today\'s team meeting:\n- New project timeline\n- Resource allocation\n- Next steps',
          categoryId: categories[0].id,
          colorIndex: 0,
        );
        LogService.debug('✅ DefaultDataService: Meeting Notes notu oluşturuldu');
      }

      // Kişisel kategorisinden not
      if (categories.length > 1) {
        await notesProvider.addNote(
          title: 'Reading List',
          content: 'Books to read:\n1. Atomic Habits\n2. Deep Work\n3. The Pragmatic Programmer',
          categoryId: categories[1].id,
          colorIndex: 1,
        );
        LogService.debug('✅ DefaultDataService: Reading List notu oluşturuldu');
      }

      // Genel not (kategori yok)
      await notesProvider.addNote(
        title: 'Ideas',
        content: 'Random thoughts and ideas:\n- App feature improvements\n- Weekend plans\n- Gift ideas',
        colorIndex: 3,
      );
      LogService.debug('✅ DefaultDataService: Ideas notu oluşturuldu');

      // Sağlık kategorisinden not
      if (categories.length > 2) {
        await notesProvider.addNote(
          title: 'Workout Plan',
          content: 'Weekly workout schedule:\nMon: Upper body\nWed: Lower body\nFri: Cardio\nSun: Rest',
          categoryId: categories[2].id,
          colorIndex: 2,
        );
        LogService.debug('✅ DefaultDataService: Workout Plan notu oluşturuldu');
      }
    } catch (e) {
      LogService.error('❌ DefaultDataService: Not oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan verileri sıfırlamak için (test amaçlı)
  static Future<void> resetFirstLaunchFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, true);
      LogService.debug('🔄 DefaultDataService: İlk yükleme bayrağı sıfırlandı');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Bayrak sıfırlama hatası: $e');
    }
  }
}
