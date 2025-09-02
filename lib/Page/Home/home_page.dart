import 'package:flutter/material.dart';
import 'package:next_level/Page/Home/Widget/custom_app_bar.dart';
import 'package:next_level/Page/Home/Widget/task_list.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const Scaffold(
        appBar: CustomAppBar(),
        body: TaskList(),
      ),
    );
  }
}
