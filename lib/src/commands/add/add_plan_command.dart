import 'package:args/command_runner.dart';
import 'package:uuid/uuid.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/input_utils.dart';

class AddPlanCommand extends Command<void> {
  @override
  final String name = 'plan';
  @override
  final String description = 'Adds a new planning item.';
   @override
  String get invocation => '${runner?.executableName} add plan [arguments]';

  final ExcelService _excelService;
  final bool interactive;

  AddPlanCommand({required ExcelService excelService, this.interactive = false})
      : _excelService = excelService {
    // --- Define Arguments ---
    // Mandatory
    argParser.addOption('title', abbr: 't', help: '(Required) What is the plan item?', valueHelp: 'PLAN_TITLE');
    argParser.addOption('type', help: '(Required) What type of plan is this? \nAllowed: [${PlanTypeExtension.allowedValuesString}]', valueHelp: 'TYPE', allowed: PlanTypeExtension.names, allowedHelp: Map.fromEntries(PlanType.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('status', abbr:'s', help: '(Required) What is the current status/health of this plan item?', valueHelp: 'STATUS_TEXT (e.g., On Track)'); // Mandatory String

    // Optional
    argParser.addOption('start-date', help: 'When should this plan item ideally start? (YYYY-MM-DD)', valueHelp: 'YYYY-MM-DD');
    argParser.addOption('end-date', help: 'When is the expected completion date? (YYYY-MM-DD)', valueHelp: 'YYYY-MM-DD');
    argParser.addOption('depends-on', help: 'Does this plan item depend on any other items? (Comma-separated Plan Titles)', valueHelp: 'plan1,plan2');
    argParser.addOption('progress', help: 'What is the current progress? (e.g., 0%, 50%, Notes)', valueHelp: 'PROGRESS_NOTES');
    argParser.addOption('goal', help: 'What overall goal does this contribute to? (Goal Title)', valueHelp: 'GOAL_TITLE');
    argParser.addOption('milestones', help: 'What are the key milestones? (Related Task Titles)', valueHelp: 'task1,task2');
    argParser.addOption('resources', help: 'What resources are allocated?', valueHelp: 'ALLOCATED_RESOURCES');
 }

  @override
  Future<void> run() async {
    String? title = argResults?['title'];
    String? typeStr = argResults?['type'];
    String? status = argResults?['status']; // Mandatory String
    String? startDate = argResults?['start-date'];
    String? endDate = argResults?['end-date'];
    String? dependencies = argResults?['depends-on'];
    String? progress = argResults?['progress'];
    String? goal = argResults?['goal'];
    String? milestones = argResults?['milestones'];
    String? resources = argResults?['resources'];

    // --- Interactive Mode ---
    if (interactive) {
       print('\n--- Adding New Planning Item ---');
       title = InputUtils.prompt('What is the plan item?', isRequired: true, currentValue: title);
       typeStr = InputUtils.promptEnum<PlanType>('What type of plan is this? (${PlanTypeExtension.allowedValuesString})', PlanType.values, isRequired: true, currentValue: typeStr);
       status = InputUtils.prompt('What is the current status/health? (e.g., On Track)', isRequired: true, currentValue: status);
       startDate = InputUtils.prompt('Ideal start date? (YYYY-MM-DD) (Optional):', validator: InputUtils.isValidDate, validationError: 'Invalid date format.', currentValue: startDate);
       endDate = InputUtils.prompt('Expected end date? (YYYY-MM-DD) (Optional):', validator: InputUtils.isValidDate, validationError: 'Invalid date format.', currentValue: endDate);
       dependencies = InputUtils.prompt('Depends on which plans? (comma-separated titles) (Optional):', currentValue: dependencies);
       progress = InputUtils.prompt('Current progress? (Optional):', currentValue: progress);
       goal = InputUtils.prompt('Related overall goal title? (Optional):', currentValue: goal);
       milestones = InputUtils.prompt('Key milestones? (Related Task Titles) (Optional):', currentValue: milestones);
       resources = InputUtils.prompt('Allocated resources? (Optional):', currentValue: resources);
       print('--------------------------\n');
    }

    // --- Validation ---
     if (title == null || title.isEmpty) {
       throw UsageException('Plan title (--title or -t) is required.', usage);
     }
     if (typeStr == null || typeStr.isEmpty) {
        throw UsageException('Type of plan (--type) is required.', usage);
    }
     final type = PlanTypeExtension.tryParse(typeStr);
     if (type == null) {
        throw UsageException('Invalid type value: "$typeStr". Allowed: ${PlanTypeExtension.allowedValuesString}', usage);
     }
     if (status == null || status.isEmpty) {
        throw UsageException('Status (--status or -s) is required.', usage);
     }
     if (startDate != null && startDate.isNotEmpty && !InputUtils.isValidDate(startDate)) {
       throw UsageException('Invalid start date format: "$startDate". Use YYYY-MM-DD.', usage);
     }
      if (endDate != null && endDate.isNotEmpty && !InputUtils.isValidDate(endDate)) {
       throw UsageException('Invalid end date format: "$endDate". Use YYYY-MM-DD.', usage);
     }

    // --- Create and Save ---
    final newPlan = PlanningItem(
      id: const Uuid().v4(),
      planItemDescription: title, // Map title argument to model field
      typeOfPlan: type,
      status: status, // Save the mandatory string status
      startDate: startDate,
      endDate: endDate,
      dependencies: dependencies,
      progress: progress,
      relatedGoal: goal,
      keyMilestones: milestones,
      allocatedResources: resources,
    );

    try {
      final addedId = await _excelService.addItem<PlanningItem>(newPlan);
      print('✅ Planning item added successfully with ID: $addedId');
    } catch (e) {
      print('❌ Error adding planning item to Excel file "${_excelService.filePath}": $e');
    }
  }
}
