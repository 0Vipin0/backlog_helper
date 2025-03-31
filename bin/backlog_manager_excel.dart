import 'dart:io';
import 'package:args/command_runner.dart';

import 'package:backlog_helper/src/commands/add/add_command.dart';
import 'package:backlog_helper/src/commands/list/list_command.dart';
import 'package:backlog_helper/src/commands/update/update_command.dart';
import 'package:backlog_helper/src/commands/interactive_command.dart';
import 'package:backlog_helper/src/services/excel_service.dart';
import 'package:backlog_helper/src/constants/excel_constants.dart';


Future<void> main(List<String> arguments) async {
   final runner = CommandRunner<void>(
    'backlog_helper', // Your executable name
    'CLI tool to manage project items using an Excel file.',
  )
  // Add global option for file path
  ..argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Path to the Excel data file.',
      valueHelp: 'path/to/your/data.xlsx',
      defaultsTo: ExcelConstants.defaultFilename,
    );


  // --- Initialize Service and Commands ---
  // We need to parse global options *before* creating commands
  // if commands depend on them (like the file path for ExcelService).
  ExcelService excelService;
  try {
     // Parse arguments *just* to get the global options
     final globalResults = runner.argParser.parse(arguments);
     final filePath = globalResults['file'] as String?; // Use nullable string
     excelService = ExcelService(filePath: filePath); // Pass potential custom path
  } catch(e) {
      // Handle parsing error for global options if needed, maybe default?
      print("Warning: Could not parse global options, using default file path. Error: $e");
      excelService = ExcelService(); // Use default path on error
  }


  // Add commands, passing the initialized service
  runner
    ..addCommand(AddCommand(excelService: excelService))
    ..addCommand(ListCommand(excelService: excelService))
    ..addCommand(UpdateCommand(excelService: excelService))
    ..addCommand(InteractiveCommand(excelService: excelService));

  try {
     // Check if only the global '--file' option was passed without a command
    final parsedArgs = runner.parse(arguments); // Parse again to get command info
     final commandName = parsedArgs.command?.name;

    // If no command is specified (or only global options like --help, --file),
    // default to interactive mode or show help.
     if (arguments.isEmpty || commandName == null && arguments.isNotEmpty && !arguments.contains('--help') && !arguments.contains('-h')) {
        // If arguments are present but no command (likely just --file), explain.
        if (arguments.isNotEmpty) {
             print('No command specified. Use --help to see commands or run without command for interactive mode.');
             print('Using data file: ${excelService.filePath}');
             exit(0);
        }
        // Default to interactive mode if no args at all
        print('No command specified. Entering interactive mode...');
        print('Use `${runner.executableName} --help` for non-interactive commands.');
        print('---');
        // Run interactive command directly, passing the service
        await InteractiveCommand(excelService: excelService).run();
     } else {
      // Run the command specified in arguments (non-interactive or help)
       await runner.run(arguments);
    }
  } on UsageException catch (e) {
    print('❌ Error: ${e.message}');
    print('');
    print(e.usage);
    exit(64); // Command line usage error
  } catch (e, s) {
    print(' Fata Error: $e');
     if (Platform.environment['DEBUG'] == 'true') {
        print(s); // Print stack trace if in debug mode
    }
    exit(1); // General error
  }
  // No explicit close needed for Excel file unless using locks,
  // but service cache clearing might be useful in some scenarios.
   excelService.clearCache();
}
