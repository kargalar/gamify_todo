import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
    return MouseRegion(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
              onLongPress: () async {
                await NavigatorService()
                    .goTo(
                      AddStoreItemPage(editItemModel: widget.storeItemModel),
                      transition: Transition.size,
                    )
                    .then(
                      (value) => StoreProvider().setStateItems(),
                    );
              },
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and credit
                    Row(
                      children: [
                        _buildTypeIcon(),
                        const Spacer(),
                        _buildCreditAmount(),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      widget.storeItemModel.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Progress
                    _buildProgressIndicator(),
                    const SizedBox(height: 12),

                    // Buy button
                    _buildBuyButton(),
                  ],
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

  Widget _buildProgressIndicator() {
    if (widget.storeItemModel.type == TaskTypeEnum.CHECKBOX) {
      return const SizedBox(height: 0);
    }

    String valueText;
    Color textColor;

    if (widget.storeItemModel.type == TaskTypeEnum.COUNTER) {
      valueText = "${widget.storeItemModel.currentCount}";
      textColor = AppColors.text;
    } else {
      // TIMER
      valueText = widget.storeItemModel.currentDuration!.textShortDynamic();
      textColor = (widget.storeItemModel.isTimerActive ?? false) ? AppColors.main : AppColors.text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.storeItemModel.type == TaskTypeEnum.COUNTER ? Icons.numbers : Icons.timer,
          size: 14,
          color: AppColors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          valueText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCreditAmount() {
    if (widget.storeItemModel.credit == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${widget.storeItemModel.credit}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.monetization_on,
            size: 14,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton() {
    String buttonText;

    if (widget.storeItemModel.credit == 0) {
      if (widget.storeItemModel.type == TaskTypeEnum.COUNTER) {
        buttonText = "${LocaleKeys.Add.tr()} ${widget.storeItemModel.addCount}";
      } else {
        buttonText = "${LocaleKeys.Add.tr()} ${widget.storeItemModel.addDuration?.textLongDynamicWithoutZero()}";
      }
    } else {
      if (widget.storeItemModel.type == TaskTypeEnum.COUNTER) {
        buttonText = "${LocaleKeys.Buy.tr()} ${widget.storeItemModel.addCount}";
      } else {
        buttonText = "${LocaleKeys.Buy.tr()} ${widget.storeItemModel.addDuration?.textLongDynamicWithoutZero()}";
      }
    }
    return InkWell(
      borderRadius: AppColors.borderRadiusAll,
      onTap: () async {
        // Null check for loginUser
        if (loginUser == null) {
          debugPrint('❌ Store Item Purchase: loginUser is null');
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
        height: 36,
        constraints: const BoxConstraints(minWidth: 80),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Center(
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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

        debugPrint('DEBUG: Timer will be stopped for item ${widget.storeItemModel.id}');
        debugPrint('DEBUG: timerStartTimeStr = $timerStartTimeStr');
        debugPrint('DEBUG: timerStartDurationStr = $timerStartDurationStr');

        if (timerStartTimeStr != null && timerStartDurationStr != null) {
          DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));
          DateTime currentTime = DateTime.now();

          // Geçen süreyi hesapla (timer ne kadar çalıştı)
          elapsedTime = currentTime.difference(timerStartTime);

          debugPrint('DEBUG: timerStartTime = $timerStartTime');
          debugPrint('DEBUG: currentTime = $currentTime');
          debugPrint('DEBUG: elapsedTime = ${elapsedTime.inSeconds} seconds (${elapsedTime.inMinutes}m ${elapsedTime.inSeconds % 60}s)');
          debugPrint('DEBUG: elapsedTime.inMilliseconds = ${elapsedTime.inMilliseconds}');
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
          debugPrint('DEBUG: value to log = ${value.inSeconds} seconds');
          debugPrint('DEBUG: value.inMinutes = ${value.inMinutes}, value.inSeconds % 60 = ${value.inSeconds % 60}');
        } else {
          debugPrint('DEBUG: Timer data was not available, logging as zero');
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
