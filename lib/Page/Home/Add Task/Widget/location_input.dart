import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationInput extends StatelessWidget {
  const LocationInput({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.Location.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: AppColors.borderRadiusAll,
          ),
          child: TextField(
            controller: addTaskProvider.locationController,
            focusNode: addTaskProvider.locationFocus,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: LocaleKeys.EnterLocation.tr(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              suffixIcon: addTaskProvider.locationController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
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
        if (addTaskProvider.locationController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: InkWell(
              onTap: () => _launchMaps(addTaskProvider.locationController.text),
              child: Row(
                children: [
                  Icon(Icons.map, size: 16, color: AppColors.main),
                  const SizedBox(width: 4),
                  Text(
                    LocaleKeys.ShowOnMap.tr(),
                    style: TextStyle(
                      color: AppColors.main,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _launchMaps(String location) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
