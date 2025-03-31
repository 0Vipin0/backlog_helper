import 'package:args/command_runner.dart';
import '../../services/excel_service.dart';
import 'list_tasks_command.dart';
import 'list_goals_command.dart';
import 'list_plans_command.dart';
import 'list_obstacles_command.dart';

class ListCommand extends Command<void> {
  @override
  final String name = 'list';
  @override
  final String description = 'List existing items (tasks, goals, plans, obstacles) from the Excel file.';

  final ExcelService _excelService;

  ListCommand({ExcelService? excelService})
      : _excelService = excelService ?? ExcelService() {
    addSubcommand(ListTasksCommand(excelService: _excelService));
    addSubcommand(ListGoalsCommand(excelService: _excelService));
    addSubcommand(ListPlansCommand(excelService: _excelService));
    addSubcommand(ListObstaclesCommand(excelService: _excelService));
  }

  @override
   void run() {
    print(usage);
  }
}
