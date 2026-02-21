import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Store/add_store_item_page.dart';
import 'package:next_level/Page/Store/Widget/store_item_buy_button.dart';
import 'package:next_level/Page/Store/Widget/store_item_type_icon.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Repository/user_repository.dart';
import 'package:next_level/Repository/store_repository.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/logging_service.dart';

class StoreItem extends StatefulWidget {
  const StoreItem({
    super.key,
    required this.storeItemModel,
  });

  final ItemModel storeItemModel;

  @override
  State<StoreItem> createState() => _StoreItemState();
}

class _StoreItemState extends State<StoreItem> {
  ItemModel get _item => widget.storeItemModel;
  bool get _isTimerActive => _item.isTimerActive ?? false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Slidable(
        key: ValueKey(_item.id),
        startActionPane: _buildEditAction(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.main.withValues(alpha: 0.08),
            highlightColor: AppColors.main.withValues(alpha: 0.04),
            onTap: _handleItemAction,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.panelBackground.withValues(alpha: 0.85),
                    AppColors.panelBackground2.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isTimerActive ? AppColors.main.withValues(alpha: 0.4) : AppColors.panelBackground2.withValues(alpha: 0.5),
                  width: _isTimerActive ? 1.5 : 1,
                ),
                boxShadow: _isTimerActive
                    ? [
                        BoxShadow(
                          color: AppColors.main.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  StoreItemTypeIcon(
                    type: _item.type,
                    isTimerActive: _isTimerActive,
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _buildTitleSection()),
                  const SizedBox(width: 10),
                  _buildRightSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────── UI BUILDERS ────────────────────

  ActionPane _buildEditAction() {
    return ActionPane(
      extentRatio: 0.4,
      dismissible: DismissiblePane(
        dismissThreshold: 0.3,
        closeOnCancel: true,
        confirmDismiss: () async {
          await NavigatorService()
              .goTo(
                AddStoreItemPage(editItemModel: _item),
                transition: Transition.size,
              )
              .then((_) => StoreProvider().setStateItems());
          return false;
        },
        onDismissed: () {},
      ),
      motion: const ScrollMotion(),
      children: [
        SlidableAction(
          onPressed: (_) async {
            await NavigatorService()
                .goTo(
                  AddStoreItemPage(editItemModel: _item),
                  transition: Transition.size,
                )
                .then((_) => StoreProvider().setStateItems());
          },
          backgroundColor: AppColors.matteBlue,
          borderRadius: BorderRadius.circular(14),
          foregroundColor: Colors.white,
          icon: Icons.edit_rounded,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          label: LocaleKeys.Edit.tr(),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _item.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            letterSpacing: 0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (_item.description != null && _item.description!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            _item.description!,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.text.withValues(alpha: 0.4),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildRightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_item.type != TaskTypeEnum.CHECKBOX) ...[
          _buildRemainingBadge(),
          const SizedBox(height: 6),
        ],
        StoreItemBuyButton(
          amountText: _buildAmountText(),
          credit: _item.credit,
          onTap: _handlePurchase,
        ),
      ],
    );
  }

  Widget _buildRemainingBadge() {
    final String valueText;
    final Color badgeColor;
    final IconData iconData;

    if (_item.type == TaskTypeEnum.COUNTER) {
      valueText = '${_item.currentCount}';
      badgeColor = AppColors.text;
      iconData = Icons.numbers_rounded;
    } else {
      valueText = _item.currentDuration!.textShortDynamic();
      badgeColor = _isTimerActive ? AppColors.main : AppColors.text;
      iconData = Icons.timer_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 13, color: badgeColor.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            valueText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: badgeColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  String _buildAmountText() {
    if (_item.type == TaskTypeEnum.COUNTER) {
      return '${_item.addCount}';
    }
    return _item.addDuration?.textLongDynamicWithoutZero() ?? '';
  }

  // ──────────────────── ACTIONS ────────────────────

  Future<void> _handlePurchase() async {
    if (loginUser == null) {
      LogService.error('❌ Store Item Purchase: loginUser is null');
      return;
    }

    loginUser!.userCredit -= _item.credit;

    dynamic value;

    if (_item.type == TaskTypeEnum.TIMER) {
      _item.currentDuration = _item.currentDuration! + _item.addDuration!;
      value = _item.addDuration;
    } else {
      _item.currentCount = _item.currentCount! + _item.addCount!;
      value = _item.addCount;
    }

    TaskProgressViewModel.addStoreItemLog(
      itemId: _item.id,
      action: 'Purchase',
      value: value,
      type: _item.type,
      isPurchase: true,
    );

    LogService.debug('💰 Store Item Purchase: ${_item.title} - Credit cost: -${_item.credit}');

    await UserRepository().updateUser(loginUser!);
    await StoreRepository().updateItem(_item);

    UserProvider().setUser(loginUser!);
    StoreProvider().setStateItems();
  }

  void _handleItemAction() async {
    dynamic value;
    String action;

    if (_item.type == TaskTypeEnum.COUNTER) {
      _item.currentCount = _item.currentCount! - 1;
      value = -1;
      action = 'Usage';
      StoreRepository().updateItem(_item);
    } else {
      bool wasTimerActive = _isTimerActive;

      Duration? elapsedTime;
      if (wasTimerActive) {
        final prefs = await SharedPreferences.getInstance();
        String? timerStartTimeStr = prefs.getString('item_timer_start_time_${_item.id}');
        String? timerStartDurationStr = prefs.getString('item_timer_start_duration_${_item.id}');

        LogService.debug('DEBUG: Timer will be stopped for item ${_item.id}');
        LogService.debug('DEBUG: timerStartTimeStr = $timerStartTimeStr');
        LogService.debug('DEBUG: timerStartDurationStr = $timerStartDurationStr');

        if (timerStartTimeStr != null && timerStartDurationStr != null) {
          DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));
          DateTime currentTime = DateTime.now();

          elapsedTime = currentTime.difference(timerStartTime);

          LogService.debug('DEBUG: timerStartTime = $timerStartTime');
          LogService.debug('DEBUG: currentTime = $currentTime');
          LogService.debug('DEBUG: elapsedTime = ${elapsedTime.inSeconds} seconds (${elapsedTime.inMinutes}m ${elapsedTime.inSeconds % 60}s)');
          LogService.debug('DEBUG: elapsedTime.inMilliseconds = ${elapsedTime.inMilliseconds}');
        }
      }

      GlobalTimer().startStopTimer(storeItemModel: _item);

      if (!wasTimerActive && _isTimerActive) {
        action = 'Timer Started';
        value = Duration.zero;
      } else if (wasTimerActive && !_isTimerActive) {
        action = 'Timer Stopped';

        if (elapsedTime != null) {
          value = -elapsedTime;
          LogService.debug('DEBUG: value to log = ${value.inSeconds} seconds');
          LogService.debug('DEBUG: value.inMinutes = ${value.inMinutes}, value.inSeconds % 60 = ${value.inSeconds % 60}');
        } else {
          LogService.debug('DEBUG: Timer data was not available, logging as zero');
          value = Duration.zero;
        }
      } else {
        value = Duration.zero;
        action = 'Timer Action';
      }

      StoreRepository().updateItem(_item);
    }

    if (_item.type == TaskTypeEnum.COUNTER || (_item.type == TaskTypeEnum.TIMER && action == 'Timer Stopped')) {
      TaskProgressViewModel.addStoreItemLog(
        itemId: _item.id,
        action: action,
        value: value,
        type: _item.type,
      );
    }

    StoreProvider().setStateItems();
  }
}
