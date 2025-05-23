import 'package:flutter/material.dart';
import 'package:next_level/Page/Home/Widget/custom_app_bar.dart';
import 'package:next_level/Page/Home/Widget/task_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(),
      body: TaskList(),
    );
  }
}
