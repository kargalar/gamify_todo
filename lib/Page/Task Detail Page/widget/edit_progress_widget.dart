import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/app_helper.dart';
import 'package:gamify_todo/Service/global_timer.dart';
import 'package:gamify_todo/Service/home_widget_service.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Service/notification_services.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Provider/store_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/store_item_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Model/task_log_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProgressWidget extends StatefulWidget {
  final TaskModel? taskModel;
  final ItemModel? itemModel;

  const EditProgressWidget.forTask({
    super.key,
    required TaskModel task,
  })  : taskModel = task,
        itemModel = null;

  const EditProgressWidget.forStoreItem({
    super.key,
    required ItemModel item,
  })  : itemModel = item,
        taskModel = null;

  @override
  State<EditProgressWidget> createState() => _EditProgressWidgetState();
}

class _EditProgressWidgetState extends State<EditProgressWidget> {
  bool _isIncrementing = false;
  bool _isDecrementing = false;

  // TaskLogProvider'ı dinlemek için
  late final TaskLogProvider _taskLogProvider = TaskLogProvider();

  bool get isTask => widget.taskModel != null;
  TaskTypeEnum get type => isTask ? widget.taskModel!.type : widget.itemModel!.type;
  int get currentCount => isTask ? widget.taskModel!.currentCount! : widget.itemModel!.currentCount!;
  Duration? get currentDuration => isTask ? widget.taskModel!.currentDuration : widget.itemModel!.currentDuration;
  Duration? get targetDuration => isTask ? widget.taskModel!.remainingDuration : widget.itemModel!.addDuration;

  @override
  void initState() {
    super.initState();
    if (isTask) {
      // Widget oluşturulduğunda loglardan ilerleme değerlerini al
      _updateProgressFromLogs();

      // TaskLogProvider'ı dinle
      _taskLogProvider.addListener(_onTaskLogChanged);
    }
  }

  @override
  void dispose() {
    if (isTask) {
      // Listener'ı kaldır
      _taskLogProvider.removeListener(_onTaskLogChanged);
    }
    super.dispose();
  }

  void _onTaskLogChanged() {
    // TaskLogProvider değiştiğinde ilerleme değerlerini güncelle
    _updateProgressFromLogs();
  }

  Future<void> _updateProgressFromLogs() async {
    if (!isTask) return;

    // Task için logları al
    List<TaskLogModel> logs = _taskLogProvider.getLogsByTaskId(widget.taskModel!.id);

    // TaskProvider'dan seçili tarihi al
    final selectedDate = TaskProvider().selectedDate;
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    // Sadece seçili tarihe ait logları filtrele
    List<TaskLogModel> filteredLogs = logs.where((log) {
      final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      return logDate.isAtSameMomentAs(selectedDay); // Sadece seçili tarih
    }).toList();

    // Toplam ilerlemeyi hesapla
    int totalCount = 0;
    Duration totalDuration = Duration.zero;

    // Checkbox için en son durumu al (en yeni log)
    if (widget.taskModel!.type == TaskTypeEnum.CHECKBOX && filteredLogs.isNotEmpty) {
      // Logları tarihe göre sırala (en yenisi en üstte)
      filteredLogs.sort((a, b) => b.logDate.compareTo(a.logDate));

      // En yeni log (ilk eleman)
      TaskLogModel latestLog = filteredLogs.first;

      // Task durumunu güncelle
      widget.taskModel!.status = latestLog.status;
    }

    // Tüm logları işle ve toplam değeri hesapla
    for (var log in filteredLogs) {
      if (widget.taskModel!.type == TaskTypeEnum.TIMER && log.duration != null) {
        // Her log kendi başına bir artış olarak değerlendirilir
        // Örneğin: +2h, +1h, +30m gibi
        totalDuration += log.duration!;
      } else if (widget.taskModel!.type == TaskTypeEnum.COUNTER && log.count != null) {
        // Her log kendi başına bir artış olarak değerlendirilir
        // Örneğin: +5, +1, -2 gibi
        totalCount += log.count!;
      }
    }

    // Aktif timer varsa, şu anki timer değerini de ekle
    if (widget.taskModel!.type == TaskTypeEnum.TIMER && widget.taskModel!.isTimerActive == true) {
      // SharedPreferences'dan timer başlangıç zamanını al
      final prefs = await SharedPreferences.getInstance();
      String? timerStartTimeStr = prefs.getString('timer_start_time_${widget.taskModel!.id}');
      String? timerStartDurationStr = prefs.getString('timer_start_duration_${widget.taskModel!.id}');

      if (timerStartTimeStr != null && timerStartDurationStr != null) {
        // Timer başlangıç zamanını hesapla
        DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));
        Duration timerStartDuration = Duration(seconds: int.parse(timerStartDurationStr));

        // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
        Duration timerRunDuration = DateTime.now().difference(timerStartTime);

        // Toplam süreyi hesapla (başlangıç değeri + geçen süre)
        totalDuration = timerStartDuration + timerRunDuration;
      }
    }

    // Task tipine göre ilerleme değerini güncelle
    if (widget.taskModel!.type == TaskTypeEnum.TIMER) {
      widget.taskModel!.currentDuration = totalDuration;
    } else if (widget.taskModel!.type == TaskTypeEnum.COUNTER) {
      widget.taskModel!.currentCount = totalCount;
    }

    // Sunucuya güncelleme gönder
    ServerManager().updateTask(taskModel: widget.taskModel!);

    // TaskProvider'ı güncelle (ana sayfadaki görev ilerlemesini güncellemek için)
    TaskProvider().updateItems();

    // Widget'ı güncelle
    if (mounted) {
      setState(() {});
    }
  }

  void updateProgress(value) {
    if (isTask) {
      late Duration progressDifference;
      if (widget.taskModel!.type == TaskTypeEnum.COUNTER) {
        int previousCount = widget.taskModel!.currentCount ?? 0;
        widget.taskModel!.currentCount = value;

        // Calculate progress difference for credit adjustment
        int difference = value - previousCount;
        progressDifference = widget.taskModel!.remainingDuration! * difference ~/ widget.taskModel!.targetCount!;
      } else {
        Duration previousDuration = widget.taskModel!.currentDuration ?? Duration.zero;
        widget.taskModel!.currentDuration = value;

        // Calculate progress difference for credit adjustment
        progressDifference = value - previousDuration;
      }

      // Sunucuya güncelleme gönder
      ServerManager().updateTask(taskModel: widget.taskModel!);

      // Kredi ekle
      AppHelper().addCreditByProgress(progressDifference);

      // Ana sayfadaki görev sayısını güncelle
      HomeWidgetService.updateTaskCount();

      // TaskProvider'ı güncelle (ana sayfadaki görev ilerlemesini güncellemek için)
      TaskProvider().updateItems();
    } else {
      ServerManager().updateItem(itemModel: widget.itemModel!);
    }
  }

  void setCount(int value) async {
    // Önceki değeri kaydet
    int previousCount = isTask ? (widget.taskModel!.currentCount ?? 0) : 0;

    setState(() {
      if (isTask) {
        // Değer değiştiyse log oluştur
        bool shouldCreateLog = value != previousCount;

        if (value >= widget.taskModel!.targetCount! && widget.taskModel!.status != TaskStatusEnum.COMPLETED) {
          widget.taskModel!.status = TaskStatusEnum.COMPLETED;
        } else if (value < widget.taskModel!.targetCount! && widget.taskModel!.status == TaskStatusEnum.COMPLETED) {
          widget.taskModel!.status = null;
        }

        // Değer değiştiyse log oluştur
        if (shouldCreateLog) {
          // Değişim miktarını hesapla
          int difference = value - previousCount;

          // Değişim miktarını log olarak kaydet (hem pozitif hem negatif değişimler için)
          if (difference != 0) {
            // TaskProvider'dan seçili tarihi al
            final selectedDate = TaskProvider().selectedDate;

            TaskLogProvider().addTaskLog(
              widget.taskModel!,
              customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, DateTime.now().hour, DateTime.now().minute, DateTime.now().second, DateTime.now().millisecond),
              customCount: difference, // Değişim miktarını logla (pozitif veya negatif)
              customStatus: value >= widget.taskModel!.targetCount! ? TaskStatusEnum.COMPLETED : null,
            );
          }
        }
      } else {
        widget.itemModel!.currentCount = value;
      }
    });
    updateProgress(value);
  }

  void setDuration(Duration value) async {
    // Önceki değeri kaydet
    Duration previousDuration = isTask ? (widget.taskModel!.currentDuration ?? Duration.zero) : Duration.zero;

    // Timer aktifse durdur
    if (isTask && widget.taskModel!.isTimerActive == true) {
      // Timer'ı durdur
      GlobalTimer().startStopTimer(taskModel: widget.taskModel!);
    }

    setState(() {
      if (isTask) {
        // Değer değiştiyse log oluştur
        bool shouldCreateLog = value != previousDuration;

        if (value >= widget.taskModel!.remainingDuration! && widget.taskModel!.status != TaskStatusEnum.COMPLETED) {
          widget.taskModel!.status = TaskStatusEnum.COMPLETED;
        } else if (value < widget.taskModel!.remainingDuration! && widget.taskModel!.status == TaskStatusEnum.COMPLETED) {
          widget.taskModel!.status = null;
        }

        // Değer değiştiyse log oluştur
        if (shouldCreateLog) {
          // Değişim miktarını hesapla
          Duration difference = value - previousDuration;

          // Değişim miktarını log olarak kaydet (hem pozitif hem negatif değişimler için)
          if (difference.inSeconds != 0) {
            // TaskProvider'dan seçili tarihi al
            final selectedDate = TaskProvider().selectedDate;

            TaskLogProvider().addTaskLog(
              widget.taskModel!,
              customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, DateTime.now().hour, DateTime.now().minute, DateTime.now().second, DateTime.now().millisecond),
              customDuration: difference, // Değişim miktarını logla (pozitif veya negatif)
              customStatus: value >= widget.taskModel!.remainingDuration! ? TaskStatusEnum.COMPLETED : null,
            );

            // Son loglanan süreyi SharedPreferences'a kaydet
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('last_logged_duration_${widget.taskModel!.id}', value.inSeconds.toString());
            });
          }
        }

        _checkAndUpdateNotificationStatusForTask();
      } else {
        widget.itemModel!.currentDuration = value;
        _checkAndUpdateNotificationStatusForStoreItem();
      }
    });
    updateProgress(value);
  }

  @override
  Widget build(BuildContext context) {
    if (isTask) {
      // TaskProvider'ı dinle (seçili tarih değiştiğinde widget'ı güncelle)
      context.watch<TaskProvider>();

      // TaskLogProvider'ı dinle (loglar değiştiğinde widget'ı güncelle)
      context.watch<TaskLogProvider>();

      // Timer aktifse periyodik olarak güncelle
      if (widget.taskModel!.type == TaskTypeEnum.TIMER && widget.taskModel!.isTimerActive == true) {
        // Her saniye güncelle
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _updateProgressFromLogs();
          }
        });
      }

      // Sayfa yüklendiğinde logları güncelle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateProgressFromLogs();
      });
    } else {
      context.watch<StoreProvider>();
    }

    if (type == TaskTypeEnum.CHECKBOX) {
      return Column(
        children: [
          Text(
            _getCheckboxStatus(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Durum değiştirme butonları
          if (isTask)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusButton(
                  label: LocaleKeys.Completed.tr(),
                  status: TaskStatusEnum.COMPLETED,
                  color: AppColors.green,
                ),
                _buildStatusButton(
                  label: LocaleKeys.Failed.tr(),
                  status: TaskStatusEnum.FAILED,
                  color: AppColors.red,
                ),
                _buildStatusButton(
                  label: LocaleKeys.Cancelled.tr(),
                  status: TaskStatusEnum.CANCEL,
                  color: AppColors.purple,
                ),
              ],
            ),
        ],
      );
    } else if (type == TaskTypeEnum.COUNTER) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (currentCount > 0 || !isTask) {
                setCount(currentCount - 1);
              }
            },
            onLongPressStart: (_) async {
              _isDecrementing = true;
              while (_isDecrementing && mounted) {
                if (currentCount > 0 || !isTask) {
                  setCount(currentCount - 1);
                }
                await Future.delayed(const Duration(milliseconds: 60));
              }
            },
            onLongPressEnd: (_) {
              _isDecrementing = false;
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.remove, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isTask ? "$currentCount / ${widget.taskModel!.targetCount!}" : "$currentCount",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              setCount(currentCount + 1);
            },
            onLongPressStart: (_) async {
              _isIncrementing = true;
              while (_isIncrementing && mounted) {
                setCount(currentCount + 1);
                await Future.delayed(const Duration(milliseconds: 60));
              }
            },
            onLongPressEnd: (_) {
              _isIncrementing = false;
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.add, size: 30),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDurationControl(
            label: LocaleKeys.Hour.tr(),
            value: (currentDuration?.isNegative ?? false) ? -((-currentDuration!.inHours) % 24) : currentDuration?.inHours ?? 0,
            onIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(hours: 1));
            },
            onDecrease: () {
              if ((currentDuration?.inHours ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(hours: 1));
              }
            },
            onLongIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(hours: 1));
            },
            onLongDecrease: () {
              if ((currentDuration?.inHours ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(hours: 1));
              }
            },
          ),
          const SizedBox(width: 16),
          _buildDurationControl(
            label: LocaleKeys.Minute.tr(),
            value: (currentDuration?.isNegative ?? false) ? -((-currentDuration!.inMinutes) % 60) : (currentDuration?.inMinutes ?? 0) % 60,
            onIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(minutes: 1));
            },
            onDecrease: () {
              if ((currentDuration?.inMinutes ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(minutes: 1));
              }
            },
            onLongIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(minutes: 1));
            },
            onLongDecrease: () {
              if ((currentDuration?.inMinutes ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(minutes: 1));
              }
            },
          ),
          const SizedBox(width: 16),
          _buildDurationControl(
            label: LocaleKeys.Second.tr(),
            value: (currentDuration?.isNegative ?? false) ? -((-currentDuration!.inSeconds) % 60) : (currentDuration?.inSeconds ?? 0) % 60,
            onIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(seconds: 1));
            },
            onDecrease: () {
              if ((currentDuration?.inSeconds ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(seconds: 1));
              }
            },
            onLongIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(seconds: 1));
            },
            onLongDecrease: () {
              if ((currentDuration?.inSeconds ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(seconds: 1));
              }
            },
          ),
          if (isTask) ...[
            const SizedBox(width: 16),
            Text(
              "/ ${targetDuration?.textShort3() ?? "0"}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildDurationControl({
    required String label,
    required int value,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
    required VoidCallback onLongIncrease,
    required VoidCallback onLongDecrease,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onIncrease,
          onLongPressStart: (_) async {
            _isIncrementing = true;
            while (_isIncrementing && mounted) {
              onLongIncrease();
              await Future.delayed(const Duration(milliseconds: 60));
            }
          },
          onLongPressEnd: (_) {
            _isIncrementing = false;
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_up, size: 24),
          ),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onDecrease,
          onLongPressStart: (_) async {
            _isDecrementing = true;
            while (_isDecrementing && mounted) {
              onLongDecrease();
              await Future.delayed(const Duration(milliseconds: 60));
            }
          },
          onLongPressEnd: (_) {
            _isDecrementing = false;
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_down, size: 24),
          ),
        ),
      ],
    );
  }

  String _getCheckboxStatus() {
    if (!isTask) return "";

    switch (widget.taskModel!.status) {
      case TaskStatusEnum.COMPLETED:
        return LocaleKeys.Completed.tr();
      case TaskStatusEnum.FAILED:
        return LocaleKeys.Failed.tr();
      case TaskStatusEnum.CANCEL:
        return LocaleKeys.Cancelled.tr();
      default:
        return LocaleKeys.InProgress.tr();
    }
  }

  // Durum değiştirme butonu
  Widget _buildStatusButton({
    required String label,
    required TaskStatusEnum status,
    required Color color,
  }) {
    final bool isSelected = isTask && widget.taskModel!.status == status;

    return ElevatedButton(
      onPressed: () async {
        if (!isTask) return;

        // TaskProvider'dan seçili tarihi al
        final selectedDate = TaskProvider().selectedDate;
        final now = DateTime.now();

        // Eğer zaten seçili durum tıklanırsa, durumu sıfırla (null yap)
        if (isSelected) {
          widget.taskModel!.status = null;

          // Son logları kontrol et
          List<TaskLogModel> logs = _taskLogProvider.getLogsByTaskId(widget.taskModel!.id);

          // Bugüne ait logları filtrele
          logs = logs.where((log) {
            final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
            final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
            return logDate.isAtSameMomentAs(today);
          }).toList();

          // Logları tarihe göre sırala (en yenisi en üstte)
          logs.sort((a, b) => b.logDate.compareTo(a.logDate));

          // Son log'un durumu kontrol et
          bool shouldCreateLog = true;
          if (logs.isNotEmpty) {
            TaskLogModel lastLog = logs.first;
            // Eğer son log'un durumu null ise ve şimdi de null yapıyorsak, log oluşturma
            if (lastLog.status == null) {
              shouldCreateLog = false;
            }
          }

          // Log oluştur (durumu null olarak)
          if (shouldCreateLog) {
            TaskLogProvider().addTaskLog(
              widget.taskModel!,
              customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second, now.millisecond),
              // Burada null olarak gönderiyoruz - bu, checkbox'ın hiçbir durumunun seçili olmadığını gösterir
              customStatus: null,
            );
          }
        } else {
          // Yeni durum
          TaskStatusEnum newStatus = status;
          widget.taskModel!.status = newStatus;

          // Son logları kontrol et
          List<TaskLogModel> logs = _taskLogProvider.getLogsByTaskId(widget.taskModel!.id);

          // Bugüne ait logları filtrele
          logs = logs.where((log) {
            final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
            final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
            return logDate.isAtSameMomentAs(today);
          }).toList();

          // Logları tarihe göre sırala (en yenisi en üstte)
          logs.sort((a, b) => b.logDate.compareTo(a.logDate));

          // Son log'un durumu kontrol et
          bool shouldCreateLog = true;
          if (logs.isNotEmpty) {
            TaskLogModel lastLog = logs.first;
            // Eğer son log'un durumu yeni durum ile aynıysa, log oluşturma
            if (lastLog.status == newStatus) {
              shouldCreateLog = false;
            }
          }

          // Log oluştur
          if (shouldCreateLog) {
            TaskLogProvider().addTaskLog(
              widget.taskModel!,
              customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second, now.millisecond),
              customStatus: newStatus,
            );
          }
        }

        // Sunucuya güncelleme gönder
        ServerManager().updateTask(taskModel: widget.taskModel!);

        // TaskProvider'ı güncelle (ana sayfadaki görev durumunu güncellemek için)
        TaskProvider().updateItems();

        // Widget'ı güncelle
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withValues(alpha: 0.2),
        foregroundColor: isSelected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  // TODO: buradalar notificaitonService de yapılsın
  // check notifiaciaton status for task
  void _checkAndUpdateNotificationStatusForTask() {
    final task = widget.taskModel!;
    final remainingDuration = task.remainingDuration!;
    final currentDuration = task.currentDuration!;
    final isTimerActive = task.isTimerActive ?? false;

    if (currentDuration < remainingDuration && isTimerActive) {
      // Zamanlanmış bildirimi yeniden hesapla
      final int secondsUntilCompletion = remainingDuration.inSeconds - currentDuration.inSeconds;
      NotificationService().scheduleNotification(
        id: task.id,
        title: '🎉 ${task.title} Tamamlandı',
        desc: 'Toplam süre: ${task.remainingDuration!.textLongDynamicWithoutZero()}',
        scheduledDate: DateTime.now().add(Duration(seconds: secondsUntilCompletion)),
        isAlarm: task.isAlarmOn,
      );
    } else if (isTimerActive && currentDuration >= remainingDuration) {
      // Halihazırdaki zamanlanmış bildirimi iptal et
      NotificationService().cancelNotificationOrAlarm(task.id);
    }
  }

  // check notifiaciaton status for store item
  void _checkAndUpdateNotificationStatusForStoreItem() {
    final item = widget.itemModel!;
    final currentDuration = item.currentDuration!;
    final isTimerActive = item.isTimerActive ?? false;

    if (currentDuration.inSeconds > 0 && isTimerActive) {
      // Zamanlanmış bildirimi yeniden hesapla
      final int secondsUntilCompletion = currentDuration.inSeconds;
      NotificationService().scheduleNotification(
        id: item.id,
        title: '⚠️ ${item.title} Süre Doldu',
        desc: 'Sınırı Aşma!',
        scheduledDate: DateTime.now().add(Duration(seconds: secondsUntilCompletion)),
        isAlarm: true,
      );
    } else if (isTimerActive && currentDuration.inSeconds <= 0) {
      // Halihazırdaki zamanlanmış bildirimi iptal et
      NotificationService().cancelNotificationOrAlarm(item.id);
    }
  }
}
