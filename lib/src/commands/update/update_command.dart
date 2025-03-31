import 'package:args/command_runner.dart';
import '../../services/excel_service.dart';
import 'update_task_command.dart';
import 'update_goal_command.dart';
import 'update_plan_command.dart';
import 'update_obstacle_command.dart';

class UpdateCommand extends Command<void> {
  @override
  final String name = 'update';
  @override
  final String description = 'Update an existing item (task, goal, plan, obstacle) in the Excel file.';

  final ExcelService _excelService;
  final bool interactive;

  UpdateCommand({ExcelService? excelService, this.interactive = false})
      : _excelService = excelService ?? ExcelService() {
    addSubcommand(UpdateTaskCommand(excelService: _excelService, interactive: interactive));
    addSubcommand(UpdateGoalCommand(excelService: _excelService, interactive: interactive));
    addSubcommand(UpdatePlanCommand(excelService: _excelService, interactive: interactive));
    addSubcommand(UpdateObstacleCommand(excelService: _excelService, interactive: interactive));
  }

   @override
   void run() {
    print(usage);
  }
}
