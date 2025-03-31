import 'package:args/command_runner.dart';
import '../../services/excel_service.dart'; // Import service
import 'add_task_command.dart';
import 'add_goal_command.dart';
import 'add_plan_command.dart';
import 'add_obstacle_command.dart';

class AddCommand extends Command<void> {
  @override
  final String name = 'add';
  @override
  final String description =
      'Add a new item (task, goal, plan, obstacle) to the Excel file.';

  // Allow passing ExcelService, useful for testing or custom file paths
  final ExcelService _excelService;
  final bool interactive; // Passed down to subcommands

  AddCommand({ExcelService? excelService, this.interactive = false})
      : _excelService = excelService ?? ExcelService() {
    // Use default if not provided
    // Pass service and interactive flag to subcommands
    addSubcommand(
        AddTaskCommand(excelService: _excelService, interactive: interactive));
    addSubcommand(
        AddGoalCommand(excelService: _excelService, interactive: interactive));
    addSubcommand(
        AddPlanCommand(excelService: _excelService, interactive: interactive));
    addSubcommand(AddObstacleCommand(
        excelService: _excelService, interactive: interactive));
  }

  // Override run to show help if no subcommand is given
  @override
  void run() {
    print(usage);
  }
}
