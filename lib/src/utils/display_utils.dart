import 'package:tabular/tabular.dart';
import '../models/models.dart'; // Access displayHeaders

class DisplayUtils {
  /// Displays a list of items in a formatted table.
  static void printTable<T extends ExcelStorable>(
      List<T> items, List<String> headers) {
    if (items.isEmpty) {
      print("No items found.");
      return;
    }

    // Convert items to List<List<String>> for tabular
    final tableData = items.map((item) {
      // Need a way to get the display list from the item
      // Add a method to the models e.g., toListForDisplay()
      if (item is BacklogTask) return item.toListForDisplay();
      if (item is FutureGoal) return item.toListForDisplay();
      if (item is PlanningItem) return item.toListForDisplay();
      if (item is Obstacle) return item.toListForDisplay();
      print(
          "Warning: Using fallback display logic for item type ${item.runtimeType}. Implement 'toListForDisplay()' in '${item.runtimeType}' for optimal formatting.");
      return item.toRowData().map((cell) {
        // Use the static helper from ExcelStorable to extract the primitive value
        final dynamic primitiveValue = ExcelStorable.extractValue(cell);
        // Convert the extracted primitive value to a string for the table, handle nulls
        return primitiveValue?.toString() ?? '';
      }).toList();
    }).toList();

    // Prepend headers
    final dataWithHeaders = [headers, ...tableData];

    // Use tabular package
    print(tabular(
      dataWithHeaders,
      // border: Border.all, // Optional: add borders
      // rowDividers: true,  // Optional: add row dividers
      // align: { 0: Side.start, 1: Side.start }, // Example alignment
      // headerStyle: Style.bold // Optional: style header
    ));
  }
}
