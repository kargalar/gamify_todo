import 'dart:async';
import 'package:flutter/material.dart';
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
  Timer? _updateTimer;
  Duration _currentDuration = Duration.zero;
  Duration _targetDuration = Duration.zero;
  bool _isTimerRunning = true;

  @override
  void initState() {
    super.initState();

    // Başlangıç süresini al
    _currentDuration = widget.taskModel.currentDuration ?? Duration.zero;
    _targetDuration = widget.taskModel.remainingDuration ?? Duration.zero;

    // Timer durumunu kontrol et
    _isTimerRunning = widget.taskModel.isTimerActive ?? false;

    // Timer'ı başlat
    _startUpdateTimer();

    // Her zaman wakelock aktif tut
    _setKeepScreenOn(true);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _setKeepScreenOn(false); // Ekran açık tutmayı kapat
    super.dispose();
  }

  void _setKeepScreenOn(bool value) {
    if (value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _startUpdateTimer() {
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

  // Takvim yaprağı gibi süre gösterimi
  Widget _buildTimeDisplay(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    // Sadece gerekli olanları göster
    final List<Widget> timeWidgets = [];

    if (hours > 0) {
      timeWidgets.add(_buildTimeCard(hours.toString().padLeft(2, '0')));
      timeWidgets.add(const SizedBox(width: 4));
    }

    timeWidgets.add(_buildTimeCard(minutes.toString().padLeft(2, '0')));
    timeWidgets.add(const SizedBox(width: 4));
    timeWidgets.add(_buildTimeCard(seconds.toString().padLeft(2, '0')));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: timeWidgets,
    );
  }

  // Takvim yaprağı kartı - sadece rakam göster
  Widget _buildTimeCard(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.text.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  // Hedef süreyi formatla (saat:dakika:saniye)
  String _formatTargetTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Üst bar boş bırakıldı (gelecek ihtiyaçlar için)
              const SizedBox(height: 16),

              // Ana içerik
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dairesel progress ile timer gösterimi
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Dairesel progress indicator
                          SizedBox(
                            width: 280,
                            height: 280,
                            child: CircularProgressIndicator(
                              value: _progress,
                              strokeWidth: 12,
                              backgroundColor: AppColors.text.withAlpha(50),
                              valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                            ),
                          ),
                          // İçerideki timer gösterimi
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Takvim yaprakları gibi mevcut süre gösterimi
                              _buildTimeDisplay(_currentDuration),
                              const SizedBox(height: 20),
                              // Hedef süre normal text olarak
                              Text(
                                _formatTargetTime(_targetDuration),
                                style: TextStyle(
                                  color: AppColors.text.withAlpha(150),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          // Tamamlanma icon'u
                          if (_progress >= 1.0)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 60),

                      // Play/Pause butonu - sadece icon
                      IconButton(
                        onPressed: _toggleTimer,
                        icon: Icon(
                          _isTimerRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _isTimerRunning ? AppColors.red.withAlpha(100) : AppColors.green.withAlpha(100),
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
