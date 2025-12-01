import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/alarm_sound_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:just_audio/just_audio.dart';

/// Alarm sound selection dialog
class AlarmSoundSelectionDialog extends StatefulWidget {
  const AlarmSoundSelectionDialog({super.key});

  @override
  State<AlarmSoundSelectionDialog> createState() => _AlarmSoundSelectionDialogState();
}

class _AlarmSoundSelectionDialogState extends State<AlarmSoundSelectionDialog> {
  final AlarmSoundService _alarmSoundService = AlarmSoundService();
  String _selectedItemSoundId = 'alarm1';
  String _selectedScheduledSoundId = 'alarm1';
  String _selectedTimerSoundId = 'alarm1';
  bool _isLoading = true;
  String? _playingSoundId; // Track which sound is currently playing

  // Audio player for preview (no notification!)
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSelectedSounds();
    LogService.debug('AlarmSoundSelectionDialog: Initialized');
  }

  @override
  void dispose() {
    // Stop and dispose audio player
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedSounds() async {
    try {
      final itemSoundId = await _alarmSoundService.getSelectedSoundId(AlarmType.item);
      final scheduledSoundId = await _alarmSoundService.getSelectedSoundId(AlarmType.scheduled);
      final timerSoundId = await _alarmSoundService.getSelectedSoundId(AlarmType.timer);

      if (mounted) {
        setState(() {
          _selectedItemSoundId = itemSoundId;
          _selectedScheduledSoundId = scheduledSoundId;
          _selectedTimerSoundId = timerSoundId;
          _isLoading = false;
        });
      }
      LogService.debug('AlarmSoundSelectionDialog: All alarm sounds loaded');
      LogService.debug('  Item: $itemSoundId, Scheduled: $scheduledSoundId, Timer: $timerSoundId');
    } catch (e) {
      LogService.error('AlarmSoundSelectionDialog: Error loading sounds: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectSound(String soundId, AlarmType type) async {
    try {
      await _alarmSoundService.saveSelectedSound(soundId, type);
      if (mounted) {
        setState(() {
          switch (type) {
            case AlarmType.item:
              _selectedItemSoundId = soundId;
              break;
            case AlarmType.scheduled:
              _selectedScheduledSoundId = soundId;
              break;
            case AlarmType.timer:
              _selectedTimerSoundId = soundId;
              break;
          }
        });
      }

      final soundName = _alarmSoundService.getSoundById(soundId).name;
      LogService.debug('AlarmSoundSelectionDialog: Sound selected for ${type.name}: $soundId');

      // Success message
      Helper().getMessage(
        message: '$soundName selected for ${_getTypeDisplayName(type)}',
        status: StatusEnum.SUCCESS,
      );
    } catch (e) {
      LogService.error('AlarmSoundSelectionDialog: Error selecting sound: $e');
    }
  }

  Future<void> _playPreview(String soundId) async {
    try {
      // If same sound is playing, stop it
      if (_playingSoundId == soundId) {
        await _stopPreview();
        return;
      }

      // Stop any currently playing preview
      await _stopPreview();

      // Get the sound file path
      final sound = _alarmSoundService.getSoundById(soundId);
      final soundPath = 'sounds/${sound.fileName}';

      LogService.debug('AlarmSoundSelectionDialog: Starting preview for: $soundId, path: assets/$soundPath');

      // Update state IMMEDIATELY to show stop icon
      if (mounted) {
        setState(() {
          _playingSoundId = soundId;
        });
      }

      // Play audio using just_audio (NO NOTIFICATION!)
      await _audioPlayer.setAsset('assets/$soundPath');
      await _audioPlayer.setLoopMode(LoopMode.one); // Loop the sound
      await _audioPlayer.play();

      LogService.debug('AlarmSoundSelectionDialog: ✓ Preview playing (sound only, NO notification): $soundId');

      // Auto-stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_playingSoundId == soundId && mounted) {
          _stopPreview();
        }
      });
    } catch (e) {
      LogService.error('AlarmSoundSelectionDialog: ✗ Error playing preview: $e');

      // Reset state on error
      if (mounted) {
        setState(() {
          _playingSoundId = null;
        });

        Helper().getMessage(
          message: 'Error playing sound: $e',
          status: StatusEnum.WARNING,
        );
      }
    }
  }

  Future<void> _stopPreview() async {
    try {
      if (_playingSoundId != null) {
        LogService.debug('AlarmSoundSelectionDialog: Stopping preview for: $_playingSoundId');
      }

      await _audioPlayer.stop();

      if (mounted) {
        setState(() {
          _playingSoundId = null;
        });
      }

      LogService.debug('AlarmSoundSelectionDialog: ✓ Preview stopped');
    } catch (e) {
      LogService.error('AlarmSoundSelectionDialog: ✗ Error stopping preview: $e');
      // Force reset state even on error
      if (mounted) {
        setState(() {
          _playingSoundId = null;
        });
      }
    }
  }

  String _getTypeDisplayName(AlarmType type) {
    switch (type) {
      case AlarmType.item:
        return 'Task Items';
      case AlarmType.scheduled:
        return 'Scheduled Tasks';
      case AlarmType.timer:
        return 'Timer Completed';
    }
  }

  String _getSelectedSoundId(AlarmType type) {
    switch (type) {
      case AlarmType.item:
        return _selectedItemSoundId;
      case AlarmType.scheduled:
        return _selectedScheduledSoundId;
      case AlarmType.timer:
        return _selectedTimerSoundId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Row(
        children: [
          Icon(Icons.music_note, color: AppColors.main),
          const SizedBox(width: 8),
          const Text(
            'Alarm Sound Selection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Alarm Section
                  _buildAlarmTypeSection(
                    title: '🎯 Task Items',
                    description: 'Alarm sound for regular task items',
                    alarmType: AlarmType.item,
                  ),
                  const SizedBox(height: 20),

                  // Scheduled Alarm Section
                  _buildAlarmTypeSection(
                    title: '📅 Scheduled Tasks',
                    description: 'Alarm sound for scheduled tasks',
                    alarmType: AlarmType.scheduled,
                  ),
                  const SizedBox(height: 20),

                  // Timer Alarm Section
                  _buildAlarmTypeSection(
                    title: '⏱️ Timer Completed',
                    description: 'Alarm sound when timer reaches target duration',
                    alarmType: AlarmType.timer,
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () async {
            // Stop any playing preview before closing
            await _stopPreview();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            LogService.debug('AlarmSoundSelectionDialog: Dialog closed');
          },
          child: Text(
            LocaleKeys.Close.tr(),
            style: TextStyle(color: AppColors.main),
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmTypeSection({
    required String title,
    required String description,
    required AlarmType alarmType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ...AlarmSoundService.availableSounds.map((sound) {
          final isSelected = _getSelectedSoundId(alarmType) == sound.id;
          final isPlaying = _playingSoundId == sound.id;

          // Debug: Log state for each sound
          if (isPlaying) {
            LogService.debug('AlarmSoundSelectionDialog: UI - Sound ${sound.id} is PLAYING, showing STOP icon');
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: isPlaying ? AppColors.dirtyRed.withValues(alpha: 0.1) : (isSelected ? AppColors.main.withValues(alpha: 0.1) : AppColors.panelBackground),
                borderRadius: AppColors.borderRadiusAll,
                border: isPlaying ? Border.all(color: AppColors.dirtyRed, width: 2) : (isSelected ? Border.all(color: AppColors.main, width: 2) : null),
              ),
              child: ListTile(
                dense: true,
                leading: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.stop_circle : Icons.play_circle,
                    color: isPlaying ? AppColors.dirtyRed : AppColors.main,
                    size: 32,
                  ),
                  onPressed: () async {
                    await _playPreview(sound.id);
                  },
                  tooltip: isPlaying ? 'Stop preview' : 'Play preview',
                ),
                title: Text(
                  sound.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.main : AppColors.text,
                  ),
                ),
                subtitle: Text(
                  sound.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.text.withValues(alpha: 0.6),
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: AppColors.main,
                        size: 20,
                      )
                    : const SizedBox(width: 20), // Placeholder for alignment
                onTap: () async {
                  await _selectSound(sound.id, alarmType);
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}
