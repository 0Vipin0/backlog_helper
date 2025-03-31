import 'package:args/command_runner.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/input_utils.dart';

class UpdatePlanCommand extends Command<void> {
  @override
  final String name = 'plan';
  @override
  final String description = 'Updates an existing planning item.';
  @override
  String get invocation =>
      '${runner?.executableName} update plan --id <PLAN_ID> [arguments]';

  final ExcelService _excelService;
  final bool interactive;

  UpdatePlanCommand(
      {required ExcelService excelService, this.interactive = false})
      : _excelService = excelService {
    // --- Define Arguments ---
    argParser.addOption('id',
        abbr: 'i',
        help: 'The unique ID of the plan item to update (Required).',
        valueHelp: 'PLAN_ID');

    // Optional update fields
    argParser.addOption('title',
        abbr: 't', help: 'New plan item title.', valueHelp: 'PLAN_TITLE');
    argParser.addOption('type',
        help:
            'New plan type. Allowed: [${PlanTypeExtension.allowedValuesString}]',
        valueHelp: 'TYPE',
        allowed: PlanTypeExtension.names,
        allowedHelp: Map.fromEntries(
            PlanType.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('status',
        abbr: 's',
        help: 'New status/health text.',
        valueHelp: 'STATUS_TEXT (e.g., At Risk)'); // String status
    argParser.addOption('start-date',
        help: 'New start date (YYYY-MM-DD).', valueHelp: 'YYYY-MM-DD');
    argParser.addOption('end-date',
        help: 'New end date (YYYY-MM-DD).', valueHelp: 'YYYY-MM-DD');
    argParser.addOption('depends-on',
        help: 'New dependencies (Comma-separated Plan Titles).',
        valueHelp: 'plan1,plan2');
    argParser.addOption('progress',
        help: 'New progress notes.', valueHelp: 'PROGRESS_NOTES');
    argParser.addOption('goal',
        help: 'New related goal title.', valueHelp: 'GOAL_TITLE');
    argParser.addOption('milestones',
        help: 'New key milestones (Related Task Titles).',
        valueHelp: 'task1,task2');
    argParser.addOption('resources',
        help: 'New allocated resources.', valueHelp: 'ALLOCATED_RESOURCES');

    // Clear flags for optional fields
    argParser.addFlag('clear-start-date',
        help: 'Set start date to empty.', negatable: false);
    argParser.addFlag('clear-end-date',
        help: 'Set end date to empty.', negatable: false);
    argParser.addFlag('clear-depends-on',
        help: 'Set dependencies to empty.', negatable: false);
    argParser.addFlag('clear-progress',
        help: 'Set progress to empty.', negatable: false);
    argParser.addFlag('clear-goal',
        help: 'Set related goal to empty.', negatable: false);
    argParser.addFlag('clear-milestones',
        help: 'Set key milestones to empty.', negatable: false);
    argParser.addFlag('clear-resources',
        help: 'Set allocated resources to empty.', negatable: false);
  }

  @override
  Future<void> run() async {
    String? id = argResults?['id'];

    if (interactive && (id == null || id.isEmpty)) {
      id = InputUtils.prompt('Enter the ID of the plan item to update:',
          isRequired: true);
    }
    if (id == null || id.isEmpty) {
      throw UsageException(
          'Plan ID (--id or -i) is required for update.', usage);
    }

    PlanningItem? existingPlan;
    try {
      existingPlan = await _excelService.getItemById<PlanningItem>(
          id, PlanningItem.fromRow);
    } catch (e) {
      print('❌ Error fetching plan item with ID "$id": $e');
      return;
    }

    if (existingPlan == null) {
      print('❌ Plan item with ID "$id" not found.');
      return;
    }

    print('🔄 Updating Plan: ${existingPlan.planItemDescription} (ID: $id)');

    // --- Gather Updated Values ---
    String? title = argResults?['title'];
    String? typeStr = argResults?['type'];
    String? status = argResults?['status']; // String status
    String? startDate = argResults?['start-date'];
    String? endDate = argResults?['end-date'];
    String? dependencies = argResults?['depends-on'];
    String? progress = argResults?['progress'];
    String? goal = argResults?['goal'];
    String? milestones = argResults?['milestones'];
    String? resources = argResults?['resources'];

    if (interactive) {
      print('\nEnter new values or press Enter to keep current.');
      title = InputUtils.prompt('Plan Title',
          isRequired: true, currentValue: existingPlan.planItemDescription);
      typeStr = InputUtils.promptEnum<PlanType>(
          'Type of Plan (${PlanTypeExtension.allowedValuesString})',
          PlanType.values,
          isRequired: true,
          currentValue: existingPlan.typeOfPlan.name);
      status = InputUtils.prompt('Status/Health',
          isRequired: true, currentValue: existingPlan.status); // String status
      startDate = InputUtils.prompt('Start Date (YYYY-MM-DD)',
          validator: InputUtils.isValidDate,
          validationError: 'Invalid date format.',
          currentValue: existingPlan.startDate);
      endDate = InputUtils.prompt('End Date (YYYY-MM-DD)',
          validator: InputUtils.isValidDate,
          validationError: 'Invalid date format.',
          currentValue: existingPlan.endDate);
      dependencies = InputUtils.prompt('Dependencies (Plan Titles)',
          currentValue: existingPlan.dependencies);
      progress =
          InputUtils.prompt('Progress', currentValue: existingPlan.progress);
      goal = InputUtils.prompt('Related Goal Title',
          currentValue: existingPlan.relatedGoal);
      milestones = InputUtils.prompt('Key Milestones (Task Titles)',
          currentValue: existingPlan.keyMilestones);
      resources = InputUtils.prompt('Allocated Resources',
          currentValue: existingPlan.allocatedResources);
      print('--------------------------\n');
    }

    // --- Apply Non-Interactive Args & Validate ---
    title ??= existingPlan.planItemDescription;
    typeStr ??= existingPlan.typeOfPlan.name;
    status ??= existingPlan.status; // String status
    startDate = argResults?.wasParsed('clear-start-date') ?? false
        ? null
        : (startDate ?? existingPlan.startDate);
    endDate = argResults?.wasParsed('clear-end-date') ?? false
        ? null
        : (endDate ?? existingPlan.endDate);
    dependencies = argResults?.wasParsed('clear-depends-on') ?? false
        ? null
        : (dependencies ?? existingPlan.dependencies);
    progress = argResults?.wasParsed('clear-progress') ?? false
        ? null
        : (progress ?? existingPlan.progress);
    goal = argResults?.wasParsed('clear-goal') ?? false
        ? null
        : (goal ?? existingPlan.relatedGoal);
    milestones = argResults?.wasParsed('clear-milestones') ?? false
        ? null
        : (milestones ?? existingPlan.keyMilestones);
    resources = argResults?.wasParsed('clear-resources') ?? false
        ? null
        : (resources ?? existingPlan.allocatedResources);

    // Re-validate
    if (title.isEmpty) {
      throw UsageException('Plan title cannot be empty.', usage);
    }
    final type = PlanTypeExtension.tryParse(typeStr);
    if (type == null) {
      throw UsageException(
          'Invalid type value: "$typeStr". Allowed: ${PlanTypeExtension.allowedValuesString}',
          usage);
    }
    if (status.isEmpty) {
      // Check mandatory string status
      throw UsageException('Status cannot be empty.', usage);
    }
    if (startDate != null &&
        startDate.isNotEmpty &&
        !InputUtils.isValidDate(startDate)) {
      throw UsageException(
          'Invalid start date format: "$startDate". Use YYYY-MM-DD.', usage);
    }
    if (endDate != null &&
        endDate.isNotEmpty &&
        !InputUtils.isValidDate(endDate)) {
      throw UsageException(
          'Invalid end date format: "$endDate". Use YYYY-MM-DD.', usage);
    }

    // --- Create Updated Plan Object ---
    final updatedPlan = PlanningItem(
      id: existingPlan.id,
      createdAt: existingPlan.createdAt, // Preserve creation date
      planItemDescription: title,
      typeOfPlan: type,
      status: status, // Use updated string status
      startDate: startDate,
      endDate: endDate,
      dependencies: dependencies,
      progress: progress,
      relatedGoal: goal,
      keyMilestones: milestones,
      allocatedResources: resources,
    );

    // --- Save Update ---
    try {
      final success = await _excelService.updateItem<PlanningItem>(updatedPlan);
      if (success) {
        print('✅ Planning item with ID "$id" updated successfully.');
      }
    } catch (e) {
      print(
          '❌ Error updating plan item with ID "$id" in Excel file "${_excelService.filePath}": $e');
    }
  }
}
