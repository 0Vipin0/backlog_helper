import 'package:args/command_runner.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/display_utils.dart';

class ListObstaclesCommand extends Command<void> {
  @override
  final String name = 'obstacles';
  @override
  final String description = 'Lists all obstacles.';
  @override
  String get invocation => '${runner?.executableName} list obstacles';

  final ExcelService _excelService;

  ListObstaclesCommand({required ExcelService excelService})
      : _excelService = excelService;
  // Add filtering/sorting later

  @override
  Future<void> run() async {
    print('\n--- Listing Obstacles ---');
    try {
      final obstacles =
          await _excelService.getAllItems<Obstacle>(Obstacle.fromRow);
      DisplayUtils.printTable<Obstacle>(obstacles, Obstacle.displayHeaders);
      print('-----------------------\n');
    } catch (e) {
      print(
          '❌ Error listing obstacles from Excel file "${_excelService.filePath}": $e');
    }
  }
}
