import 'package:args/command_runner.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/input_utils.dart';

class UpdateGoalCommand extends Command<void> {
  @override
  final String name = 'goal';
  @override
  final String description = 'Updates an existing future goal.';
  @override
  String get invocation =>
      '${runner?.executableName} update goal --id <GOAL_ID> [arguments]';

  final ExcelService _excelService;
  final bool interactive;

  UpdateGoalCommand(
      {required ExcelService excelService, this.interactive = false})
      : _excelService = excelService {
    // --- Define Arguments ---
    argParser.addOption('id',
        abbr: 'i',
        help: 'The unique ID of the goal to update (Required).',
        valueHelp: 'GOAL_ID');

    // Optional update fields
    argParser.addOption('title',
        abbr: 't', help: 'New goal title.', valueHelp: 'GOAL_TITLE');
    argParser.addOption('target-date',
        help: 'New target completion date (YYYY-MM-DD).',
        valueHelp: 'YYYY-MM-DD');
    argParser.addOption('priority',
        abbr: 'p',
        help:
            'New priority. Allowed: [${PriorityExtension.allowedValuesString}]',
        valueHelp: 'PRIORITY',
        allowed: PriorityExtension.names,
        allowedHelp: Map.fromEntries(
            Priority.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('status',
        abbr: 's',
        help:
            'New status. Allowed: [${GoalStatusExtension.allowedValuesString}]',
        valueHelp: 'STATUS',
        allowed: GoalStatusExtension.names,
        allowedHelp: Map.fromEntries(
            GoalStatus.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('kpis', help: 'New KPIs.', valueHelp: 'KPIS');
    argParser.addOption('resources',
        help: 'New resources required.', valueHelp: 'RESOURCES');
    argParser.addOption('motivation',
        help: 'New motivation notes.', valueHelp: 'MOTIVATION_NOTES');
    argParser.addOption('first-step',
        help: 'New first step (Related Task Title).', valueHelp: 'TASK_TITLE');
    argParser.addOption('challenges',
        help: 'New potential challenges (Related Obstacle Titles).',
        valueHelp: 'obstacle1,obstacle2');
    argParser.addOption('support',
        help: 'New support contacts.', valueHelp: 'CONTACT_INFO');

    // Clear flags for optional fields
    argParser.addFlag('clear-status',
        help: 'Set status to empty.', negatable: false);
    argParser.addFlag('clear-kpis',
        help: 'Set KPIs to empty.', negatable: false);
    argParser.addFlag('clear-resources',
        help: 'Set resources required to empty.', negatable: false);
    argParser.addFlag('clear-motivation',
        help: 'Set motivation to empty.', negatable: false);
    argParser.addFlag('clear-first-step',
        help: 'Set first step to empty.', negatable: false);
    argParser.addFlag('clear-challenges',
        help: 'Set potential challenges to empty.', negatable: false);
    argParser.addFlag('clear-support',
        help: 'Set support contacts to empty.', negatable: false);
  }

  @override
  Future<void> run() async {
    String? id = argResults?['id'];

    if (interactive && (id == null || id.isEmpty)) {
      id = InputUtils.prompt('Enter the ID of the goal to update:',
          isRequired: true);
    }
    if (id == null || id.isEmpty) {
      throw UsageException(
          'Goal ID (--id or -i) is required for update.', usage);
    }

    FutureGoal? existingGoal;
    try {
      existingGoal =
          await _excelService.getItemById<FutureGoal>(id, FutureGoal.fromRow);
    } catch (e) {
      print('❌ Error fetching goal with ID "$id": $e');
      return;
    }

    if (existingGoal == null) {
      print('❌ Goal with ID "$id" not found.');
      return;
    }

    print('🔄 Updating Goal: ${existingGoal.goalDescription} (ID: $id)');

    // --- Gather Updated Values ---
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

    if (interactive) {
      print('\nEnter new values or press Enter to keep current.');
      title = InputUtils.prompt('Goal Title',
          isRequired: true, currentValue: existingGoal.goalDescription);
      targetDate = InputUtils.prompt('Target Completion Date (YYYY-MM-DD)',
          isRequired: true,
          validator: InputUtils.isValidDate,
          validationError: 'Invalid date format.',
          currentValue: existingGoal.targetCompletionDate);
      priorityStr = InputUtils.promptEnum<Priority>(
          'Priority (${PriorityExtension.allowedValuesString})',
          Priority.values,
          isRequired: true,
          currentValue: existingGoal.priority.name);
      statusStr = InputUtils.promptEnum<GoalStatus>(
          'Status (${GoalStatusExtension.allowedValuesString})',
          GoalStatus.values,
          currentValue: existingGoal.currentStatus?.name);
      kpis = InputUtils.prompt('KPIs', currentValue: existingGoal.kpis);
      resources = InputUtils.prompt('Resources Required',
          currentValue: existingGoal.resourcesRequired);
      motivation = InputUtils.prompt('Motivation',
          currentValue: existingGoal.motivation);
      firstStep = InputUtils.prompt('First Step (Task Title)',
          currentValue: existingGoal.firstStep);
      challenges = InputUtils.prompt('Potential Challenges (Obstacle Titles)',
          currentValue: existingGoal.potentialChallenges);
      support = InputUtils.prompt('Support Contacts',
          currentValue: existingGoal.supportContacts);
      print('--------------------------\n');
    }

    // --- Apply Non-Interactive Args & Validate ---
    title ??= existingGoal.goalDescription;
    targetDate ??= existingGoal.targetCompletionDate;
    priorityStr ??= existingGoal.priority.name;
    statusStr = argResults?.wasParsed('clear-status') ?? false
        ? null
        : (statusStr ?? existingGoal.currentStatus?.name);
    kpis = argResults?.wasParsed('clear-kpis') ?? false
        ? null
        : (kpis ?? existingGoal.kpis);
    resources = argResults?.wasParsed('clear-resources') ?? false
        ? null
        : (resources ?? existingGoal.resourcesRequired);
    motivation = argResults?.wasParsed('clear-motivation') ?? false
        ? null
        : (motivation ?? existingGoal.motivation);
    firstStep = argResults?.wasParsed('clear-first-step') ?? false
        ? null
        : (firstStep ?? existingGoal.firstStep);
    challenges = argResults?.wasParsed('clear-challenges') ?? false
        ? null
        : (challenges ?? existingGoal.potentialChallenges);
    support = argResults?.wasParsed('clear-support') ?? false
        ? null
        : (support ?? existingGoal.supportContacts);

    // Re-validate
    if (title.isEmpty) {
      throw UsageException('Goal title cannot be empty.', usage);
    }
    if (!InputUtils.isValidDate(targetDate)) {
      throw UsageException(
          'Invalid target date format: "$targetDate". Use YYYY-MM-DD.', usage);
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

    // --- Create Updated Goal Object ---
    final updatedGoal = FutureGoal(
      id: existingGoal.id,
      createdAt: existingGoal.createdAt, // Preserve creation date
      goalDescription: title,
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

    // --- Save Update ---
    try {
      final success = await _excelService.updateItem<FutureGoal>(updatedGoal);
      if (success) {
        print('✅ Goal with ID "$id" updated successfully.');
      }
    } catch (e) {
      print(
          '❌ Error updating goal with ID "$id" in Excel file "${_excelService.filePath}": $e');
    }
  }
}
