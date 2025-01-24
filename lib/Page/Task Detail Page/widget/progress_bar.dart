import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final String title;
  final double progress;
  final Color color;
  final String? icon;

  const ProgressBar({
    super.key,
    required this.title,
    required this.progress,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(icon!, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 8),
              ],
              Text("$title ${(progress * 100).toInt()}%"),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}
