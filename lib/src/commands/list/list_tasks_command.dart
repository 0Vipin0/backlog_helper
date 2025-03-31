import 'package:args/command_runner.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/display_utils.dart'; // For table formatting

class ListTasksCommand extends Command<void> {
  @override
  final String name = 'tasks';
  @override
  final String description = 'Lists all backlog tasks.';
   @override
  String get invocation => '${runner?.executableName} list tasks';

  final ExcelService _excelService;

  ListTasksCommand({required ExcelService excelService})
      : _excelService = excelService {
     // Add filtering/sorting options here later if needed
     // argParser.addOption('status', help: 'Filter by status');
     // argParser.addOption('sort-by', help: 'Sort by column', allowed: BacklogTask.displayHeaders);
  }

  @override
  Future<void> run() async {
    print('\n--- Listing Backlog Tasks ---');
    try {
      final tasks = await _excelService.getAllItems<BacklogTask>(BacklogTask.fromRow);
      DisplayUtils.printTable<BacklogTask>(tasks, BacklogTask.displayHeaders);
      print('---------------------------\n');
    } catch (e) {
      print('❌ Error listing tasks from Excel file "${_excelService.filePath}": $e');
    }
  }
}
