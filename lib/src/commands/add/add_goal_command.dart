import 'package:args/command_runner.dart';
import 'package:uuid/uuid.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/input_utils.dart';

class AddGoalCommand extends Command<void> {
  @override
  final String name = 'goal';
  @override
  final String description = 'Adds a new future goal.';
  @override
  String get invocation => '${runner?.executableName} add goal [arguments]';

  final ExcelService _excelService;
  final bool interactive;

  AddGoalCommand({required ExcelService excelService, this.interactive = false})
      : _excelService = excelService {
    // --- Define Arguments (Based on Question Table & Model) ---
    // Mandatory
    argParser.addOption('title',
        abbr: 't',
        help: '(Required) What is your goal?',
        valueHelp: 'GOAL_TITLE');
    argParser.addOption('target-date',
        help: '(Required) By when do you aim to complete it? (YYYY-MM-DD)',
        valueHelp: 'YYYY-MM-DD');
    argParser.addOption('priority',
        abbr: 'p',
        help:
            '(Required) How important is this goal? \nAllowed: [${PriorityExtension.allowedValuesString}]',
        valueHelp: 'PRIORITY',
        allowed: PriorityExtension.names,
        allowedHelp: Map.fromEntries(
            Priority.values.map((e) => MapEntry(e.name, e.description))));

    // Optional
    argParser.addOption('status',
        abbr: 's',
        help:
            'What is the current status? \nAllowed: [${GoalStatusExtension.allowedValuesString}]',
        valueHelp: 'STATUS',
        allowed: GoalStatusExtension.names,
        allowedHelp: Map.fromEntries(
            GoalStatus.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('kpis',
        help: 'What specific metrics will indicate success?',
        valueHelp: 'KPIS');
    argParser.addOption('resources',
        help: 'What resources do you anticipate needing?',
        valueHelp: 'RESOURCES');
    argParser.addOption('motivation',
        help: 'Why is this goal important to you?',
        valueHelp: 'MOTIVATION_NOTES');
    argParser.addOption('first-step',
        help: 'What is the first step you need to take? (Related Task Title)',
        valueHelp: 'TASK_TITLE');
    argParser.addOption('challenges',
        help:
            'What potential challenges might you encounter? (Related Obstacle Titles)',
        valueHelp: 'obstacle1,obstacle2');
    argParser.addOption('support',
        help: 'Who can support you in achieving this goal?',
        valueHelp: 'CONTACT_INFO');
  }

  @override
  Future<void> run() async {
    String? title = argResults?['title'];
    String? targetDate = argResults?['target-date'];
    String? priorityStr = argResults?['priority'];
    String? statusStr = argResults?['status'];
    String? kpis = argResults?['kpis'];
    String? resources = argResults?['resources'];
    String? motivation = argResults?['motivation'];
    String? firstStep = argResults?['first-step'];
    String? challenges = argResults?['challenges'];
    String? support = argResults?['support'];

    // --- Interactive Mode ---
    if (interactive) {
      print('\n--- Adding New Future Goal ---');
      title = InputUtils.prompt('What is your goal?',
          isRequired: true, currentValue: title);
      targetDate = InputUtils.prompt('Target completion date? (YYYY-MM-DD)',
          isRequired: true,
          validator: InputUtils.isValidDate,
          validationError: 'Invalid date format.',
          currentValue: targetDate);
      priorityStr = InputUtils.promptEnum<Priority>(
          'How important is this goal? (${PriorityExtension.allowedValuesString})',
          Priority.values,
          isRequired: true,
          currentValue: priorityStr);
      statusStr = InputUtils.promptEnum<GoalStatus>(
          'Current status? (${GoalStatusExtension.allowedValuesString}) (Optional):',
          GoalStatus.values,
          currentValue: statusStr);
      kpis = InputUtils.prompt('KPIs to measure success? (Optional):',
          currentValue: kpis);
      resources = InputUtils.prompt('Resources needed? (Optional):',
          currentValue: resources);
      motivation = InputUtils.prompt('Why is this goal important? (Optional):',
          currentValue: motivation);
      firstStep = InputUtils.prompt(
          'What is the first step? (Related Task Title) (Optional):',
          currentValue: firstStep);
      challenges = InputUtils.prompt(
          'Potential challenges? (Related Obstacle Titles) (Optional):',
          currentValue: challenges);
      support = InputUtils.prompt('Who can support you? (Optional):',
          currentValue: support);
      print('--------------------------\n');
    }

    // --- Validation ---
    if (title == null || title.isEmpty) {
      throw UsageException('Goal title (--title or -t) is required.', usage);
    }
    if (targetDate == null || targetDate.isEmpty) {
      throw UsageException(
          'Target completion date (--target-date) is required.', usage);
    }
    if (!InputUtils.isValidDate(targetDate)) {
      throw UsageException(
          'Invalid target date format: "$targetDate". Use YYYY-MM-DD.', usage);
    }
    if (priorityStr == null || priorityStr.isEmpty) {
      throw UsageException('Priority (--priority or -p) is required.', usage);
    }
    final priority = PriorityExtension.tryParse(priorityStr);
    if (priority == null) {
      throw UsageException(
          'Invalid priority value: "$priorityStr". Allowed: ${PriorityExtension.allowedValuesString}',
          usage);
    }

    final status = GoalStatusExtension.tryParse(statusStr);
    if (statusStr != null && statusStr.isNotEmpty && status == null) {
      throw UsageException(
          'Invalid status value: "$statusStr". Allowed: ${GoalStatusExtension.allowedValuesString}',
          usage);
    }

    // --- Create and Save ---
    final newGoal = FutureGoal(
      id: const Uuid().v4(),
      goalDescription:
          title, // Map title argument to goalDescription model field
      targetCompletionDate: targetDate,
      priority: priority,
      currentStatus: status,
      kpis: kpis,
      resourcesRequired: resources,
      motivation: motivation,
      firstStep: firstStep,
      potentialChallenges: challenges,
      supportContacts: support,
    );

    try {
      final addedId = await _excelService.addItem<FutureGoal>(newGoal);
      print('✅ Future goal added successfully with ID: $addedId');
    } catch (e) {
      print(
          '❌ Error adding goal to Excel file "${_excelService.filePath}": $e');
    }
  }
}
