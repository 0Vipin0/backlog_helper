import 'dart:io';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../constants/excel_constants.dart';
import '../models/models.dart';

class ExcelService {
  final String filePath;
  final Uuid _uuid = const Uuid();
  Excel? _excel; // Cache the loaded excel object

  ExcelService({String? filePath})
      : filePath = filePath ?? ExcelConstants.defaultFilename;

  // --- Initialization and File Handling ---

  Future<Excel> _loadExcel() async {
    if (_excel != null) return _excel!; // Return cached version if available

    final file = File(filePath);
    if (await file.exists()) {
      try {
        final bytes = await file.readAsBytes();
        _excel = Excel.decodeBytes(bytes);
        // Basic validation: check if required sheets exist? (Optional)
      } catch (e) {
        throw Exception('Error reading or decoding Excel file "$filePath": $e');
      }
    } else {
      _excel = Excel.createExcel();
      // Optionally create default sheets immediately
       _ensureSheetExists(_excel!, ExcelConstants.sheetTasks);
       _ensureSheetExists(_excel!, ExcelConstants.sheetGoals);
       _ensureSheetExists(_excel!, ExcelConstants.sheetPlans);
       _ensureSheetExists(_excel!, ExcelConstants.sheetObstacles);
       await _saveExcel(); // Save the newly created file with sheets/headers
       print("✨ Created new data file: $filePath");
    }
    return _excel!;
  }

  Sheet _ensureSheetExists(Excel excel, String sheetName) {
    if (!excel.sheets.containsKey(sheetName)) {
      excel.sheets[sheetName] = excel[sheetName]; // Create if not exists
      // Add headers to the new sheet
      final headers = ExcelConstants.getHeadersForSheet(sheetName);
      excel.sheets[sheetName]!.appendRow(headers.map((h) => TextCellValue(h)).toList());
      print("   📄 Added sheet: $sheetName with headers.");
    }
    // Ensure headers exist even if sheet existed but was empty/corrupted
    else if (excel.sheets[sheetName]!.maxRows < 1) {
         final headers = ExcelConstants.getHeadersForSheet(sheetName);
         excel.sheets[sheetName]!.appendRow(headers.map((h) => TextCellValue(h)).toList());
         print("   🔧 Added missing headers to sheet: $sheetName.");
    }
     return excel.sheets[sheetName]!;
  }

  Future<void> _saveExcel() async {
    if (_excel == null) return; // Nothing to save

    try {
      final fileBytes = _excel!.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        // Create directory if it doesn't exist
        if (!await file.parent.exists()) {
           await file.parent.create(recursive: true);
        }
        await file.writeAsBytes(fileBytes);
         // Invalidate cache after saving
         _excel = null;
      }
    } catch (e) {
      throw Exception('Error saving Excel file "$filePath": $e');
    }
  }

   // Method to explicitly close/clear the cache if needed (e.g., for testing)
   void clearCache() {
       _excel = null;
   }

  // --- Generic CRUD Operations ---

  Future<String> addItem<T extends ExcelStorable>(T item) async {
    final excel = await _loadExcel();
    final sheet = _ensureSheetExists(excel, item.sheetName);
    // Assign ID and timestamps if not already done (though model constructor does it)
    item.id = _uuid.v4();
    item.createdAt = DateTime.now();
    item.updatedAt = item.createdAt;

    sheet.appendRow(item.toRowData());
    await _saveExcel();
    return item.id;
  }

  Future<List<T>> getAllItems<T extends ExcelStorable>(T Function(List<Data?>) fromRowFactory) async {
    final excel = await _loadExcel();
    final sheetName = _getSheetNameFromType<T>();
    if (!excel.sheets.containsKey(sheetName)) {
      _ensureSheetExists(excel, sheetName); // Ensure sheet exists if file was just created
      await _saveExcel();
      return []; // No items yet
    }

    final sheet = excel.sheets[sheetName]!;
    final items = <T>[];

    // Start from row 1 to skip header (index 0)
    for (int i = 1; i < sheet.maxRows; i++) {
      // Get row data, ensuring we get nulls for empty cells up to maxCols
       final rowData = sheet.row(i); //.map((cell) => cell).toList(); // Get Data? objects
       // Pad rowData with nulls if it's shorter than expected header length
       final expectedLength = ExcelConstants.getHeadersForSheet(sheetName).length;
       while (rowData.length < expectedLength) {
           rowData.add(null);
       }

      try {
        // Check if the ID column (first column) is present and not empty
        if (rowData.isNotEmpty && rowData[0]?.value != null && rowData[0]!.value.toString().isNotEmpty) {
             items.add(fromRowFactory(rowData));
        } else {
            // Optionally log skipped empty/invalid rows
            // print("Skipping potentially empty or invalid row ${i + 1} in sheet $sheetName");
        }
      } catch (e) {
        print('⚠️ Error parsing row ${i + 1} in sheet "$sheetName": $e. Skipping row.');
        // Decide whether to throw, skip, or try to recover
      }
    }
    return items;
  }


  Future<T?> getItemById<T extends ExcelStorable>(String id, T Function(List<Data?>) fromRowFactory) async {
     final excel = await _loadExcel();
     final sheetName = _getSheetNameFromType<T>();
     if (!excel.sheets.containsKey(sheetName)) {
        return null; // Sheet doesn't exist
     }
     final sheet = excel.sheets[sheetName]!;

     // Find the row index for the given ID (assuming ID is in the first column, index 0)
     int? rowIndex;
     for (int i = 1; i < sheet.maxRows; i++) { // Skip header row
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
        if (cell.value?.toString() == id) {
            rowIndex = i;
            break;
        }
     }

     if (rowIndex == null) {
        return null; // ID not found
     }

     // Fetch the row data and parse
     final rowData = sheet.row(rowIndex);
      // Pad rowData with nulls if it's shorter than expected header length
       final expectedLength = ExcelConstants.getHeadersForSheet(sheetName).length;
       while (rowData.length < expectedLength) {
           rowData.add(null);
       }
     try {
         return fromRowFactory(rowData);
     } catch (e) {
         print('⚠️ Error parsing row ${rowIndex + 1} for ID "$id" in sheet "$sheetName": $e.');
         return null; // Return null if parsing fails for the found row
     }
  }


 Future<bool> updateItem<T extends ExcelStorable>(T item) async {
     final excel = await _loadExcel();
     final sheetName = item.sheetName; // Get sheet name from the item itself
      if (!excel.sheets.containsKey(sheetName)) {
        print("Error: Sheet '$sheetName' not found for update.");
        return false; // Sheet doesn't exist
     }
     final sheet = excel.sheets[sheetName]!;

     // Find the row index for the item's ID (assuming ID is in the first column, index 0)
     int? rowIndex;
     for (int i = 1; i < sheet.maxRows; i++) { // Skip header row
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
        if (cell.value?.toString() == item.id) {
            rowIndex = i;
            break;
        }
     }

      if (rowIndex == null) {
        print("Error: Item with ID '${item.id}' not found in sheet '$sheetName' for update.");
        return false; // ID not found
     }

     // Update the timestamp
     item.updatedAt = DateTime.now();

     // Get the new row data
     final newRowData = item.toRowData();
     final headers = item.headers;

     // Update the cells in the found row
     for (int colIndex = 0; colIndex < newRowData.length; colIndex++) {
         // Important: Use updateCell for existing rows
         sheet.updateCell(
             CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex),
             (newRowData[colIndex] ?? '') as CellValue?, // Provide empty string or specific null marker if needed by excel package
             // cellStyle: optionalCellStyle,
         );
     }

     await _saveExcel();
     return true; // Update successful
 }

 // --- Helper to get sheet name based on generic type ---
 // This is a bit hacky but avoids passing sheet name everywhere
 String _getSheetNameFromType<T>() {
     if (T == BacklogTask) return ExcelConstants.sheetTasks;
     if (T == FutureGoal) return ExcelConstants.sheetGoals;
     if (T == PlanningItem) return ExcelConstants.sheetPlans;
     if (T == Obstacle) return ExcelConstants.sheetObstacles;
     throw ArgumentError("Unsupported type for Excel service: $T");
 }
}
