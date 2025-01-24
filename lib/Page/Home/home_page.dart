import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Page/Home/Widget/day_item.dart';
import 'package:gamify_todo/Page/Home/Widget/go_today_button.dart';
import 'package:gamify_todo/Page/Home/Widget/task_list.dart';
import 'package:gamify_todo/Service/notification_services.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:provider/provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedDate = context.watch<TaskProvider>().selectedDate;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 200,
        leading: Row(
          children: [
            DayItem(date: selectedDate.subtract(const Duration(days: 1))),
            DayItem(date: selectedDate),
            DayItem(date: selectedDate.add(const Duration(days: 1))),
            const GoTodayButton(),
          ],
        ),
        actions: [
          // test button
          if (kDebugMode)
            InkWell(
              onTap: () async {
                NotificationService().notificaitonTest();
              },
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Text("Test Notificaiton"),
              ),
            ),
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () {
                    TaskProvider().changeShowCompleted();
                  },
                  child: Text("${TaskProvider().showCompleted ? LocaleKeys.Hide.tr() : LocaleKeys.Show.tr()} ${LocaleKeys.Completed.tr()}"),
                ),
              ];
            },
          ),
        ],
      ),
      body: const TaskList(),
    );
  }
}
