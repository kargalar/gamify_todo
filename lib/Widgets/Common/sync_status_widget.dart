import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Service/server_manager.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerManager>(
      builder: (context, serverManager, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                serverManager.isRealTimeSyncActive ? Icons.sync : Icons.sync_disabled,
                size: 16,
                color: serverManager.isRealTimeSyncActive ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                serverManager.isRealTimeSyncActive ? 'Real-time Sync' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: serverManager.isRealTimeSyncActive ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
