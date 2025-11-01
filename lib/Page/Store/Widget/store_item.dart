import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Store/add_store_item_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/server_manager.dart';
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

class _StoreItemState extends State<StoreItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Slidable(
        key: ValueKey(widget.storeItemModel.id),
        startActionPane: ActionPane(
          dismissible: DismissiblePane(
            dismissThreshold: 0.3,
            closeOnCancel: true,
            confirmDismiss: () async {
              await NavigatorService()
                  .goTo(
                    AddStoreItemPage(editItemModel: widget.storeItemModel),
                    transition: Transition.size,
                  )
                  .then(
                    (value) => StoreProvider().setStateItems(),
                  );
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
                      AddStoreItemPage(editItemModel: widget.storeItemModel),
                      transition: Transition.size,
                    )
                    .then(
                      (value) => StoreProvider().setStateItems(),
                    );
              },
              backgroundColor: AppColors.main,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: LocaleKeys.Edit.tr(),
            ),
          ],
        ),
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              _isHovering = true;
              _animationController.forward();
            });
          },
          onExit: (_) {
            setState(() {
              _isHovering = false;
              _animationController.reverse();
            });
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              borderRadius: AppColors.borderRadiusAll,
              child: InkWell(
                borderRadius: AppColors.borderRadiusAll,
                splashColor: AppColors.panelBackground.withValues(alpha: 0.9),
                highlightColor: AppColors.panelBackground.withValues(alpha: 0.1),
                onTap: storeItemAction,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.panelBackground.withValues(alpha: 0.8),
                        AppColors.panelBackground2.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: AppColors.borderRadiusAll,
                    border: Border.all(
                      color: AppColors.main.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.1),
                        blurRadius: _isHovering ? 50 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon on the left
                      _buildTypeIcon(),
                      const SizedBox(width: 16),

                      // Title and Description in the middle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.storeItemModel.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.storeItemModel.description != null && widget.storeItemModel.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.storeItemModel.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Remaining amount and button on the right
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRemainingAmount(),
                          const SizedBox(height: 8),
                          _buildBuyButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData iconData;

    switch (widget.storeItemModel.type) {
      case TaskTypeEnum.TIMER:
        iconData = (widget.storeItemModel.isTimerActive ?? false) ? Icons.pause : Icons.play_arrow;
        break;
      case TaskTypeEnum.COUNTER:
        iconData = Icons.add;
        break;
      case TaskTypeEnum.CHECKBOX:
        iconData = Icons.check_box;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.main.withValues(alpha: 0.8),
            AppColors.main.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.main.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: 24,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildRemainingAmount() {
    if (widget.storeItemModel.type == TaskTypeEnum.CHECKBOX) {
      return const SizedBox();
    }

    String valueText;
    Color textColor;
    IconData iconData;

    if (widget.storeItemModel.type == TaskTypeEnum.COUNTER) {
      valueText = "${widget.storeItemModel.currentCount}";
      textColor = AppColors.text;
      iconData = Icons.numbers;
    } else {
      // TIMER
      valueText = widget.storeItemModel.currentDuration!.textShortDynamic();
      textColor = (widget.storeItemModel.isTimerActive ?? false) ? AppColors.main : AppColors.text;
      iconData = Icons.timer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.panelBackground2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.main.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            valueText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton() {
    String actionText;
    String amountText;

    if (widget.storeItemModel.type == TaskTypeEnum.COUNTER) {
      amountText = "${widget.storeItemModel.addCount}";
    } else {
      amountText = widget.storeItemModel.addDuration?.textLongDynamicWithoutZero() ?? "";
    }

    if (widget.storeItemModel.credit == 0) {
      actionText = LocaleKeys.Add.tr();
    } else {
      actionText = LocaleKeys.Buy.tr();
    }

    return InkWell(
      borderRadius: AppColors.borderRadiusAll,
      onTap: () async {
        // Null check for loginUser
        if (loginUser == null) {
          LogService.error('❌ Store Item Purchase: loginUser is null');
          return;
        }

        // Deduct credit (can go negative)
        loginUser!.userCredit -= widget.storeItemModel.credit;

        dynamic value; // Değişiklik miktarı

        if (widget.storeItemModel.type == TaskTypeEnum.TIMER) {
          widget.storeItemModel.currentDuration = widget.storeItemModel.currentDuration! + widget.storeItemModel.addDuration!;
          value = widget.storeItemModel.addDuration; // Eklenen süre miktarı
        } else {
          widget.storeItemModel.currentCount = widget.storeItemModel.currentCount! + widget.storeItemModel.addCount!;
          value = widget.storeItemModel.addCount; // Eklenen sayı miktarı
        }

        // Log kaydini oluştur
        TaskProgressViewModel.addStoreItemLog(
          itemId: widget.storeItemModel.id,
          action: "Purchase",
          value: value, // Sadece değişiklik miktarını kaydet
          type: widget.storeItemModel.type,
        );

        await ServerManager().updateUser(userModel: loginUser!);
        await ServerManager().updateItem(itemModel: widget.storeItemModel);

        // Sync with UserProvider to update UI
        UserProvider().setUser(loginUser!);

        StoreProvider().setStateItems();
      },
      child: Container(
        height: 32,
        constraints: const BoxConstraints(minWidth: 100),
        decoration: BoxDecoration(
          borderRadius: AppColors.borderRadiusAll,
          gradient: LinearGradient(
            colors: [AppColors.main.withAlpha(150), AppColors.main],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.main.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Action + Amount
            Text(
              "$actionText $amountText",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Credit amount (if not zero)
            if (widget.storeItemModel.credit != 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${widget.storeItemModel.credit}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.monetization_on,
                      size: 12,
                      color: Color.fromARGB(255, 226, 230, 0),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void storeItemAction() async {
    dynamic value; // Değişiklik miktarı
    String action; // Action türü

    if (widget.storeItemModel.type == TaskTypeEnum.COUNTER) {
      widget.storeItemModel.currentCount = widget.storeItemModel.currentCount! - 1;
      value = -1; // Kullanılan miktar (negatif)
      action = "Usage";
      ServerManager().updateItem(itemModel: widget.storeItemModel);
      // TODO: - olursa disiplin düşecek
    } else {
      // Timer için timer aktif durumunu kaydet
      bool wasTimerActive = widget.storeItemModel.isTimerActive ?? false;

      // Eğer timer durdurulacaksa, önce elapsed time'ı hesapla
      Duration? elapsedTime;
      if (wasTimerActive) {
        final prefs = await SharedPreferences.getInstance();
        String? timerStartTimeStr = prefs.getString('item_timer_start_time_${widget.storeItemModel.id}');
        String? timerStartDurationStr = prefs.getString('item_timer_start_duration_${widget.storeItemModel.id}');

        LogService.debug('DEBUG: Timer will be stopped for item ${widget.storeItemModel.id}');
        LogService.debug('DEBUG: timerStartTimeStr = $timerStartTimeStr');
        LogService.debug('DEBUG: timerStartDurationStr = $timerStartDurationStr');

        if (timerStartTimeStr != null && timerStartDurationStr != null) {
          DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));
          DateTime currentTime = DateTime.now();

          // Geçen süreyi hesapla (timer ne kadar çalıştı)
          elapsedTime = currentTime.difference(timerStartTime);

          LogService.debug('DEBUG: timerStartTime = $timerStartTime');
          LogService.debug('DEBUG: currentTime = $currentTime');
          LogService.debug('DEBUG: elapsedTime = ${elapsedTime.inSeconds} seconds (${elapsedTime.inMinutes}m ${elapsedTime.inSeconds % 60}s)');
          LogService.debug('DEBUG: elapsedTime.inMilliseconds = ${elapsedTime.inMilliseconds}');
        }
      }

      // Timer'ı başlat/durdur
      GlobalTimer().startStopTimer(
        storeItemModel: widget.storeItemModel,
      );

      // Timer durumuna göre log oluştur
      if (!wasTimerActive && (widget.storeItemModel.isTimerActive ?? false)) {
        // Timer başlatıldı
        action = "Timer Started";
        value = Duration.zero; // Başlangıçta değişiklik yok
      } else if (wasTimerActive && !(widget.storeItemModel.isTimerActive ?? false)) {
        // Timer durduruldu - önceden hesaplanan elapsed time'ı kullan
        action = "Timer Stopped";

        if (elapsedTime != null) {
          // Store item timer'ları geri sayım yapar, kullanılan süre negatif olarak log'lanır
          value = -elapsedTime;
          LogService.debug('DEBUG: value to log = ${value.inSeconds} seconds');
          LogService.debug('DEBUG: value.inMinutes = ${value.inMinutes}, value.inSeconds % 60 = ${value.inSeconds % 60}');
        } else {
          LogService.debug('DEBUG: Timer data was not available, logging as zero');
          value = Duration.zero;
        }
      } else {
        // Durum değişmedi
        value = Duration.zero;
        action = "Timer Action";
      }

      ServerManager().updateItem(itemModel: widget.storeItemModel);
    }

    // Log kaydını oluştur - sadece anlamlı değişiklikler için
    if (widget.storeItemModel.type == TaskTypeEnum.COUNTER || (widget.storeItemModel.type == TaskTypeEnum.TIMER && action == "Timer Stopped")) {
      TaskProgressViewModel.addStoreItemLog(
        itemId: widget.storeItemModel.id,
        action: action,
        value: value,
        type: widget.storeItemModel.type,
      );
    }

    StoreProvider().setStateItems();
  }
}
