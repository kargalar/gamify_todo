import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:provider/provider.dart';

class SetCredit extends StatefulWidget {
  const SetCredit({
    super.key,
  });

  @override
  State<SetCredit> createState() => _SetCreditState();
}

class _SetCreditState extends State<SetCredit> {
  Timer? _longPressTimer;
  bool _isLongPressing = false;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _startLongPress(bool isIncrement, AddStoreItemProvider provider) {
    _isLongPressing = true;

    // İlk değişiklik
    if (isIncrement) {
      setState(() {
        provider.credit++;
      });
    } else {
      if (provider.credit > 0) {
        setState(() {
          provider.credit--;
        });
      }
    }

    // Timer ile sürekli artış/azalış
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted || !_isLongPressing) {
        timer.cancel();
        return;
      }

      if (isIncrement) {
        setState(() {
          provider.credit++;
        });
      } else {
        if (provider.credit > 0) {
          setState(() {
            provider.credit--;
          });
        }
      }
    });
  }

  void _endLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _isLongPressing = false;
  }

  @override
  Widget build(BuildContext context) {
    late final AddStoreItemProvider provider = context.read<AddStoreItemProvider>();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              // Unfocus when tapping
              provider.unfocusAll();
              FocusScope.of(context).unfocus();

              if (provider.credit > 0) {
                setState(() {
                  provider.credit--;
                });
              }
            },
            onLongPressStart: (_) {
              // Unfocus when long pressing
              provider.unfocusAll();
              FocusScope.of(context).unfocus();

              _startLongPress(false, provider);
            },
            onLongPressEnd: (_) {
              _endLongPress();
            },
            onLongPressCancel: () {
              _endLongPress();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppColors.borderRadiusAll,
              ),
              padding: const EdgeInsets.all(5),
              child: const Icon(
                Icons.remove,
                size: 30,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  provider.credit.toString(),
                  style: const TextStyle(
                    fontSize: 25,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.monetization_on),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Unfocus when tapping
              provider.unfocusAll();
              FocusScope.of(context).unfocus();

              setState(() {
                provider.credit++;
              });
            },
            onLongPressStart: (_) {
              // Unfocus when long pressing
              provider.unfocusAll();
              FocusScope.of(context).unfocus();

              _startLongPress(true, provider);
            },
            onLongPressEnd: (_) {
              _endLongPress();
            },
            onLongPressCancel: () {
              _endLongPress();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppColors.borderRadiusAll,
              ),
              padding: const EdgeInsets.all(5),
              child: const Icon(
                Icons.add,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
