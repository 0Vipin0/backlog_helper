// lib/src/models/models.dart

import 'package:excel/excel.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'enums.dart';
import '../constants/excel_constants.dart'; // For header constants

// Base class for items stored in Excel
abstract class ExcelStorable {
  String id; // Unique identifier (UUID)
  DateTime createdAt;
  DateTime updatedAt;

  ExcelStorable({required this.id, DateTime? createdAt, DateTime? updatedAt})
      : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Converts the object to a list of Excel CellValue objects for writing to a row.
  /// The order MUST match the headers defined in ExcelConstants.
  List<CellValue?> toRowData();

  /// Creates an instance from a list of Excel Data objects (cells in a row).
  /// Needs a factory constructor in each subclass.
  // factory ExcelStorable.fromRow(List<Data?> rowData) => throw UnimplementedError();

  /// Returns the headers corresponding to this item type.
  List<String> get headers;

  /// Returns the sheet name corresponding to this item type.
  String get sheetName;

  // --- Static Helper Methods ---
  // These MUST be called using ExcelStorable._getString() etc. from subclasses

  // Helper to safely get string value from Excel Data
  static String? _getString(Data? data) => data?.value?.toString().trim();

  // Helper to safely get DateTime from Excel Data (assuming ISO8601 string)
  static DateTime? _getDateTime(Data? data) {
    if (data == null || data.value == null) return null;

    try {
      // Priority 1: Check if it's already a DateTimeCellValue
      if (data.value is DateTimeCellValue) {
        // Use UTC for consistency, matching the toString() output
        return (data.value as DateTimeCellValue).asDateTimeUtc();
      }
      // Priority 2: Check if it's already a Dart DateTime (less likely from excel pkg?)
      if (data.value is DateTime) {
        return data.value as DateTime;
      }
      // Priority 3: Fallback to parsing the string representation
      final stringValue = data.value.toString().trim();
      if (stringValue.isEmpty) return null;
      // Attempt parsing ISO8601 format
      return DateTime.parse(stringValue);
    } catch (e) {
      // print("Warning: Could not parse date value '${data.value}': $e");
      return null; // Return null on any parsing error
    }
  }

  // Helper to format DateTime for Excel (ISO8601 string)
  static TextCellValue? _formatDateTime(DateTime? dt) =>
      dt == null ? null : TextCellValue(dt.toIso8601String());

  // Helper to format Enum for Excel
  static TextCellValue? _formatEnum<T extends Enum>(T? enumValue) =>
      enumValue == null ? null : TextCellValue(enumValue.name);

  // Helper to format String for Excel
  static TextCellValue? _formatString(String? value) =>
      (value == null || value.isEmpty) ? null : TextCellValue(value);

  // Helper to create TextCellValue (internal use or if needed directly)
  static TextCellValue _s(String value) => TextCellValue(value);
  static TextCellValue? _sN(String? value) => _formatString(value);

  /// Extracts the primitive value from a CellValue object for methods like updateCell.
  static dynamic extractValue(CellValue? cellValue) {
    if (cellValue == null) {
      return null; // Return null to clear the cell or handle as needed by excel pkg
    }
    // Check the specific type of CellValue and return its underlying value
    if (cellValue is TextCellValue) {
      return cellValue.value;
    } else if (cellValue is IntCellValue) {
      return cellValue.value;
    } else if (cellValue is DoubleCellValue) {
      return cellValue.value;
    } else if (cellValue is BoolCellValue) {
      return cellValue.value;
    } else if (cellValue is DateTimeCellValue) {
      // updateCell might prefer String or DateTime directly.
      // Sticking to ISO string might be safer if DateTime object causes issues.
      return cellValue.toString();;
    } else if (cellValue is FormulaCellValue) {
      // Decide how to handle formulas - maybe return the formula string?
      return cellValue.formula; // Returns the formula string e.g., "SUM(A1:A2)"
    }
    // Add other types if you use them (DateCellValue, TimeCellValue)

    // Fallback or throw error if type is unknown/unhandled
    return cellValue.toString(); // Less ideal fallback
  }
}


class BacklogTask extends ExcelStorable {
  String taskTitle;         // Mandatory
  String? description;
  Priority priority;          // Mandatory
  String? estimatedEffort;
  TaskStatus? status;
  String? dueDate;           // Store as YYYY-MM-DD String
  String? tagsCategories;
  String? dependencies;      // Comma-separated Task Titles
  String? reasoning;         // Related Goal/Plan Title
  String? resolution;

  BacklogTask({
    required String id,
    required this.taskTitle,
    required this.priority,
    this.description,
    this.estimatedEffort,
    this.status,
    this.dueDate,
    this.tagsCategories,
    this.dependencies,
    this.reasoning,
    this.resolution,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  @override
  String get sheetName => ExcelConstants.sheetTasks;

  @override
  List<String> get headers => ExcelConstants.headersTasks;

  @override
  List<CellValue?> toRowData() => [
    ExcelStorable._s(id),             // Use qualified static helper
    ExcelStorable._s(taskTitle),
    ExcelStorable._sN(description),
    ExcelStorable._s(priority.name),
    ExcelStorable._sN(estimatedEffort),
    ExcelStorable._formatEnum(status),
    ExcelStorable._sN(dueDate),
    ExcelStorable._sN(tagsCategories),
    ExcelStorable._sN(dependencies),
    ExcelStorable._sN(reasoning),
    ExcelStorable._sN(resolution),
    ExcelStorable._formatDateTime(createdAt),
    ExcelStorable._formatDateTime(updatedAt),
  ];

  factory BacklogTask.fromRow(List<Data?> rowData) {
    if (rowData.length < ExcelConstants.headersTasks.length) {
      throw FormatException("Invalid row data length for BacklogTask. Expected ${ExcelConstants.headersTasks.length}, got ${rowData.length}");
    }
    return BacklogTask(
      // --- CORRECTION: Qualify static calls with ExcelStorable. ---
      id: ExcelStorable._getString(rowData[0]) ?? (throw FormatException("Missing ID in Task row")),
      taskTitle: ExcelStorable._getString(rowData[1]) ?? (throw FormatException("Missing Task Title in row")),
      description: ExcelStorable._getString(rowData[2]),
      priority: PriorityExtension.tryParse(ExcelStorable._getString(rowData[3])) ?? (throw FormatException("Invalid or missing Priority in Task row")),
      estimatedEffort: ExcelStorable._getString(rowData[4]),
      status: TaskStatusExtension.tryParse(ExcelStorable._getString(rowData[5])),
      dueDate: ExcelStorable._getString(rowData[6]),
      tagsCategories: ExcelStorable._getString(rowData[7]),
      dependencies: ExcelStorable._getString(rowData[8]),
      reasoning: ExcelStorable._getString(rowData[9]),
      resolution: ExcelStorable._getString(rowData[10]),
      createdAt: ExcelStorable._getDateTime(rowData[11]) ?? DateTime.now(),
      updatedAt: ExcelStorable._getDateTime(rowData[12]) ?? DateTime.now(),
      // --- End CORRECTION ---
    );
  }

  List<String> toListForDisplay() => [
    id,
    taskTitle,
    description ?? '',
    priority.name,
    estimatedEffort ?? '',
    status?.name ?? '',
    dueDate ?? '',
    tagsCategories ?? '',
    dependencies ?? '',
    reasoning ?? '',
    resolution ?? '',
    DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
    DateFormat('yyyy-MM-dd HH:mm').format(updatedAt),
  ];

  static List<String> get displayHeaders => ExcelConstants.headersTasks;
}


class FutureGoal extends ExcelStorable {
  String goalDescription;      // Mandatory (mapped to 'Goal Title' header)
  String targetCompletionDate; // Mandatory (YYYY-MM-DD)
  Priority priority;           // Mandatory
  String? kpis;
  String? resourcesRequired;
  GoalStatus? currentStatus;
  String? motivation;
  String? firstStep;            // Related Task Title
  String? potentialChallenges;  // Related Obstacle Titles (comma-sep)
  String? supportContacts;

  FutureGoal({
    required String id,
    required this.goalDescription,
    required this.targetCompletionDate,
    required this.priority,
    this.kpis,
    this.resourcesRequired,
    this.currentStatus,
    this.motivation,
    this.firstStep,
    this.potentialChallenges,
    this.supportContacts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  @override
  String get sheetName => ExcelConstants.sheetGoals;

  @override
  List<String> get headers => ExcelConstants.headersGoals;

  @override
  List<CellValue?> toRowData() => [
    ExcelStorable._s(id),
    ExcelStorable._s(goalDescription),
    ExcelStorable._s(targetCompletionDate),
    ExcelStorable._s(priority.name),
    ExcelStorable._sN(kpis),
    ExcelStorable._sN(resourcesRequired),
    ExcelStorable._formatEnum(currentStatus),
    ExcelStorable._sN(motivation),
    ExcelStorable._sN(firstStep),
    ExcelStorable._sN(potentialChallenges),
    ExcelStorable._sN(supportContacts),
    ExcelStorable._formatDateTime(createdAt),
    ExcelStorable._formatDateTime(updatedAt),
  ];

  factory FutureGoal.fromRow(List<Data?> rowData) {
    if (rowData.length < ExcelConstants.headersGoals.length) {
      throw FormatException("Invalid row data length for FutureGoal. Expected ${ExcelConstants.headersGoals.length}, got ${rowData.length}");
    }
    return FutureGoal(
      // --- CORRECTION: Qualify static calls ---
      id: ExcelStorable._getString(rowData[0]) ?? (throw FormatException("Missing ID in Goal row")),
      goalDescription: ExcelStorable._getString(rowData[1]) ?? (throw FormatException("Missing Goal Title in row")),
      targetCompletionDate: ExcelStorable._getString(rowData[2]) ?? (throw FormatException("Missing Target Completion Date in Goal row")),
      priority: PriorityExtension.tryParse(ExcelStorable._getString(rowData[3])) ?? (throw FormatException("Invalid or missing Priority in Goal row")),
      kpis: ExcelStorable._getString(rowData[4]),
      resourcesRequired: ExcelStorable._getString(rowData[5]),
      currentStatus: GoalStatusExtension.tryParse(ExcelStorable._getString(rowData[6])),
      motivation: ExcelStorable._getString(rowData[7]),
      firstStep: ExcelStorable._getString(rowData[8]),
      potentialChallenges: ExcelStorable._getString(rowData[9]),
      supportContacts: ExcelStorable._getString(rowData[10]),
      createdAt: ExcelStorable._getDateTime(rowData[11]) ?? DateTime.now(),
      updatedAt: ExcelStorable._getDateTime(rowData[12]) ?? DateTime.now(),
      // --- End CORRECTION ---
    );
  }

  List<String> toListForDisplay() => [
    id,
    goalDescription,
    targetCompletionDate,
    priority.name,
    kpis ?? '',
    resourcesRequired ?? '',
    currentStatus?.name ?? '',
    motivation ?? '',
    firstStep ?? '',
    potentialChallenges ?? '',
    supportContacts ?? '',
    DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
    DateFormat('yyyy-MM-dd HH:mm').format(updatedAt),
  ];
  static List<String> get displayHeaders => ExcelConstants.headersGoals;
}

class PlanningItem extends ExcelStorable {
  String planItemDescription; // Mandatory (mapped to 'Plan Title')
  PlanType typeOfPlan;        // Mandatory
  String? startDate;          // YYYY-MM-DD
  String? endDate;            // YYYY-MM-DD
  String? dependencies;       // Comma-separated Plan Titles
  String? progress;
  String status;              // Mandatory (e.g., On Track, At Risk) - Kept as String
  String? relatedGoal;        // Related Goal Title
  String? keyMilestones;      // Related Task Titles (comma-sep)
  String? allocatedResources;

  PlanningItem({
    required String id,
    required this.planItemDescription,
    required this.typeOfPlan,
    required this.status,
    this.startDate,
    this.endDate,
    this.dependencies,
    this.progress,
    this.relatedGoal,
    this.keyMilestones,
    this.allocatedResources,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  @override
  String get sheetName => ExcelConstants.sheetPlans;

  @override
  List<String> get headers => ExcelConstants.headersPlans;

  @override
  List<CellValue?> toRowData() => [
    ExcelStorable._s(id),
    ExcelStorable._s(planItemDescription),
    ExcelStorable._s(typeOfPlan.name),
    ExcelStorable._sN(startDate),
    ExcelStorable._sN(endDate),
    ExcelStorable._sN(dependencies),
    ExcelStorable._sN(progress),
    ExcelStorable._s(status), // String status
    ExcelStorable._sN(relatedGoal),
    ExcelStorable._sN(keyMilestones),
    ExcelStorable._sN(allocatedResources),
    ExcelStorable._formatDateTime(createdAt),
    ExcelStorable._formatDateTime(updatedAt),
  ];

  factory PlanningItem.fromRow(List<Data?> rowData) {
    if (rowData.length < ExcelConstants.headersPlans.length) {
      throw FormatException("Invalid row data length for PlanningItem. Expected ${ExcelConstants.headersPlans.length}, got ${rowData.length}");
    }
    return PlanningItem(
      // --- CORRECTION: Qualify static calls ---
      id: ExcelStorable._getString(rowData[0]) ?? (throw FormatException("Missing ID in Plan row")),
      planItemDescription: ExcelStorable._getString(rowData[1]) ?? (throw FormatException("Missing Plan Title in row")),
      typeOfPlan: PlanTypeExtension.tryParse(ExcelStorable._getString(rowData[2])) ?? (throw FormatException("Invalid or missing Type of Plan in Plan row")),
      startDate: ExcelStorable._getString(rowData[3]),
      endDate: ExcelStorable._getString(rowData[4]),
      dependencies: ExcelStorable._getString(rowData[5]),
      progress: ExcelStorable._getString(rowData[6]),
      status: ExcelStorable._getString(rowData[7]) ?? (throw FormatException("Missing Status in Plan row")), // String status
      relatedGoal: ExcelStorable._getString(rowData[8]),
      keyMilestones: ExcelStorable._getString(rowData[9]),
      allocatedResources: ExcelStorable._getString(rowData[10]),
      createdAt: ExcelStorable._getDateTime(rowData[11]) ?? DateTime.now(),
      updatedAt: ExcelStorable._getDateTime(rowData[12]) ?? DateTime.now(),
      // --- End CORRECTION ---
    );
  }

  List<String> toListForDisplay() => [
    id,
    planItemDescription,
    typeOfPlan.name,
    startDate ?? '',
    endDate ?? '',
    dependencies ?? '',
    progress ?? '',
    status,
    relatedGoal ?? '',
    keyMilestones ?? '',
    allocatedResources ?? '',
    DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
    DateFormat('yyyy-MM-dd HH:mm').format(updatedAt),
  ];
  static List<String> get displayHeaders => ExcelConstants.headersPlans;
}


class Obstacle extends ExcelStorable {
  String obstacleDescription; // Mandatory (mapped to 'Obstacle Title')
  Likelihood? likelihoodOfOccurrence;
  Impact? potentialImpact;
  String? mitigationStrategies;
  String? contingencyPlans;
  ObstacleCategory? category;
  String? status;              // E.g., Open, Resolved - Kept as String
  String? relatedItem;         // Related Goal/Task/Plan Title
  String? assignedTo;
  String? dateIdentified;      // YYYY-MM-DD

  Obstacle({
    required String id,
    required this.obstacleDescription,
    this.likelihoodOfOccurrence,
    this.potentialImpact,
    this.mitigationStrategies,
    this.contingencyPlans,
    this.category,
    this.status,
    this.relatedItem,
    this.assignedTo,
    this.dateIdentified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  @override
  String get sheetName => ExcelConstants.sheetObstacles;

  @override
  List<String> get headers => ExcelConstants.headersObstacles;

  @override
  List<CellValue?> toRowData() => [
    ExcelStorable._s(id),
    ExcelStorable._s(obstacleDescription),
    ExcelStorable._formatEnum(likelihoodOfOccurrence),
    ExcelStorable._formatEnum(potentialImpact),
    ExcelStorable._sN(mitigationStrategies),
    ExcelStorable._sN(contingencyPlans),
    ExcelStorable._formatEnum(category),
    ExcelStorable._sN(status), // String status
    ExcelStorable._sN(relatedItem),
    ExcelStorable._sN(assignedTo),
    ExcelStorable._sN(dateIdentified),
    ExcelStorable._formatDateTime(createdAt),
    ExcelStorable._formatDateTime(updatedAt),
  ];

  factory Obstacle.fromRow(List<Data?> rowData) {
    if (rowData.length < ExcelConstants.headersObstacles.length) {
      throw FormatException("Invalid row data length for Obstacle. Expected ${ExcelConstants.headersObstacles.length}, got ${rowData.length}");
    }
    return Obstacle(
      // --- CORRECTION: Qualify static calls ---
      id: ExcelStorable._getString(rowData[0]) ?? (throw FormatException("Missing ID in Obstacle row")),
      obstacleDescription: ExcelStorable._getString(rowData[1]) ?? (throw FormatException("Missing Obstacle Title in row")),
      likelihoodOfOccurrence: LikelihoodExtension.tryParse(ExcelStorable._getString(rowData[2])),
      potentialImpact: ImpactExtension.tryParse(ExcelStorable._getString(rowData[3])),
      mitigationStrategies: ExcelStorable._getString(rowData[4]),
      contingencyPlans: ExcelStorable._getString(rowData[5]),
      category: ObstacleCategoryExtension.tryParse(ExcelStorable._getString(rowData[6])),
      status: ExcelStorable._getString(rowData[7]), // String status
      relatedItem: ExcelStorable._getString(rowData[8]),
      assignedTo: ExcelStorable._getString(rowData[9]),
      dateIdentified: ExcelStorable._getString(rowData[10]),
      createdAt: ExcelStorable._getDateTime(rowData[11]) ?? DateTime.now(),
      updatedAt: ExcelStorable._getDateTime(rowData[12]) ?? DateTime.now(),
      // --- End CORRECTION ---
    );
  }
  List<String> toListForDisplay() => [
    id,
    obstacleDescription,
    likelihoodOfOccurrence?.name ?? '',
    potentialImpact?.name ?? '',
    mitigationStrategies ?? '',
    contingencyPlans ?? '',
    category?.name ?? '',
    status ?? '', // Display string status
    relatedItem ?? '',
    assignedTo ?? '',
    dateIdentified ?? '',
    DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
    DateFormat('yyyy-MM-dd HH:mm').format(updatedAt),
  ];
  static List<String> get displayHeaders => ExcelConstants.headersObstacles;
}