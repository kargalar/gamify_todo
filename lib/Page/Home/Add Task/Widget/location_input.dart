import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationInput extends StatelessWidget {
  const LocationInput({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          ClickableTooltip(
            title: LocaleKeys.Location.tr(),
            bulletPoints: const ["Enter a location for your task", "Location will be displayed with an icon", "Click location to open in Google Maps", "Limited to 20 characters for display"],
            child: Container(
              color: AppColors.transparent,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppColors.main,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    LocaleKeys.Location.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Location input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.main.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: addTaskProvider.locationController,
              focusNode: addTaskProvider.locationFocus,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: LocaleKeys.EnterLocation.tr(),
                hintStyle: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.text.withValues(alpha: 0.4),
                  size: 16,
                ),
                suffixIcon: addTaskProvider.locationController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.text.withValues(alpha: 0.6),
                          size: 16,
                        ),
                        onPressed: () {
                          addTaskProvider.locationController.clear();
                          addTaskProvider.updateLocation();
                          // Unfocus after clearing
                          try {
                            if (addTaskProvider.locationFocus.hashCode != 0) {
                              addTaskProvider.locationFocus.unfocus();
                            }
                          } catch (e) {
                            // Focus node may have issues
                          }
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                addTaskProvider.updateLocation();
              },
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                // Unfocus when done editing
                try {
                  if (addTaskProvider.locationFocus.hashCode != 0) {
                    addTaskProvider.locationFocus.unfocus();
                  }
                } catch (e) {
                  // Focus node may have issues
                }
              },
            ),
          ),

          // Show on map button
          if (addTaskProvider.locationController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _launchMaps(addTaskProvider.locationController.text),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 14,
                          color: AppColors.main,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          LocaleKeys.ShowOnMap.tr(),
                          style: TextStyle(
                            color: AppColors.main,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchMaps(String location) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
