import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/Service/sync_manager.dart';

class SyncStatusWidget extends StatefulWidget {
  final bool showFullStatus;
  final VoidCallback? onTap;

  const SyncStatusWidget({
    super.key,
    this.showFullStatus = false,
    this.onTap,
  });

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final SyncManager _syncManager = SyncManager();
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Update UI every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () => _syncManager.forceSyncNow(),
      child: widget.showFullStatus ? _buildFullStatus() : _buildCompactStatus(),
    );
  }

  Widget _buildCompactStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(),
          const SizedBox(width: 4),
          Text(
            _syncManager.syncStatusText,
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusTitle(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getStatusDescription(),
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor().withOpacity(0.8),
            ),
          ),
          if (_syncManager.lastSuccessfulSync != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last sync: ${_syncManager.syncStatusText}',
              style: TextStyle(
                fontSize: 10,
                color: _getStatusColor().withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_syncManager.isSyncing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
        ),
      );
    }

    return Icon(
      _getStatusIcon(),
      size: 16,
      color: _getStatusColor(),
    );
  }

  Color _getStatusColor() {
    if (_syncManager.isSyncing) {
      return Colors.blue;
    } else if (!_syncManager.isOnline) {
      return Colors.red;
    } else if (_syncManager.lastSuccessfulSync == null) {
      return Colors.orange;
    } else {
      final timeSinceSync = DateTime.now().difference(_syncManager.lastSuccessfulSync!);
      if (timeSinceSync.inMinutes < 5) {
        return Colors.green;
      } else if (timeSinceSync.inMinutes < 60) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }
  }

  IconData _getStatusIcon() {
    if (_syncManager.isSyncing) {
      return Icons.sync;
    } else if (!_syncManager.isOnline) {
      return Icons.wifi_off;
    } else if (_syncManager.lastSuccessfulSync == null) {
      return Icons.warning;
    } else {
      final timeSinceSync = DateTime.now().difference(_syncManager.lastSuccessfulSync!);
      if (timeSinceSync.inMinutes < 5) {
        return Icons.check_circle;
      } else if (timeSinceSync.inMinutes < 60) {
        return Icons.schedule;
      } else {
        return Icons.error;
      }
    }
  }

  String _getStatusTitle() {
    if (_syncManager.isSyncing) {
      return 'Syncing...';
    } else if (!_syncManager.isOnline) {
      return 'Offline';
    } else if (_syncManager.lastSuccessfulSync == null) {
      return 'Never synced';
    } else {
      final timeSinceSync = DateTime.now().difference(_syncManager.lastSuccessfulSync!);
      if (timeSinceSync.inMinutes < 5) {
        return 'Up to date';
      } else if (timeSinceSync.inMinutes < 60) {
        return 'Recently synced';
      } else {
        return 'Outdated';
      }
    }
  }

  String _getStatusDescription() {
    if (_syncManager.isSyncing) {
      return 'Synchronizing your data with the cloud...';
    } else if (!_syncManager.isOnline) {
      return 'No internet connection available';
    } else if (_syncManager.lastSuccessfulSync == null) {
      return 'Tap to sync your data';
    } else {
      final timeSinceSync = DateTime.now().difference(_syncManager.lastSuccessfulSync!);
      if (timeSinceSync.inMinutes < 5) {
        return 'All your data is synchronized';
      } else if (timeSinceSync.inMinutes < 60) {
        return 'Your data is mostly up to date';
      } else {
        return 'Your data needs to be synchronized';
      }
    }
  }
}
