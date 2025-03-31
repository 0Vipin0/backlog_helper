import 'package:args/command_runner.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/display_utils.dart';

class ListPlansCommand extends Command<void> {
  @override
  final String name = 'plans';
  @override
  final String description = 'Lists all planning items.';
  @override
  String get invocation => '${runner?.executableName} list plans';

  final ExcelService _excelService;

  ListPlansCommand({required ExcelService excelService})
      : _excelService = excelService;
  // Add filtering/sorting later

  @override
  Future<void> run() async {
    print('\n--- Listing Planning Items ---');
    try {
      final plans =
          await _excelService.getAllItems<PlanningItem>(PlanningItem.fromRow);
      DisplayUtils.printTable<PlanningItem>(plans, PlanningItem.displayHeaders);
      print('----------------------------\n');
    } catch (e) {
      print(
          '❌ Error listing planning items from Excel file "${_excelService.filePath}": $e');
    }
  }
}
