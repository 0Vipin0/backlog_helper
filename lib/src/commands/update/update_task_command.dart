import 'package:args/command_runner.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/input_utils.dart';

class UpdateTaskCommand extends Command<void> {
  @override
  final String name = 'task';
  @override
  final String description = 'Updates an existing backlog task.';
   @override
  String get invocation => '${runner?.executableName} update task --id <TASK_ID> [arguments]';

  final ExcelService _excelService;
  final bool interactive;

  UpdateTaskCommand({required ExcelService excelService, this.interactive = false})
      : _excelService = excelService {

    // --- Define Arguments ---
    argParser.addOption('id', abbr: 'i', help: 'The unique ID of the task to update (Required).', valueHelp: 'TASK_ID');

    // Add ALL other fields as optional arguments for non-interactive update
    argParser.addOption('title', abbr: 't', help: 'New title for the task.', valueHelp: 'TASK_TITLE');
    argParser.addOption('priority', abbr: 'p', help: 'New priority. Allowed: [${PriorityExtension.allowedValuesString}]', valueHelp: 'PRIORITY', allowed: PriorityExtension.names, allowedHelp: Map.fromEntries(Priority.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('description', abbr: 'd', help: 'New description.', valueHelp: 'DESCRIPTION');
    argParser.addOption('effort', abbr: 'e', help: "New effort estimate.", valueHelp: 'EFFORT_ESTIMATE');
    argParser.addOption('status', abbr: 's', help: 'New status. Allowed: [${TaskStatusExtension.allowedValuesString}]', valueHelp: 'STATUS', allowed: TaskStatusExtension.names, allowedHelp: Map.fromEntries(TaskStatus.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('due-date', help: 'New due date (YYYY-MM-DD).', valueHelp: 'YYYY-MM-DD');
    argParser.addOption('tags', help: 'New tags/categories (comma-separated).', valueHelp: 'tag1,tag2');
    argParser.addOption('depends-on', help: 'New dependencies (comma-separated Task Titles).', valueHelp: 'title1,title2');
    argParser.addOption('reason', help: 'New reason/goal behind the task.', valueHelp: 'GOAL_OR_PLAN_TITLE');
    argParser.addOption('resolution', help: 'New resolution notes.', valueHelp: 'RESOLUTION_NOTES');
     // Special flag to clear optional fields
     argParser.addFlag('clear-description', help: 'Set description to empty.', negatable: false);
     argParser.addFlag('clear-effort', help: 'Set effort estimate to empty.', negatable: false);
     argParser.addFlag('clear-status', help: 'Set status to empty.', negatable: false);
     argParser.addFlag('clear-due-date', help: 'Set due date to empty.', negatable: false);
     argParser.addFlag('clear-tags', help: 'Set tags/categories to empty.', negatable: false);
     argParser.addFlag('clear-depends-on', help: 'Set dependencies to empty.', negatable: false);
     argParser.addFlag('clear-reason', help: 'Set reason/goal to empty.', negatable: false);
     argParser.addFlag('clear-resolution', help: 'Set resolution notes to empty.', negatable: false);
  }

  @override
  Future<void> run() async {
    String? id = argResults?['id'];

     // --- ID is always required ---
    if (interactive && (id == null || id.isEmpty)) {
       id = InputUtils.prompt('Enter the ID of the task to update:', isRequired: true);
    }
    if (id == null || id.isEmpty) {
       throw UsageException('Task ID (--id or -i) is required for update.', usage);
    }

     // --- Fetch Existing Task ---
    BacklogTask? existingTask;
    try {
      existingTask = await _excelService.getItemById<BacklogTask>(id, BacklogTask.fromRow);
    } catch (e) {
       print('❌ Error fetching task with ID "$id": $e');
       return; // Stop execution if fetch fails
    }

    if (existingTask == null) {
      print('❌ Task with ID "$id" not found.');
      return;
    }

    print('🔄 Updating Task: ${existingTask.taskTitle} (ID: $id)');

    // --- Gather Updated Values ---
    String? title = argResults?['title'];
    String? priorityStr = argResults?['priority'];
    String? description = argResults?['description'];
    String? effort = argResults?['effort'];
    String? statusStr = argResults?['status'];
    String? dueDate = argResults?['due-date'];
    String? tags = argResults?['tags'];
    String? dependencies = argResults?['depends-on'];
    String? reason = argResults?['reason'];
    String? resolution = argResults?['resolution'];

    // --- Interactive Mode: Prompt for each field ---
    if (interactive) {
      print('\nEnter new values or press Enter to keep current.');
      title = InputUtils.prompt('Task Title', isRequired: true, currentValue: existingTask.taskTitle);
      priorityStr = InputUtils.promptEnum<Priority>('Priority (${PriorityExtension.allowedValuesString})', Priority.values, isRequired: true, currentValue: existingTask.priority.name);
      description = InputUtils.prompt('Description', currentValue: existingTask.description);
      effort = InputUtils.prompt('Estimated Effort', currentValue: existingTask.estimatedEffort);
      statusStr = InputUtils.promptEnum<TaskStatus>('Status (${TaskStatusExtension.allowedValuesString})', TaskStatus.values, currentValue: existingTask.status?.name);
      dueDate = InputUtils.prompt('Due Date (YYYY-MM-DD)', validator: InputUtils.isValidDate, validationError: 'Invalid date format.', currentValue: existingTask.dueDate);
      tags = InputUtils.prompt('Tags/Categories', currentValue: existingTask.tagsCategories);
      dependencies = InputUtils.prompt('Dependencies (Task Titles)', currentValue: existingTask.dependencies);
      reason = InputUtils.prompt('Reason/Goal', currentValue: existingTask.reasoning);
      resolution = InputUtils.prompt('Resolution', currentValue: existingTask.resolution);
       print('--------------------------\n');
    }

    // --- Apply Non-Interactive Args & Validate ---
    // Use existing value if argument not provided in non-interactive mode
    title ??= existingTask.taskTitle;
    priorityStr ??= existingTask.priority.name;
    description = argResults?.wasParsed('clear-description') ?? false ? null : (description ?? existingTask.description);
    effort = argResults?.wasParsed('clear-effort') ?? false ? null : (effort ?? existingTask.estimatedEffort);
    statusStr = argResults?.wasParsed('clear-status') ?? false ? null : (statusStr ?? existingTask.status?.name);
    dueDate = argResults?.wasParsed('clear-due-date') ?? false ? null : (dueDate ?? existingTask.dueDate);
    tags = argResults?.wasParsed('clear-tags') ?? false ? null : (tags ?? existingTask.tagsCategories);
    dependencies = argResults?.wasParsed('clear-depends-on') ?? false ? null : (dependencies ?? existingTask.dependencies);
    reason = argResults?.wasParsed('clear-reason') ?? false ? null : (reason ?? existingTask.reasoning);
    resolution = argResults?.wasParsed('clear-resolution') ?? false ? null : (resolution ?? existingTask.resolution);


    // Re-validate potentially changed values
    if (title.isEmpty) {
        throw UsageException('Task title cannot be empty.', usage);
    }
    final priority = PriorityExtension.tryParse(priorityStr);
    if (priority == null) {
       throw UsageException('Invalid priority value: "$priorityStr". Allowed: ${PriorityExtension.allowedValuesString}', usage);
    }
    final status = TaskStatusExtension.tryParse(statusStr);
    if (statusStr != null && statusStr.isNotEmpty && status == null) {
       throw UsageException('Invalid status value: "$statusStr". Allowed: ${TaskStatusExtension.allowedValuesString}', usage);
    }
     if (dueDate != null && dueDate.isNotEmpty && !InputUtils.isValidDate(dueDate)) {
       throw UsageException('Invalid due date format: "$dueDate". Use YYYY-MM-DD.', usage);
     }


    // --- Create Updated Task Object ---
    // Important: Keep the original ID and createdAt timestamp!
    final updatedTask = BacklogTask(
      id: existingTask.id,
      createdAt: existingTask.createdAt, // Preserve creation date
      taskTitle: title,
      priority: priority,
      description: description,
      estimatedEffort: effort,
      status: status,
      dueDate: dueDate,
      tagsCategories: tags,
      dependencies: dependencies,
      reasoning: reason,
      resolution: resolution,
      // updatedAt will be set by service/model
    );

     // --- Save Update ---
    try {
      final success = await _excelService.updateItem<BacklogTask>(updatedTask);
      if (success) {
        print('✅ Task with ID "$id" updated successfully.');
      } else {
         // Error message already printed by service or earlier check
      }
    } catch (e) {
      print('❌ Error updating task with ID "$id" in Excel file "${_excelService.filePath}": $e');
    }
  }
}
