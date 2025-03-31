import 'dart:io';
import 'package:args/command_runner.dart';
import '../services/excel_service.dart'; // Import service
import 'add/add_command.dart';
import 'list/list_command.dart';
import 'update/update_command.dart';

class InteractiveCommand extends Command<void> {
  @override
  final String name = 'interactive';
  @override
  final String description = 'Enters interactive mode (REPL) to manage items.';
  @override
  String get invocation => '${runner?.executableName} interactive';

  final ExcelService _excelService; // Allow passing service

  InteractiveCommand({ExcelService? excelService})
      : _excelService = excelService ??
            ExcelService(); // Use default service if none provided

  @override
  Future<void> run() async {
    print(
        '\n Entering interactive mode. Type "help" for commands, "exit" to quit.');
    print(' Working with files: ${_excelService.filePath}');

    // Create a runner specifically for interactive mode commands
    final interactiveRunner = CommandRunner<void>(
        runner?.executableName ?? 'app', // Use parent runner's name or fallback
        ' Interactive Mode - ${runner?.description ?? 'Manage items'}')
      // Instantiate commands with interactive=true and pass the service
      ..addCommand(AddCommand(excelService: _excelService, interactive: true))
      ..addCommand(ListCommand(
          excelService:
              _excelService)) // List doesn't need interactive flag, but needs service
      ..addCommand(
          UpdateCommand(excelService: _excelService, interactive: true));

    String? line;
    while (true) {
      stdout.write('> ');
      line = stdin.readLineSync();

      if (line == null ||
          ['exit', 'quit'].contains(line.trim().toLowerCase())) {
        print('Exit interactive mode.');
        break;
      }

      if (line.trim().isEmpty) {
        continue;
      }

      // Simple split, may have issues with quoted arguments
      final args = line.trim().split(RegExp(r'\s+'));

      try {
        await interactiveRunner.run(args);
      } on UsageException catch (e) {
        // Don't exit in interactive mode, just show error
        print('❌ Error: ${e.message}');
        print(e.usage); // Print usage specific to the command
      } catch (e, s) {
        print(' Fatal Error: $e');
        if (Platform.environment['DEBUG'] == 'true') {
          print(s); // Print stack trace if in debug mode
        }
      }
      print(''); // Add spacing
    }
  }
}
