import 'package:args/command_runner.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/display_utils.dart';

class ListGoalsCommand extends Command<void> {
  @override
  final String name = 'goals';
  @override
  final String description = 'Lists all future goals.';
  @override
  String get invocation => '${runner?.executableName} list goals';

  final ExcelService _excelService;

  ListGoalsCommand({required ExcelService excelService})
      : _excelService = excelService;
  // Add filtering/sorting later

  @override
  Future<void> run() async {
    print('\n--- Listing Future Goals ---');
    try {
      final goals =
          await _excelService.getAllItems<FutureGoal>(FutureGoal.fromRow);
      DisplayUtils.printTable<FutureGoal>(goals, FutureGoal.displayHeaders);
      print('--------------------------\n');
    } catch (e) {
      print(
          '❌ Error listing goals from Excel file "${_excelService.filePath}": $e');
    }
  }
}
