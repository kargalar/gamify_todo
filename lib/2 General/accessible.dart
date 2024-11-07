import 'package:gamify_todo/2%20General/app_colors.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:gamify_todo/7%20Enum/trait_type_enum.dart';
import 'package:gamify_todo/8%20Model/rutin_model.dart';
import 'package:gamify_todo/8%20Model/trait_model.dart';

// TODO: test için el ile verildi normalde veritabınndan gelecek

List<RutinModel> rutinList = [
  RutinModel(
    id: 0,
    title: "Python",
    type: TaskTypeEnum.TIMER,
    createdDate: DateTime.now(),
    startDate: DateTime.now(),
    isNotificationOn: false,
    remainingDuration: const Duration(hours: 1, minutes: 0),
    repeatDays: [1, 5],
    isCompleted: false,
    attirbuteIDList: [1, 2],
    skillIDList: [1],
  ),
  RutinModel(
    id: 1,
    title: "Makale oku",
    type: TaskTypeEnum.COUNTER,
    createdDate: DateTime.now(),
    startDate: DateTime.now(),
    isNotificationOn: false,
    remainingDuration: const Duration(minutes: 15),
    targetCount: 10,
    repeatDays: [1, 5],
    isCompleted: false,
  )
];

List<TraitModel> traitList = [
  TraitModel(
    id: 0,
    title: 'Brain',
    icon: "🧠",
    type: TraitTypeEnum.ATTIRBUTE,
    color: AppColors.red,
  ),
  TraitModel(
    id: 1,
    title: 'Health',
    icon: "❤️",
    type: TraitTypeEnum.ATTIRBUTE,
    color: AppColors.blue,
  ),
  TraitModel(
    id: 2,
    title: 'Power',
    icon: "💪",
    type: TraitTypeEnum.ATTIRBUTE,
    color: AppColors.deepGreen,
  ),
  // Skill
  TraitModel(
    id: 0,
    title: 'Flutter',
    icon: "💻",
    type: TraitTypeEnum.SKILL,
    color: AppColors.red,
  ),
  TraitModel(
    id: 1,
    title: 'Book',
    icon: "📖",
    type: TraitTypeEnum.SKILL,
    color: AppColors.deepPurple,
  ),
];
