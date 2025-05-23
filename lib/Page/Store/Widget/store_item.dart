import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Store/add_store_item_page.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

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
                  color: AppColors.panelBackground,
                  borderRadius: AppColors.borderRadiusAll,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.1),
                      blurRadius: _isHovering ? 50 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    // Type icon
                    _buildTypeIcon(),
                    const SizedBox(width: 12),

                    // Title and progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(height: 2),
                          _buildProgressIndicator(),
                        ],
                      ),
                    ),

                    // Buy button
                    _buildBuyButton(),
                    const SizedBox(width: 8),

                    // Credit amount
                    _buildCreditAmount(),
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
        iconData = widget.storeItemModel.isTimerActive! ? Icons.pause : Icons.play_arrow;
        break;
      case TaskTypeEnum.COUNTER:
        iconData = Icons.add;
        break;
      case TaskTypeEnum.CHECKBOX:
        iconData = Icons.check_box;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.panelBackground2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 18,
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
      textColor = widget.storeItemModel.isTimerActive! ? AppColors.main : AppColors.text;
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${widget.storeItemModel.credit}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.monetization_on,
            size: 12,
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
        loginUser!.userCredit -= widget.storeItemModel.credit;

        if (widget.storeItemModel.type == TaskTypeEnum.TIMER) {
          widget.storeItemModel.currentDuration = widget.storeItemModel.currentDuration! + widget.storeItemModel.addDuration!;
        } else {
          widget.storeItemModel.currentCount = widget.storeItemModel.currentCount! + widget.storeItemModel.addCount!;
        }

        await ServerManager().updateUser(userModel: loginUser!);
        await ServerManager().updateItem(itemModel: widget.storeItemModel);
        StoreProvider().setStateItems();
      },
      child: Container(
        height: 30,
        constraints: const BoxConstraints(minWidth: 60),
        decoration: BoxDecoration(
          borderRadius: AppColors.borderRadiusAll,
          gradient: LinearGradient(
            colors: [AppColors.main.withAlpha(150), AppColors.main],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Center(
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 11,
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
    if (widget.storeItemModel.type == TaskTypeEnum.COUNTER) {
      widget.storeItemModel.currentCount = widget.storeItemModel.currentCount! - 1;
      ServerManager().updateItem(itemModel: widget.storeItemModel);
      // TODO: - olursa disiplin düşecek
    } else {
      GlobalTimer().startStopTimer(
        storeItemModel: widget.storeItemModel,
      );

      ServerManager().updateItem(itemModel: widget.storeItemModel);
    }

    StoreProvider().setStateItems();
  }
}
