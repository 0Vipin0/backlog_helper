import 'package:backlog_manager_excel/src/constants/excel_constants.dart';
import 'package:backlog_manager_excel/src/models/enums.dart';
import 'package:backlog_manager_excel/src/models/models.dart';
import 'package:test/test.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:equatable/equatable.dart'; // Import Equatable

// This mock focuses on providing the `value` getter as CellValue?
// for testing ExcelStorable.fromRow, which mainly reads this property.
// It does NOT fully replicate Sheet interactions or internal state.
class MockData extends Equatable implements Data {
  // Store the value as CellValue? to match the real 'Data' class getter.
  final CellValue? _value;

  // Simple constructor for testing, directly accepting the CellValue.
  MockData(this._value);

  // --- Implement required getters/setters from Data interface (mostly stubs) ---

  @override
  CellValue? get value => _value; // The critical part for our tests

  // Provide sensible defaults or stubs for unused members
  @override
  CellStyle? get cellStyle => null;

  @override
  CellIndex get cellIndex =>
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0); // Default stub
  @override
  int get columnIndex => 0; // Default stub
  @override
  int get rowIndex => 0; // Default stub
  @override
  String get sheetName => 'MockSheet'; // Default stub

  // Implement setters as no-ops or throw if needed, as they aren't used
  // directly by the fromRow logic being tested.
  @override
  set cellStyle(CellStyle? _) {
    // print("Warning: MockData cellStyle setter called (no-op)");
  }

  @override
  set value(CellValue? val) {
    // print("Warning: MockData value setter called (no-op)");
    // Note: Cannot actually change the final _value field here.
    // If testing logic relies on setting value via the Data object,
    // a more complex mock (possibly with mocktail and a MockSheet) is needed.
  }

  // Stub for setFormula if ever needed by tested code (unlikely for fromRow)
  @override
  void setFormula(String formula) {
    // print("Warning: MockData setFormula called (no-op)");
  }

  // --- Equatable Implementation ---
  @override
  List<Object?> get props => [
        _value,
        columnIndex,
        rowIndex,
        cellStyle,
        sheetName
      ]; // Match props somewhat
}

// Converts various dart types into a MockData object containing the
// appropriate CellValue type.
Data? d(dynamic value) {
  if (value == null) return MockData(null); // Wrap null in MockData

  CellValue cellValue;
  if (value is DateTime) {
    // Consistent with _formatDateTime which creates TextCellValue
    cellValue = TextCellValue(value.toIso8601String());
  } else if (value is bool) {
    cellValue = BoolCellValue(value);
  } else if (value is int) {
    cellValue = IntCellValue(value);
  } else if (value is double) {
    cellValue = DoubleCellValue(value);
  } else if (value is String) {
    cellValue = TextCellValue(value);
  } else if (value is CellValue) {
    // If it's already a CellValue, use it directly
    cellValue = value;
  } else {
    // Fallback for other types (like enums before formatting)
    cellValue = TextCellValue(value.toString());
  }
  return MockData(cellValue);
}

// Helper specifically for simulating a DateTimeCellValue source
// (for testing the _getDateTime logic branch)
Data? dDate(DateTime? dt) {
  if (dt == null) return MockData(null);
  // Use the actual DateTimeCellValue constructor
  return MockData(DateTimeCellValue.fromDateTime(dt));
}

// Concrete implementation for testing ExcelStorable constructor & helpers
class TestStorable extends ExcelStorable {
  String name;

  TestStorable({
    required super.id,
    required this.name,
    super.createdAt,
    super.updatedAt,
  });

  @override
  List<String> get headers => ['ID', 'Name', 'CreatedAt', 'UpdatedAt'];

  @override
  String get sheetName => 'TestSheet';

  @override
  List<CellValue?> toRowData() => [
        ExcelStorable.s(id),
        ExcelStorable.s(name),
        ExcelStorable.formatDateTime(createdAt),
        ExcelStorable.formatDateTime(updatedAt),
      ];

  // Static accessors for testing protected helpers
  static String? testGetString(Data? data) => ExcelStorable.getString(data);

  static DateTime? testGetDateTime(Data? data) =>
      ExcelStorable.getDateTime(data);

  static TextCellValue? testFormatDateTime(DateTime? dt) =>
      ExcelStorable.formatDateTime(dt);

  static TextCellValue? testFormatEnum<T extends Enum>(T? enumValue) =>
      ExcelStorable.formatEnum(enumValue);

  static TextCellValue? testFormatString(String? value) =>
      ExcelStorable.formatString(value);
}

void main() {
  final now = DateTime.now();
  final later = now.add(const Duration(days: 1));
  final isoNow = now.toIso8601String();
  final isoLater = later.toIso8601String();

  group('ExcelStorable Base Class', () {
    test('Constructor sets id, createdAt, updatedAt correctly (with defaults)',
        () {
      final item = TestStorable(id: 'id1', name: 'Test');
      expect(item.id, 'id1');
      expect(item.name, 'Test');
      // Check if dates are roughly 'now' (allow small difference)
      expect(item.createdAt.difference(DateTime.now()).inSeconds.abs(),
          lessThan(5));
      expect(item.updatedAt.difference(DateTime.now()).inSeconds.abs(),
          lessThan(5));
    });

    test(
        'Constructor sets id, createdAt, updatedAt correctly (with provided dates)',
        () {
      final item = TestStorable(
          id: 'id2', name: 'Test 2', createdAt: now, updatedAt: later);
      expect(item.id, 'id2');
      expect(item.name, 'Test 2');
      expect(item.createdAt, now);
      expect(item.updatedAt, later);
    });

    group('Static Helpers (_)', () {
      // ... _getString, _getDateTime tests ...

      test('_formatDateTime returns TextCellValue with ISO string or null', () {
        final dt = DateTime.utc(2023, 11, 1, 10, 0);
        final dtIso = dt.toIso8601String();
        final cellValue = TestStorable.testFormatDateTime(dt);

        expect(cellValue, isA<TextCellValue>());
        // Change: Compare against toString()
        expect(cellValue?.toString(), equals(dtIso));
        expect(TestStorable.testFormatDateTime(null), isNull);
      });

      test('_formatEnum returns TextCellValue with enum name or null', () {
        final cellValue = TestStorable.testFormatEnum(Priority.high);
        expect(cellValue, isA<TextCellValue>());
        // Change: Compare against toString()
        expect(cellValue?.toString(), equals('high'));

        expect(TestStorable.testFormatEnum<Priority>(null), isNull);
      });

      test('_formatString returns TextCellValue or null for empty/null', () {
        final cellValue = TestStorable.testFormatString(" test ");
        expect(cellValue, isA<TextCellValue>());
        // Change: Compare against toString()
        expect(cellValue?.toString(), equals(" test "));

        expect(TestStorable.testFormatString(""), isNull);
        expect(TestStorable.testFormatString(null), isNull);
      });

      // Keep the extractValue test structure, but ensure extractValue itself is fixed
      test('extractValue returns underlying value from CellValue', () {
        expect(ExcelStorable.extractValue(TextCellValue('hello')),
            equals('hello')); // This should pass AFTER fixing extractValue
        expect(ExcelStorable.extractValue(IntCellValue(123)), equals(123));
        expect(ExcelStorable.extractValue(DoubleCellValue(123.45)),
            equals(123.45));
        expect(ExcelStorable.extractValue(BoolCellValue(true)), equals(true));
        final dt = DateTime.utc(2023, 1, 1);
        final dtCellValue = DateTimeCellValue.fromDateTime(dt);
        // This might still return the ISO string via toString() in extractValue
        expect(ExcelStorable.extractValue(dtCellValue),
            equals(dtCellValue.toString()));
        expect(ExcelStorable.extractValue(FormulaCellValue('SUM(A1:A2)')),
            equals('SUM(A1:A2)'));
        expect(ExcelStorable.extractValue(null), isNull);
      });
    });
  });

  group('BacklogTask Tests', () {
    // Sample valid row data matching ExcelConstants.headersTasks order
    final validRowData = [
      d('task-001'), // ID
      d(' Implement feature X '), // Task Title (with spaces for trimming test)
      d(' Detail description '), // Description
      d('high'), // Priority
      d(' 3d '), // Estimated Effort
      d('inProgress'), // Status
      d('2024-12-31'), // Due Date
      d(' backend, api '), // Tags/Categories
      d(' task-000 '), // Dependencies
      d(' Goal Alpha '), // Reasoning
      d(' Fixed in commit abc '), // Resolution
      d(isoNow), // CreatedAt
      d(isoLater), // UpdatedAt
    ];

    // Expected BacklogTask instance from validRowData
    final expectedTask = BacklogTask(
      id: 'task-001',
      taskTitle: 'Implement feature X',
      description: 'Detail description',
      priority: Priority.high,
      estimatedEffort: '3d',
      status: TaskStatus.inProgress,
      dueDate: '2024-12-31',
      tagsCategories: 'backend, api',
      dependencies: 'task-000',
      reasoning: 'Goal Alpha',
      resolution: 'Fixed in commit abc',
      createdAt: DateTime.parse(isoNow),
      updatedAt: DateTime.parse(isoLater),
    );

    test('sheetName returns correct constant', () {
      expect(expectedTask.sheetName, ExcelConstants.sheetTasks);
    });

    test('headers returns correct constant list', () {
      expect(expectedTask.headers, ExcelConstants.headersTasks);
      expect(BacklogTask.displayHeaders, ExcelConstants.headersTasks);
    });

    test('toRowData converts object to correct CellValue list', () {
      final task = BacklogTask(
        id: 't1',
        taskTitle: 'Test Title',
        priority: Priority.medium,
        description: 'Desc',
        status: TaskStatus.toDo,
        dueDate: '2025-01-01',
        createdAt: now,
        updatedAt: now,
      );
      final rowData = task.toRowData();

      expect(rowData.length, ExcelConstants.headersTasks.length);
      expect(rowData[0],
          isA<TextCellValue>().having((c) => c.toString(), 'toString()', 't1'));
      expect(
          rowData[1],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'Test Title'));
      expect(
          rowData[2],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'Desc'));
      expect(
          rowData[3],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'medium'));
      expect(rowData[4], isNull); // estimatedEffort is null
      expect(
          rowData[5],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'toDo'));
      expect(
          rowData[6],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', '2025-01-01'));
      // ... check other null fields (7-10)
      expect(rowData[7], isNull);
      expect(rowData[8], isNull);
      expect(rowData[9], isNull);
      expect(rowData[10], isNull);
      expect(
          rowData[11],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', isoNow));
      expect(
          rowData[12],
          isA<TextCellValue>().having((c) => c.toString(), 'toString()',
              isoNow)); // updatedAt is also now
    });

    test('fromRow creates instance from valid data', () {
      final task = BacklogTask.fromRow(validRowData);

      expect(task.id, expectedTask.id);
      expect(task.taskTitle, expectedTask.taskTitle);
      expect(task.description, expectedTask.description);
      expect(task.priority, expectedTask.priority);
      expect(task.estimatedEffort, expectedTask.estimatedEffort);
      expect(task.status, expectedTask.status);
      expect(task.dueDate, expectedTask.dueDate);
      expect(task.tagsCategories, expectedTask.tagsCategories);
      expect(task.dependencies, expectedTask.dependencies);
      expect(task.reasoning, expectedTask.reasoning);
      expect(task.resolution, expectedTask.resolution);
      // Use isAtSameMomentAs for DateTime comparison due to potential minor precision diffs
      expect(task.createdAt.isAtSameMomentAs(expectedTask.createdAt), isTrue);
      expect(task.updatedAt.isAtSameMomentAs(expectedTask.updatedAt), isTrue);
    });

    test('fromRow handles optional fields being null', () {
      final minimalRowData = [
        d('task-min'), // ID
        d('Minimal Task'), // Task Title
        null, // Description
        d('low'), // Priority
        null, null, null, null, null, null, null, // Optional strings
        d(isoNow), // CreatedAt
        d(isoNow), // UpdatedAt
      ];
      final task = BacklogTask.fromRow(minimalRowData);

      expect(task.id, 'task-min');
      expect(task.taskTitle, 'Minimal Task');
      expect(task.priority, Priority.low);
      expect(task.description, isNull);
      expect(task.estimatedEffort, isNull);
      expect(task.status, isNull);
      // ... check all other optionals are null
      expect(task.dueDate, isNull);
      expect(task.tagsCategories, isNull);
      expect(task.dependencies, isNull);
      expect(task.reasoning, isNull);
      expect(task.resolution, isNull);
      expect(task.createdAt.isAtSameMomentAs(DateTime.parse(isoNow)), isTrue);
      expect(task.updatedAt.isAtSameMomentAs(DateTime.parse(isoNow)), isTrue);
    });

    test('fromRow throws FormatException for insufficient row length', () {
      final shortRow = validRowData.sublist(0, 5);
      expect(() => BacklogTask.fromRow(shortRow), throwsFormatException);
    });

    test('fromRow throws FormatException for missing required fields', () {
      final testDataMissingId = List<Data?>.from(validRowData);
      testDataMissingId[0] = null; // Missing ID
      expect(
          () => BacklogTask.fromRow(testDataMissingId), throwsFormatException);

      final testDataMissingTitle = List<Data?>.from(validRowData);
      testDataMissingTitle[1] = null; // Missing Title
      expect(() => BacklogTask.fromRow(testDataMissingTitle),
          throwsFormatException);

      final testDataMissingPriority = List<Data?>.from(validRowData);
      testDataMissingPriority[3] = null; // Missing Priority
      expect(() => BacklogTask.fromRow(testDataMissingPriority),
          throwsFormatException);

      final testDataInvalidPriority = List<Data?>.from(validRowData);
      testDataInvalidPriority[3] = d('invalid'); // Invalid Priority
      expect(() => BacklogTask.fromRow(testDataInvalidPriority),
          throwsFormatException);
    });

    test('toListForDisplay returns correct string list', () {
      final task = BacklogTask(
        id: 't1',
        taskTitle: 'Display Task',
        priority: Priority.high,
        status: TaskStatus.blocked,
        createdAt: DateTime(2023, 1, 1, 10, 30),
        updatedAt: DateTime(2023, 1, 2, 11, 0),
      );
      final displayList = task.toListForDisplay();
      final expectedDateFormat = DateFormat('yyyy-MM-dd HH:mm');

      expect(displayList, [
        't1',
        'Display Task',
        '', // description
        'high',
        '', // estimatedEffort
        'blocked',
        '', // dueDate
        '', // tagsCategories
        '', // dependencies
        '', // reasoning
        '', // resolution
        expectedDateFormat.format(task.createdAt),
        expectedDateFormat.format(task.updatedAt),
      ]);
    });
  });

  // --- Repeat similar group structure for FutureGoal, PlanningItem, Obstacle ---

  group('FutureGoal Tests', () {
    final validGoalRow = [
      d('goal-01'), // ID
      d(' Increase Market Share '), // Goal Description
      d('2025-12-31'), // Target Completion Date
      d('medium'), // Priority
      d(' Reach 20% market share '), // KPIs
      d(' Sales Team, Marketing Budget '), // Resources Required
      d('inProgress'), // Current Status
      d(' Expand business '), // Motivation
      d(' task-launch-campaign '), // First Step
      d(' obstacle-competitor '), // Potential Challenges
      d(' Sales Lead, Marketing Head '), // Support Contacts
      d(isoNow), // CreatedAt
      d(isoLater), // UpdatedAt
    ];

    final expectedGoal = FutureGoal(
      id: 'goal-01',
      goalDescription: 'Increase Market Share',
      targetCompletionDate: '2025-12-31',
      priority: Priority.medium,
      kpis: 'Reach 20% market share',
      resourcesRequired: 'Sales Team, Marketing Budget',
      currentStatus: GoalStatus.inProgress,
      motivation: 'Expand business',
      firstStep: 'task-launch-campaign',
      potentialChallenges: 'obstacle-competitor',
      supportContacts: 'Sales Lead, Marketing Head',
      createdAt: DateTime.parse(isoNow),
      updatedAt: DateTime.parse(isoLater),
    );

    test('sheetName returns correct constant', () {
      expect(expectedGoal.sheetName, ExcelConstants.sheetGoals);
    });

    test('headers returns correct constant list', () {
      expect(expectedGoal.headers, ExcelConstants.headersGoals);
      expect(FutureGoal.displayHeaders, ExcelConstants.headersGoals);
    });

    test('toRowData converts object to correct CellValue list', () {
      final goal = FutureGoal(
        id: 'g1',
        goalDescription: 'Goal Desc',
        targetCompletionDate: '2024-06-30',
        priority: Priority.low,
        currentStatus: GoalStatus.planning,
        createdAt: now,
        updatedAt: now,
      );
      final rowData = goal.toRowData();

      expect(rowData.length, ExcelConstants.headersGoals.length);
      expect(rowData[0],
          isA<TextCellValue>().having((c) => c.toString(), 'toString()', 'g1'));
      expect(
          rowData[1],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'Goal Desc'));
      expect(
          rowData[2],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', '2024-06-30'));
      expect(
          rowData[3],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'low'));
      expect(rowData[4], isNull); // kpis
      expect(rowData[5], isNull); // resourcesRequired
      expect(
          rowData[6],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'planning'));
      // ... check other null fields (7-10)
      expect(rowData[7], isNull);
      expect(rowData[8], isNull);
      expect(rowData[9], isNull);
      expect(rowData[10], isNull);
      expect(
          rowData[11],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', isoNow));
      expect(
          rowData[12],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', isoNow));
    });

    test('fromRow creates instance from valid data', () {
      final goal = FutureGoal.fromRow(validGoalRow);

      expect(goal.id, expectedGoal.id);
      expect(goal.goalDescription, expectedGoal.goalDescription);
      expect(goal.targetCompletionDate, expectedGoal.targetCompletionDate);
      expect(goal.priority, expectedGoal.priority);
      expect(goal.kpis, expectedGoal.kpis);
      expect(goal.resourcesRequired, expectedGoal.resourcesRequired);
      expect(goal.currentStatus, expectedGoal.currentStatus);
      expect(goal.motivation, expectedGoal.motivation);
      expect(goal.firstStep, expectedGoal.firstStep);
      expect(goal.potentialChallenges, expectedGoal.potentialChallenges);
      expect(goal.supportContacts, expectedGoal.supportContacts);
      expect(goal.createdAt.isAtSameMomentAs(expectedGoal.createdAt), isTrue);
      expect(goal.updatedAt.isAtSameMomentAs(expectedGoal.updatedAt), isTrue);
    });

    test('fromRow throws FormatException for missing required fields', () {
      final testDataMissingId = List<Data?>.from(validGoalRow)
        ..removeAt(0)
        ..insert(0, null);
      expect(
          () => FutureGoal.fromRow(testDataMissingId), throwsFormatException);

      final testDataMissingDesc = List<Data?>.from(validGoalRow)
        ..removeAt(1)
        ..insert(1, null);
      expect(
          () => FutureGoal.fromRow(testDataMissingDesc), throwsFormatException);

      final testDataMissingTargetDate = List<Data?>.from(validGoalRow)
        ..removeAt(2)
        ..insert(2, null);
      expect(() => FutureGoal.fromRow(testDataMissingTargetDate),
          throwsFormatException);

      final testDataMissingPriority = List<Data?>.from(validGoalRow)
        ..removeAt(3)
        ..insert(3, null);
      expect(() => FutureGoal.fromRow(testDataMissingPriority),
          throwsFormatException);
    });

    test('toListForDisplay returns correct string list', () {
      final goal = FutureGoal(
        id: 'g1',
        goalDescription: 'Display Goal',
        targetCompletionDate: '2024-12-31',
        priority: Priority.medium,
        createdAt: DateTime(2023, 2, 1, 12, 0),
        updatedAt: DateTime(2023, 2, 2, 13, 0),
      );
      final displayList = goal.toListForDisplay();
      final expectedDateFormat = DateFormat('yyyy-MM-dd HH:mm');

      expect(displayList, [
        'g1',
        'Display Goal',
        '2024-12-31',
        'medium',
        '', '', '', '', '', '', '', // Optionals
        expectedDateFormat.format(goal.createdAt),
        expectedDateFormat.format(goal.updatedAt),
      ]);
    });
  });

  group('PlanningItem Tests', () {
    final validPlanRow = [
      d('plan-01'), // ID
      d(' Q4 Marketing Push '), // Plan Item Description
      d('tactical'), // Type of Plan
      d('2024-10-01'), // Start Date
      d('2024-12-31'), // End Date
      d(' plan-overall-strategy '), // Dependencies
      d(' 50% '), // Progress
      d('On Track'), // Status (String)
      d(' goal-increase-q4-sales '), // Related Goal
      d(' task-ads, task-webinar '), // Key Milestones
      d(' Marketing Team A '), // Allocated Resources
      d(isoNow), // CreatedAt
      d(isoLater), // UpdatedAt
    ];

    final expectedPlan = PlanningItem(
      id: 'plan-01',
      planItemDescription: 'Q4 Marketing Push',
      typeOfPlan: PlanType.tactical,
      startDate: '2024-10-01',
      endDate: '2024-12-31',
      dependencies: 'plan-overall-strategy',
      progress: '50%',
      status: 'On Track',
      relatedGoal: 'goal-increase-q4-sales',
      keyMilestones: 'task-ads, task-webinar',
      allocatedResources: 'Marketing Team A',
      createdAt: DateTime.parse(isoNow),
      updatedAt: DateTime.parse(isoLater),
    );

    test('sheetName returns correct constant', () {
      expect(expectedPlan.sheetName, ExcelConstants.sheetPlans);
    });

    test('headers returns correct constant list', () {
      expect(expectedPlan.headers, ExcelConstants.headersPlans);
      expect(PlanningItem.displayHeaders, ExcelConstants.headersPlans);
    });

    test('toRowData converts object to correct CellValue list', () {
      final plan = PlanningItem(
        id: 'p1',
        planItemDescription: 'Plan Desc',
        typeOfPlan: PlanType.operational,
        status: 'Pending',
        // Mandatory string
        createdAt: now,
        updatedAt: now,
      );
      final rowData = plan.toRowData();

      expect(rowData.length, ExcelConstants.headersPlans.length);
      expect(rowData[0],
          isA<TextCellValue>().having((c) => c.toString(), 'toString()', 'p1'));
      expect(
          rowData[1],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'Plan Desc'));
      expect(
          rowData[2],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'operational'));
      expect(rowData[3], isNull); // startDate
      expect(rowData[4], isNull); // endDate
      expect(rowData[5], isNull); // dependencies
      expect(rowData[6], isNull); // progress
      expect(
          rowData[7],
          isA<TextCellValue>().having(
              (c) => c.toString(), 'toString()', 'Pending')); // status (string)
      // ... check other null fields (8-10)
      expect(rowData[8], isNull);
      expect(rowData[9], isNull);
      expect(rowData[10], isNull);
      expect(
          rowData[11],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', isoNow));
      expect(
          rowData[12],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', isoNow));
    });

    test('fromRow creates instance from valid data', () {
      final plan = PlanningItem.fromRow(validPlanRow);

      expect(plan.id, expectedPlan.id);
      expect(plan.planItemDescription, expectedPlan.planItemDescription);
      expect(plan.typeOfPlan, expectedPlan.typeOfPlan);
      expect(plan.startDate, expectedPlan.startDate);
      expect(plan.endDate, expectedPlan.endDate);
      expect(plan.dependencies, expectedPlan.dependencies);
      expect(plan.progress, expectedPlan.progress);
      expect(plan.status, expectedPlan.status); // String status
      expect(plan.relatedGoal, expectedPlan.relatedGoal);
      expect(plan.keyMilestones, expectedPlan.keyMilestones);
      expect(plan.allocatedResources, expectedPlan.allocatedResources);
      expect(plan.createdAt.isAtSameMomentAs(expectedPlan.createdAt), isTrue);
      expect(plan.updatedAt.isAtSameMomentAs(expectedPlan.updatedAt), isTrue);
    });

    test('fromRow throws FormatException for missing required fields', () {
      final testDataMissingId = List<Data?>.from(validPlanRow)
        ..removeAt(0)
        ..insert(0, null);
      expect(
          () => PlanningItem.fromRow(testDataMissingId), throwsFormatException);

      final testDataMissingDesc = List<Data?>.from(validPlanRow)
        ..removeAt(1)
        ..insert(1, null);
      expect(() => PlanningItem.fromRow(testDataMissingDesc),
          throwsFormatException);

      final testDataMissingType = List<Data?>.from(validPlanRow)
        ..removeAt(2)
        ..insert(2, null);
      expect(() => PlanningItem.fromRow(testDataMissingType),
          throwsFormatException);

      final testDataMissingStatus = List<Data?>.from(validPlanRow)
        ..removeAt(7)
        ..insert(7, null); // Status is required string
      expect(() => PlanningItem.fromRow(testDataMissingStatus),
          throwsFormatException);
    });

    test('toListForDisplay returns correct string list', () {
      final plan = PlanningItem(
        id: 'p1',
        planItemDescription: 'Display Plan',
        typeOfPlan: PlanType.strategic,
        status: 'Completed',
        createdAt: DateTime(2023, 3, 1, 14, 0),
        updatedAt: DateTime(2023, 3, 2, 15, 0),
      );
      final displayList = plan.toListForDisplay();
      final expectedDateFormat = DateFormat('yyyy-MM-dd HH:mm');

      expect(displayList, [
        'p1',
        'Display Plan',
        'strategic',
        '', '', '', '', // Optionals start/end/dep/prog
        'Completed', // Status
        '', '', '', // Optionals goal/miles/res
        expectedDateFormat.format(plan.createdAt),
        expectedDateFormat.format(plan.updatedAt),
      ]);
    });
  });

  group('Obstacle Tests', () {
    final validObstacleRow = [
      d('obs-01'), // ID
      d(' Competitor Price Cut '), // Obstacle Description
      d('medium'), // Likelihood of Occurrence
      d('high'), // Potential Impact
      d(' Offer discounts, highlight value '), // Mitigation Strategies
      d(' Reduce non-essential spending '), // Contingency Plans
      d('market'), // Category
      d('Open'), // Status (String)
      d(' goal-increase-sales '), // Related Item
      d(' Sales Lead '), // Assigned To
      d('2024-08-15'), // Date Identified
      d(isoNow), // CreatedAt
      d(isoLater), // UpdatedAt
    ];

    final expectedObstacle = Obstacle(
      id: 'obs-01',
      obstacleDescription: 'Competitor Price Cut',
      likelihoodOfOccurrence: Likelihood.medium,
      potentialImpact: Impact.high,
      mitigationStrategies: 'Offer discounts, highlight value',
      contingencyPlans: 'Reduce non-essential spending',
      category: ObstacleCategory.market,
      status: 'Open',
      // String status
      relatedItem: 'goal-increase-sales',
      assignedTo: 'Sales Lead',
      dateIdentified: '2024-08-15',
      createdAt: DateTime.parse(isoNow),
      updatedAt: DateTime.parse(isoLater),
    );

    test('sheetName returns correct constant', () {
      expect(expectedObstacle.sheetName, ExcelConstants.sheetObstacles);
    });

    test('headers returns correct constant list', () {
      expect(expectedObstacle.headers, ExcelConstants.headersObstacles);
      expect(Obstacle.displayHeaders, ExcelConstants.headersObstacles);
    });

    test('toRowData converts object to correct CellValue list', () {
      final obstacle = Obstacle(
        id: 'o1',
        obstacleDescription: 'Obstacle Desc',
        likelihoodOfOccurrence: Likelihood.low,
        potentialImpact: Impact.low,
        category: ObstacleCategory.technical,
        status: 'Resolved',
        createdAt: now,
        updatedAt: now,
      );
      final rowData = obstacle.toRowData();

      expect(rowData.length, ExcelConstants.headersObstacles.length);
      expect(rowData[0],
          isA<TextCellValue>().having((c) => c.toString(), 'toString()', 'o1'));
      expect(
          rowData[1],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'Obstacle Desc'));
      expect(
          rowData[2],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'low')); // Likelihood
      expect(
          rowData[3],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', 'low')); // Impact
      expect(rowData[4], isNull); // mitigation
      expect(rowData[5], isNull); // contingency
      expect(
          rowData[6],
          isA<TextCellValue>().having(
              (c) => c.toString(), 'toString()', 'technical')); // Category
      expect(
          rowData[7],
          isA<TextCellValue>().having((c) => c.toString(), 'toString()',
              'Resolved')); // Status (String)
      expect(rowData[8], isNull);
      expect(rowData[9], isNull);
      expect(rowData[10], isNull);
      expect(
          rowData[11],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', isoNow));
      expect(
          rowData[12],
          isA<TextCellValue>()
              .having((c) => c.toString(), 'toString()', isoNow));
    });

    test('fromRow creates instance from valid data', () {
      final obstacle = Obstacle.fromRow(validObstacleRow);

      expect(obstacle.id, expectedObstacle.id);
      expect(
          obstacle.obstacleDescription, expectedObstacle.obstacleDescription);
      expect(obstacle.likelihoodOfOccurrence,
          expectedObstacle.likelihoodOfOccurrence);
      expect(obstacle.potentialImpact, expectedObstacle.potentialImpact);
      expect(
          obstacle.mitigationStrategies, expectedObstacle.mitigationStrategies);
      expect(obstacle.contingencyPlans, expectedObstacle.contingencyPlans);
      expect(obstacle.category, expectedObstacle.category);
      expect(obstacle.status, expectedObstacle.status); // String status
      expect(obstacle.relatedItem, expectedObstacle.relatedItem);
      expect(obstacle.assignedTo, expectedObstacle.assignedTo);
      expect(obstacle.dateIdentified, expectedObstacle.dateIdentified);
      expect(obstacle.createdAt.isAtSameMomentAs(expectedObstacle.createdAt),
          isTrue);
      expect(obstacle.updatedAt.isAtSameMomentAs(expectedObstacle.updatedAt),
          isTrue);
    });

    test('fromRow handles optional enums and strings being null', () {
      final minimalObstacleRow = [
        d('obs-min'), // ID
        d('Minimal Obs'), // Description
        null, null, null, null, null, null, null, null, null, // All optionals
        d(isoNow), // CreatedAt
        d(isoNow), // UpdatedAt
      ];
      final obstacle = Obstacle.fromRow(minimalObstacleRow);

      expect(obstacle.id, 'obs-min');
      expect(obstacle.obstacleDescription, 'Minimal Obs');
      expect(obstacle.likelihoodOfOccurrence, isNull);
      expect(obstacle.potentialImpact, isNull);
      expect(obstacle.mitigationStrategies, isNull);
      expect(obstacle.contingencyPlans, isNull);
      expect(obstacle.category, isNull);
      expect(obstacle.status, isNull);
      expect(obstacle.relatedItem, isNull);
      expect(obstacle.assignedTo, isNull);
      expect(obstacle.dateIdentified, isNull);
      expect(
          obstacle.createdAt.isAtSameMomentAs(DateTime.parse(isoNow)), isTrue);
      expect(
          obstacle.updatedAt.isAtSameMomentAs(DateTime.parse(isoNow)), isTrue);
    });

    test('fromRow throws FormatException for missing required fields', () {
      final testDataMissingId = List<Data?>.from(validObstacleRow)
        ..removeAt(0)
        ..insert(0, null);
      expect(() => Obstacle.fromRow(testDataMissingId), throwsFormatException);

      final testDataMissingDesc = List<Data?>.from(validObstacleRow)
        ..removeAt(1)
        ..insert(1, null);
      expect(
          () => Obstacle.fromRow(testDataMissingDesc), throwsFormatException);
      // Note: No other fields are strictly required by the Obstacle factory beyond ID and Description
    });

    test('toListForDisplay returns correct string list', () {
      final obstacle = Obstacle(
        id: 'o1',
        obstacleDescription: 'Display Obstacle',
        category: ObstacleCategory.resource,
        status: 'Monitoring',
        createdAt: DateTime(2023, 4, 1, 16, 0),
        updatedAt: DateTime(2023, 4, 2, 17, 0),
      );
      final displayList = obstacle.toListForDisplay();
      final expectedDateFormat = DateFormat('yyyy-MM-dd HH:mm');

      expect(displayList, [
        'o1',
        'Display Obstacle',
        '', '', '', '', // Optional enums/strings
        'resource', // Category
        'Monitoring', // Status
        '', '', '', // Optionals related/assigned/dateId
        expectedDateFormat.format(obstacle.createdAt),
        expectedDateFormat.format(obstacle.updatedAt),
      ]);
    });
  });
} // End main
