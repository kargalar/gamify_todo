import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Profile/Widget/top_item.dart';
import 'package:gamify_todo/Page/Profile/Widget/profile_page_top_section.dart';
import 'package:gamify_todo/Page/Profile/Widget/trait_list.dart';
import 'package:gamify_todo/Page/Profile/Widget/weekly_total_progress_chart.dart';
import 'package:gamify_todo/Page/Settings/settings_page.dart';
import 'package:gamify_todo/Page/Schedule/schedule_page.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Provider/navbar_provider.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:provider/provider.dart';
import 'package:gamify_todo/Page/Profile/Widget/streak_analysis.dart';
import 'package:gamify_todo/Provider/profile_view_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) {
          context.read<NavbarProvider>().currentIndex = 1;
          context.read<NavbarProvider>().pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(LocaleKeys.Profile.tr()),
            leading: const SizedBox(),
            actions: [
              InkWell(
                borderRadius: AppColors.borderRadiusAll,
                onTap: () async {
                  await NavigatorService().goTo(
                    const SchedulePage(),
                    transition: Transition.rightToLeft,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Icon(Icons.calendar_month),
                ),
              ),
              InkWell(
                borderRadius: AppColors.borderRadiusAll,
                onTap: () async {
                  await NavigatorService().goTo(
                    const SettingsPage(),
                    transition: Transition.rightToLeft,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Icon(Icons.settings),
                ),
              ),
            ],
          ),
          body: const ProfilePageContent(),
        ),
      ),
    );
  }
}

class ProfilePageContent extends StatelessWidget {
  const ProfilePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ProfilePageTopSection(),
            SizedBox(height: 40),
            WeeklyTotalProgressChart(),
            SizedBox(height: 40),
            StreakAnalysis(),
            SizedBox(height: 40),
            TopItem(),
            SizedBox(height: 40),
            TraitList(isSkill: false),
            SizedBox(height: 20),
            TraitList(isSkill: true),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
