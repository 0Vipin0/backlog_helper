import 'dart:io';
import 'package:backlog_helper/src/constants/excel_constants.dart';
import 'package:backlog_helper/src/models/enums.dart';
import 'package:backlog_helper/src/models/models.dart';
import 'package:backlog_helper/src/services/excel_service.dart';
import 'package:test/test.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

// Helpers...
String getTempDir() =>
    Directory.systemTemp.createTempSync('excel_service_test_').path;

Future<Excel> decodeTestFile(String path) async {
  final file = File(path);
  if (!await file.exists()) throw Exception("Test file $path not found for decoding");
  final bytes = await file.readAsBytes();
  return Excel.decodeBytes(bytes);
}

Future<int> getRowCount(String path, String sheetName) async {
  try {
    final excel = await decodeTestFile(path);
    if (!excel.sheets.containsKey(sheetName)) return 0;
    final sheet = excel.sheets[sheetName]!;
    return sheet.maxRows <= 1 ? 0 : sheet.maxRows - 1;
  } catch (_) {
    return 0;
  }
}

void main() {
  late Directory tempDir;
  late String testFilePath;
  // Note: We will create new service instances within tests where necessary
  // to ensure reading from disk after writes.

  setUp(() {
    tempDir = Directory(getTempDir());
    testFilePath = p.join(tempDir.path, 'test_data.xlsx');
    // We might not even need a top-level excelService instance anymore
    // excelService = ExcelService(filePath: testFilePath);
  });

  tearDown(() async {
    // excelService.clearCache(); // Clear if instance exists
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Initialization and File Handling', () {
    test(
        'creates new file with sheets and headers if file does not exist on first load',
        () async {
      final service =
          ExcelService(filePath: testFilePath); // Instance for this test
      expect(await File(testFilePath).exists(), isFalse);
      // Trigger load using getAllItems on the new service
      await service.getAllItems<BacklogTask>(BacklogTask.fromRow);
      expect(await File(testFilePath).exists(), isTrue);

      // Verify file content
      final excel = await decodeTestFile(testFilePath);
      expect(excel.sheets.containsKey(ExcelConstants.sheetTasks), isTrue);
      final taskSheet = excel.sheets[ExcelConstants.sheetTasks]!;
      expect(taskSheet.maxRows, greaterThanOrEqualTo(1));
      final headerRowData = taskSheet.rows.first;
      final headerValues = headerRowData
          .map((cellData) => cellData?.value?.toString() ?? '')
          .toList();
      expect(headerValues, equals(ExcelConstants.headersTasks));
    });

    test('loads existing file correctly (and uses cache)', () async {
      final service1 = ExcelService(filePath: testFilePath);
      final initialTask = BacklogTask(
          id: 't-init', taskTitle: 'Initial', priority: Priority.low);
      final firstId =
          await service1.addItem(initialTask); // Saves & clears cache

      // Use a NEW service instance for initial read from file
      final service2 = ExcelService(filePath: testFilePath);
      final items1 =
          await service2.getAllItems<BacklogTask>(BacklogTask.fromRow);
      expect(items1, isNotEmpty);
      expect(items1.first.id, equals(firstId));

      // Manually modify file...
      final excelDirect = await decodeTestFile(testFilePath);
      final sheet = excelDirect[ExcelConstants.sheetTasks];
      sheet.appendRow([
        TextCellValue('manual-id'),
        TextCellValue('Manual Add'),
        null, // Description (optional, can be null Data)
        TextCellValue(Priority
            .medium.name) // Priority (required - provide valid enum name)
        // Add nulls or valid CellValues for other columns if needed by fromRow
      ]);
      final encodedBytes = excelDirect.encode();
      if (encodedBytes != null) {
        await File(testFilePath).writeAsBytes(encodedBytes);
      } else {
        fail('Encoding failed');
      }

      // Read again using service2 - SHOULD hit cache (no clearCache called on service2)
      final items2 =
          await service2.getAllItems<BacklogTask>(BacklogTask.fromRow);
      expect(items2.length, equals(items1.length),
          reason: "Should read from cache");

      // Read after cache clear on service2
      service2.clearCache();
      final items3 =
          await service2.getAllItems<BacklogTask>(BacklogTask.fromRow);
      expect(items3.length, greaterThan(items1.length),
          reason: "Should read modified file");
      expect(items3.any((t) => t.id == 'manual-id'), isTrue);
    });
  });

  group('addItem<T>', () {
    test('adds a new BacklogTask and saves', () async {
      final service =
          ExcelService(filePath: testFilePath); // Instance for this test
      final task = BacklogTask(
          id: 'will-be-replaced',
          taskTitle: 'Test Add Task',
          priority: Priority.high);
      expect(await getRowCount(testFilePath, ExcelConstants.sheetTasks), 0);

      final generatedId =
          await service.addItem(task); // Saves & clears cache on 'service'

      expect(Uuid.isValidUUID(fromString: generatedId), isTrue);

      // Verify row count and content using a NEW instance to read from file
      expect(await getRowCount(testFilePath, ExcelConstants.sheetTasks), 1);
      final readerService = ExcelService(filePath: testFilePath);
      final items =
          await readerService.getAllItems<BacklogTask>(BacklogTask.fromRow);
      expect(items.length, 1);
      expect(items.first.id, equals(generatedId));
      expect(items.first.taskTitle, equals('Test Add Task'));
    });
    test('adds a new FutureGoal and saves', () async {
      final service =
          ExcelService(filePath: testFilePath); // Instance for this test
      final goal = FutureGoal(
          id: 'g-replace',
          goalDescription: 'Test Add Goal',
          targetCompletionDate: '2025-01-01',
          priority: Priority.medium);
      expect(await getRowCount(testFilePath, ExcelConstants.sheetGoals), 0);

      final generatedId = await service.addItem(goal); // Saves & clears cache

      expect(await getRowCount(testFilePath, ExcelConstants.sheetGoals), 1);
      // Verify using a new instance
      final readerService = ExcelService(filePath: testFilePath);
      final items =
          await readerService.getAllItems<FutureGoal>(FutureGoal.fromRow);
      expect(items.length, 1);
      expect(items.first.id, equals(generatedId));
    });
  });

  // --- RESTRUCTURED getAllItems Group ---
  group('getAllItems<T>', () {
    // No setUp needed here anymore

    test('returns empty list when file is new/empty', () async {
      final readerService = ExcelService(filePath: testFilePath);
      // Calling getAllItems will create the file with headers
      final items =
          await readerService.getAllItems<BacklogTask>(BacklogTask.fromRow);
      expect(items, isEmpty);
      // Verify sheet exists with only header
      final excel = await decodeTestFile(testFilePath);
      expect(excel.sheets.containsKey(ExcelConstants.sheetTasks), isTrue);
      expect(excel.sheets[ExcelConstants.sheetTasks]!.maxRows, 1);
    });

    test('retrieves a single added BacklogTask correctly', () async {
      final service =
          ExcelService(filePath: testFilePath); // Service for writing
      final task1 = BacklogTask(
          id: '', taskTitle: 'Single Task', priority: Priority.high);
      final task1Id = await service.addItem(task1); // Add and save

      // Use a new service instance for reading
      final readerService = ExcelService(filePath: testFilePath);
      final items =
          await readerService.getAllItems<BacklogTask>(BacklogTask.fromRow);

      expect(items.length, 1, reason: "Should find 1 task");
      expect(items.first.id, equals(task1Id));
      expect(items.first.taskTitle, equals('Single Task'));
    });

    test('retrieves multiple added BacklogTasks correctly', () async {
      final service =
          ExcelService(filePath: testFilePath); // Service for writing
      final task1 = BacklogTask(
          id: '', taskTitle: 'Multi Task 1', priority: Priority.high);
      final task2 = BacklogTask(
          id: '',
          taskTitle: 'Multi Task 2',
          priority: Priority.low,
          description: "Desc 2");
      await service.addItem(task1);
      await service.addItem(task2); // Add and save multiple

      // Use a new service instance for reading
      final readerService = ExcelService(filePath: testFilePath);
      final items =
          await readerService.getAllItems<BacklogTask>(BacklogTask.fromRow);

      expect(items.length, 2, reason: "Should find 2 tasks");
      expect(items.any((t) => t.taskTitle == 'Multi Task 1'), isTrue);
      expect(items.any((t) => t.taskTitle == 'Multi Task 2'), isTrue);
      expect(items.firstWhere((t) => t.taskTitle == 'Multi Task 2').description,
          "Desc 2");
    });

    test('retrieves items from correct sheet when multiple types exist',
        () async {
      final service =
          ExcelService(filePath: testFilePath); // Service for writing
      final task1 = BacklogTask(
          id: '', taskTitle: 'Task For Mix', priority: Priority.high);
      final goal1 = FutureGoal(
          id: '',
          goalDescription: 'Goal For Mix',
          targetCompletionDate: '2024',
          priority: Priority.medium);
      await service.addItem(task1);
      await service.addItem(goal1); // Add different types

      // Use a new service instance for reading
      final readerService = ExcelService(filePath: testFilePath);

      // Read Tasks
      final taskItems =
          await readerService.getAllItems<BacklogTask>(BacklogTask.fromRow);
      expect(taskItems.length, 1, reason: "Should find 1 task");
      expect(taskItems.first.taskTitle, equals('Task For Mix'));

      // Read Goals
      final goalItems =
          await readerService.getAllItems<FutureGoal>(FutureGoal.fromRow);
      expect(goalItems.length, 1, reason: "Should find 1 goal");
      expect(goalItems.first.goalDescription, equals('Goal For Mix'));
    });

    // Error handling tests can remain similar, just ensure setup is done within the test
    test('skips row if ID is missing/empty', () async {
      final service = ExcelService(filePath: testFilePath);
      // Add a valid item first
      await service.addItem(BacklogTask(
          id: '',
          taskTitle: 'Valid Task Before Empty',
          priority: Priority.medium));

      // Manually add a row with an empty ID
      // We need to load the excel object *after* the addItem call to modify it
      service.clearCache(); // Make sure we load fresh
      final excel = await service
          .loadExcel(); // Use internal method carefully for test setup
      final sheet = excel[ExcelConstants.sheetTasks];
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue('Task With Empty ID'),
        TextCellValue('high')
      ]);
      final encodedBytes = excel.encode();
      if (encodedBytes == null) fail("Encoding failed");
      await File(testFilePath).writeAsBytes(encodedBytes);
      // No need to clear cache on 'service', use a new reader

      // Use a new service instance to read the modified file
      final readerService = ExcelService(filePath: testFilePath);
      final items =
          await readerService.getAllItems<BacklogTask>(BacklogTask.fromRow);

      // Should get only the 1 original valid task
      expect(items.length, 1);
      expect(items.first.taskTitle, 'Valid Task Before Empty');
      expect(items.any((t) => t.taskTitle == 'Task With Empty ID'), isFalse);
    });

    test('handles parsing errors gracefully (skips row)', () async {
      final service = ExcelService(filePath: testFilePath);
      // Add a valid item first
      final validTask = BacklogTask(
          id: '',
          taskTitle: 'Valid Task Before Bad',
          priority: Priority.medium);
      await service.addItem(validTask);

      // Manually add a row with invalid data
      service.clearCache();
      final excel = await service.loadExcel(); // Use internal method carefully
      final sheet = excel[ExcelConstants.sheetTasks];
      final taskId = const Uuid().v4();
      sheet.appendRow([
        TextCellValue(taskId),
        TextCellValue('Task Invalid Prio'),
        TextCellValue('INVALID_PRIORITY_VALUE')
      ]);
      final encodedBytes = excel.encode();
      if (encodedBytes == null) fail("Encoding failed");
      await File(testFilePath).writeAsBytes(encodedBytes);

      // Use a new service instance to read the modified file
      final readerService = ExcelService(filePath: testFilePath);
      final items =
          await readerService.getAllItems<BacklogTask>(BacklogTask.fromRow);

      // Should get only the 1 original valid task
      expect(items.length, 1);
      expect(items.first.taskTitle, 'Valid Task Before Bad');
      expect(items.any((t) => t.id == taskId), isFalse);
    });
  }); // End group 'getAllItems<T>'

  // --- getItemById Group ---
  // Setup needs to be done within tests or using a clear pre/post state
  group('getItemById<T>', () {
    test('retrieves correct BacklogTask by ID', () async {
      final service = ExcelService(filePath: testFilePath);
      final t1 = BacklogTask(
          id: '', taskTitle: 'Task Find Me', priority: Priority.high);
      final task1Id = await service.addItem(t1); // Add item

      // Use a new reader instance
      final readerService = ExcelService(filePath: testFilePath);
      final item = await readerService.getItemById<BacklogTask>(
          task1Id, BacklogTask.fromRow);
      expect(item, isNotNull);
      expect(item!.id, equals(task1Id));
      expect(item.taskTitle, equals('Task Find Me'));
    });

    test('retrieves correct FutureGoal by ID', () async {
      final service = ExcelService(filePath: testFilePath);
      final g1 = FutureGoal(
          id: '',
          goalDescription: 'Goal Find Me',
          targetCompletionDate: '2024',
          priority: Priority.medium);
      final goal1Id = await service.addItem(g1); // Add item

      // Use a new reader instance
      final readerService = ExcelService(filePath: testFilePath);
      final item = await readerService.getItemById<FutureGoal>(
          goal1Id, FutureGoal.fromRow);
      expect(item, isNotNull);
      expect(item!.id, equals(goal1Id));
      expect(item.goalDescription, equals('Goal Find Me'));
    });

    test('returns null if ID is not found', () async {
      final service = ExcelService(filePath: testFilePath);
      // Add some other item so file exists
      await service.addItem(
          BacklogTask(id: '', taskTitle: 'Other', priority: Priority.low));

      // Use a new reader instance
      final readerService = ExcelService(filePath: testFilePath);
      final item = await readerService.getItemById<BacklogTask>(
          'non-existent-id', BacklogTask.fromRow);
      expect(item, isNull);
    });

    test('returns null if sheet does not exist for the type initially',
        () async {
      final readerService = ExcelService(filePath: testFilePath);
      // Ensure file exists by adding something else
      await readerService.addItem(
          BacklogTask(id: '', taskTitle: 'Filler', priority: Priority.low));
      readerService.clearCache(); // Clear cache after write

      // Now try to get item from a sheet that wasn't explicitly added
      final item = await readerService.getItemById<PlanningItem>(
          'some-id', PlanningItem.fromRow);
      expect(item, isNull);

      // Verify sheet was created by load
      final excel = await decodeTestFile(testFilePath);
      expect(excel.sheets.containsKey(ExcelConstants.sheetPlans), isTrue);
    });

    test('handles parsing error for the specific row gracefully', () async {
      final service = ExcelService(filePath: testFilePath);
      final t1 = BacklogTask(
          id: '', taskTitle: 'Task To Corrupt', priority: Priority.high);
      final task1Id = await service.addItem(t1); // Add item & save

      // --- FIX: Reload using decodeTestFile for modification ---
      final excel = await decodeTestFile(testFilePath);
      // --- END FIX ---

      final sheet = excel[ExcelConstants.sheetTasks];
      int? rowIndex;
      for (int i = 1; i < sheet.maxRows; i++) {
        // Start from 1 (skip header)
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
        // --- FIX: Compare cell's value?.toString() ---
        if (cell.value?.toString() == task1Id) {
          rowIndex = i;
          break;
        }
        // --- END FIX ---
      }

      // This assertion should now pass if addItem saved correctly
      expect(rowIndex, isNotNull,
          reason: "Row with ID $task1Id not found after addItem/reload");
      if (rowIndex == null) return; // Avoid proceeding if setup failed

      // Corrupt the priority column (index 3) in the found row
      sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
          TextCellValue('BAD_PRIO') // Intentionally invalid priority string
          );

      // Save the corrupted file
      final encodedBytes = excel.encode();
      if (encodedBytes == null) fail("Encoding failed");
      await File(testFilePath).writeAsBytes(encodedBytes);

      // Use a new reader instance to attempt reading the corrupted file
      final readerService = ExcelService(filePath: testFilePath);
      // Expect getItemById to catch the parsing error and return null
      final item = await readerService.getItemById<BacklogTask>(
          task1Id, BacklogTask.fromRow);
      expect(item, isNull,
          reason: "getItemById should return null when parsing fails");
    });
  }); // End group 'getItemById<T>'

  // --- updateItem Group ---
  group('updateItem<T>', () {
    test('updates existing BacklogTask data successfully', () async {
      final service = ExcelService(filePath: testFilePath);
      // 1. Add initial item
      final t1 = BacklogTask(
          id: '',
          taskTitle: 'Task Before Update',
          priority: Priority.high,
          description: "Old Desc");
      final task1Id = await service.addItem(t1);

      // 2. Get the item using a new instance to ensure we have the saved state
      final readerService = ExcelService(filePath: testFilePath);
      final taskToUpdate = await readerService.getItemById<BacklogTask>(
          task1Id, BacklogTask.fromRow);
      expect(taskToUpdate, isNotNull,
          reason:
              "Failed to read item back after initial add"); // Check setup worked
      if (taskToUpdate == null) return; // Exit if setup failed

      final task1CreatedAt = taskToUpdate.createdAt;
      final originalUpdatedAt = taskToUpdate.updatedAt;

      // 3. Modify the fetched item
      taskToUpdate.taskTitle = 'Task After Update';
      taskToUpdate.priority = Priority.low;
      taskToUpdate.description = 'New Desc';

      // 4. Perform update using a new service instance
      final updateService = ExcelService(filePath: testFilePath);
      final success = await updateService.updateItem(taskToUpdate);
      expect(success, isTrue, reason: "updateItem returned false");

      // --- ADD DELAY before verification ---
      await Future.delayed(
          const Duration(milliseconds: 200)); // Adjust if needed
      // --- END DELAY ---

      // 5. Verify by reloading using another new service instance
      final verifierService = ExcelService(filePath: testFilePath);
      final updatedItem = await verifierService.getItemById<BacklogTask>(
          task1Id, BacklogTask.fromRow);

      // This is the failing assertion
      expect(updatedItem, isNotNull,
          reason: "getItemById returned null after update");
      if (updatedItem == null) return; // Exit test early if failed

      // Continue verification if item was found
      expect(updatedItem.id, equals(task1Id));
      expect(updatedItem.taskTitle, equals('Task After Update'));
      expect(updatedItem.priority, equals(Priority.low));
      expect(updatedItem.description, equals('New Desc'));
      expect(updatedItem.createdAt.isAtSameMomentAs(task1CreatedAt), isTrue);
      expect(updatedItem.updatedAt.isAfter(originalUpdatedAt), isTrue);
      expect(updatedItem.updatedAt.isAtSameMomentAs(taskToUpdate.updatedAt),
          isTrue);

      expect(await getRowCount(testFilePath, ExcelConstants.sheetTasks), 1);
    });

    test('returns false if item ID is not found for update', () async {
      final service = ExcelService(filePath: testFilePath);
      await service.addItem(
          BacklogTask(id: '', taskTitle: 'Other', priority: Priority.low));

      final nonExistentTask = BacklogTask(
          id: 'fake-id', taskTitle: 'Wont Find', priority: Priority.low);
      final updateService = ExcelService(filePath: testFilePath);
      final success = await updateService.updateItem(nonExistentTask);
      expect(success, isFalse);
    });

    test('returns false if sheet does not exist for update', () async {
      final service = ExcelService(filePath: testFilePath);
      await service.addItem(
          BacklogTask(id: '', taskTitle: 'Other', priority: Priority.low));

      final nonExistentPlan = PlanningItem(
          id: 'plan-id',
          planItemDescription: 'No Sheet',
          typeOfPlan: PlanType.strategic,
          status: 'Ok');
      final updateService = ExcelService(filePath: testFilePath);
      final success = await updateService.updateItem(nonExistentPlan);
      expect(success, isFalse);
    });
  }); // End group 'updateItem<T>'
} // End main
