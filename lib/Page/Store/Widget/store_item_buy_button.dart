import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

/// Premium buy/add button for store items with credit badge.
class StoreItemBuyButton extends StatelessWidget {
  final String amountText;
  final int credit;
  final VoidCallback onTap;

  const StoreItemBuyButton({
    super.key,
    required this.amountText,
    required this.credit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final actionText = credit == 0 ? LocaleKeys.Add.tr() : LocaleKeys.Buy.tr();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 34,
          constraints: const BoxConstraints(minWidth: 90),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.main.withValues(alpha: 0.7),
                AppColors.main,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.main.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$actionText $amountText',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (credit != 0) ...[
                const SizedBox(width: 6),
                _buildCreditBadge(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$credit',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.monetization_on_rounded,
            size: 12,
            color: Color(0xFFFFD600),
          ),
        ],
      ),
    );
  }
}
