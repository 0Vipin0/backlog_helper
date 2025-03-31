import 'package:args/command_runner.dart';
import 'package:uuid/uuid.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/input_utils.dart';

class AddTaskCommand extends Command<void> {
  @override
  final String name = 'task';
  @override
  final String description = 'Adds a new backlog task.';
  @override
  String get invocation => '${runner?.executableName} add task [arguments]';


  final ExcelService _excelService;
  final bool interactive;

  AddTaskCommand({required ExcelService excelService, this.interactive = false})
      : _excelService = excelService {

    // --- Define Arguments ---
    // Mandatory
    argParser.addOption('title', abbr: 't', help: '(Required) What is the task?', valueHelp: 'TASK_TITLE');
    argParser.addOption('priority', abbr: 'p', help: '(Required) How important is this task? \nAllowed: [${PriorityExtension.allowedValuesString}]', valueHelp: 'PRIORITY', allowed: PriorityExtension.names, allowedHelp: Map.fromEntries(Priority.values.map((e) => MapEntry(e.name, e.description))));

    // Optional
    argParser.addOption('description', abbr: 'd', help: 'Please provide a detailed description of the task.', valueHelp: 'DESCRIPTION');
    argParser.addOption('effort', abbr: 'e', help: "What's your best estimate of the effort needed? (e.g., hours, days)", valueHelp: 'EFFORT_ESTIMATE');
    argParser.addOption('status', abbr: 's', help: 'What is the current status of this task? \nAllowed: [${TaskStatusExtension.allowedValuesString}]', valueHelp: 'STATUS', allowed: TaskStatusExtension.names, allowedHelp: Map.fromEntries(TaskStatus.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('due-date', help: 'Is there a specific date this task should be done by? (YYYY-MM-DD)', valueHelp: 'YYYY-MM-DD');
    argParser.addOption('tags', help: 'Are there any tags or categories for this task? (e.g., UI, Bug, Feature)', valueHelp: 'tag1,tag2');
    argParser.addOption('depends-on', help: 'Are there any tasks this task depends on? (Comma-separated Task Titles)', valueHelp: 'title1,title2');
    argParser.addOption('reason', help: 'What is the reason or goal behind this task? (Related Goal/Plan Title)', valueHelp: 'GOAL_OR_PLAN_TITLE');
    argParser.addOption('resolution', help: 'What was the resolution for this task? (For completed/blocked tasks)', valueHelp: 'RESOLUTION_NOTES');
  }

  @override
  Future<void> run() async {
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

    // --- Interactive Mode ---
    if (interactive) {
      print('\n--- Adding New Backlog Task ---');
      title = InputUtils.prompt('What is the task?', isRequired: true, currentValue: title);
      priorityStr = InputUtils.promptEnum<Priority>('How important is this task? (${PriorityExtension.allowedValuesString})', Priority.values, isRequired: true, currentValue: priorityStr);
      description = InputUtils.prompt('Please provide a detailed description (Optional):', currentValue: description);
      effort = InputUtils.prompt("What's your estimate of the effort needed? (Optional):", currentValue: effort);
      statusStr = InputUtils.promptEnum<TaskStatus>('What is the current status? (${TaskStatusExtension.allowedValuesString}) (Optional):', TaskStatus.values, currentValue: statusStr);
      dueDate = InputUtils.prompt('Due date? (YYYY-MM-DD) (Optional):', validator: InputUtils.isValidDate, validationError: 'Invalid date format.', currentValue: dueDate);
      tags = InputUtils.prompt('Tags or categories? (comma-separated) (Optional):', currentValue: tags);
      dependencies = InputUtils.prompt('Depends on which tasks? (comma-separated titles) (Optional):', currentValue: dependencies);
      reason = InputUtils.prompt('Reason/Goal behind this task? (Optional):', currentValue: reason);
      resolution = InputUtils.prompt('Resolution notes? (Optional):', currentValue: resolution);
       print('--------------------------\n');
    }

    // --- Validation (after interactive potentially filled values) ---
     if (title == null || title.isEmpty) {
       throw UsageException('Task title (--title or -t) is required.', usage);
     }
     if (priorityStr == null || priorityStr.isEmpty) {
        throw UsageException('Priority (--priority or -p) is required.', usage);
    }
    final priority = PriorityExtension.tryParse(priorityStr);
    if (priority == null) { // Should be caught by argParser allowed, but check anyway
       throw UsageException('Invalid priority value: "$priorityStr". Allowed: ${PriorityExtension.allowedValuesString}', usage);
    }

    final status = TaskStatusExtension.tryParse(statusStr);
    if (statusStr != null && statusStr.isNotEmpty && status == null) {
       throw UsageException('Invalid status value: "$statusStr". Allowed: ${TaskStatusExtension.allowedValuesString}', usage);
    }
     if (dueDate != null && dueDate.isNotEmpty && !InputUtils.isValidDate(dueDate)) {
       throw UsageException('Invalid due date format: "$dueDate". Use YYYY-MM-DD.', usage);
     }

    // --- Create and Save ---
    final newTask = BacklogTask(
      id: const Uuid().v4(), // Generate ID here or let service do it
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
      // createdAt/updatedAt will be set by model/service
    );

    try {
      final addedId = await _excelService.addItem<BacklogTask>(newTask);
      print('✅ Backlog task added successfully with ID: $addedId');
    } catch (e) {
      print('❌ Error adding task to Excel file "${_excelService.filePath}": $e');
      // Consider more specific error handling (file access, parsing errors)
    }
  }
}
