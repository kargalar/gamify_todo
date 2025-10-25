import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/task_provider.dart';

class FullScreenTimerPage extends StatefulWidget {
  final TaskModel taskModel;

  const FullScreenTimerPage({
    super.key,
    required this.taskModel,
  });

  @override
  State<FullScreenTimerPage> createState() => _FullScreenTimerPageState();
}

class _FullScreenTimerPageState extends State<FullScreenTimerPage> {
  bool _keepScreenOn = false;
  Timer? _updateTimer;
  Duration _currentDuration = Duration.zero;
  Duration _targetDuration = Duration.zero;
  bool _isTimerRunning = true;

  @override
  void initState() {
    super.initState();
    debugPrint('FullScreenTimerPage: initState called for task ${widget.taskModel.id}');

    // Başlangıç süresini al
    _currentDuration = widget.taskModel.currentDuration ?? Duration.zero;
    _targetDuration = widget.taskModel.remainingDuration ?? Duration.zero;

    // Timer durumunu kontrol et
    _isTimerRunning = widget.taskModel.isTimerActive ?? false;

    // Timer'ı başlat
    _startUpdateTimer();

    // Başlangıçta ekran açık tutma ayarını kontrol et
    _loadKeepScreenOnSetting();
  }

  @override
  void dispose() {
    debugPrint('FullScreenTimerPage: dispose called for task ${widget.taskModel.id}');
    _updateTimer?.cancel();
    _setKeepScreenOn(false); // Ekran açık tutmayı kapat
    super.dispose();
  }

  void _loadKeepScreenOnSetting() async {
    // SharedPreferences'tan ayarı yükle (şimdilik varsayılan false)
    // İleride ayar sayfasına bağlanabilir
    setState(() {
      _keepScreenOn = false;
    });
    _setKeepScreenOn(_keepScreenOn);
  }

  void _setKeepScreenOn(bool value) {
    debugPrint('FullScreenTimerPage: Setting keep screen on to $value');
    if (value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _startUpdateTimer() {
    debugPrint('FullScreenTimerPage: Starting update timer');
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // TaskProvider'dan güncel süreyi al
          final taskProvider = Provider.of<TaskProvider>(context, listen: false);
          final task = taskProvider.taskList.firstWhere(
            (t) => t.id == widget.taskModel.id,
            orElse: () => widget.taskModel,
          );
          _currentDuration = task.currentDuration ?? Duration.zero;
          _targetDuration = task.remainingDuration ?? Duration.zero;
          _isTimerRunning = task.isTimerActive ?? false;
        });
      }
    });
  }

  void _toggleTimer() {
    debugPrint('FullScreenTimerPage: Toggling timer for task ${widget.taskModel.id}');
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });
    GlobalTimer().startStopTimer(taskModel: widget.taskModel);
  }

  double get _progress {
    if (_targetDuration.inSeconds == 0) return 0.0;
    return (_currentDuration.inSeconds / _targetDuration.inSeconds).clamp(0.0, 1.0);
  }

  Color get _progressColor {
    if (_progress >= 1.0) return AppColors.blue; // Tamamlandı
    if (_progress >= 0.75) return AppColors.green; // Çok iyi
    if (_progress >= 0.5) return AppColors.yellow; // İyi
    if (_progress >= 0.25) return AppColors.orange; // Orta
    return AppColors.red; // Az
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('FullScreenTimerPage: Building UI for task ${widget.taskModel.id}');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Üst bar - sadece ayarlar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Switch(
                      value: _keepScreenOn,
                      onChanged: (value) {
                        debugPrint('FullScreenTimerPage: Keep screen on toggled to $value');
                        setState(() {
                          _keepScreenOn = value;
                        });
                        _setKeepScreenOn(value);
                      },
                      activeColor: AppColors.main,
                      thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Icon(
                              Icons.lightbulb,
                              color: Colors.white,
                              size: 16,
                            );
                          }
                          return const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white,
                            size: 16,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Ana içerik
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Task adı
                      Text(
                        widget.taskModel.title,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 50),

                      // Büyük timer gösterimi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentDuration.textLongDynamicWithoutZero(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            ' /${_targetDuration.textLongDynamicWithoutZero()}',
                            style: TextStyle(
                              color: AppColors.text.withAlpha(180),
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Progress bar ve tamamlanma icon'u
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: AppColors.text.withAlpha(50),
                              valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                            ),
                          ),
                          if (_progress >= 1.0) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.green,
                              size: 24,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 100),

                      // Play/Pause butonu - sadece icon
                      IconButton(
                        onPressed: _toggleTimer,
                        icon: Icon(
                          _isTimerRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _isTimerRunning ? AppColors.red.withAlpha(150) : AppColors.green.withAlpha(150),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
