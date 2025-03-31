import 'package:backlog_manager_excel/src/models/enums.dart';
import 'package:backlog_manager_excel/src/utils/enum_helpers.dart';
import 'package:test/test.dart';

void main() {
  group('EnumHelpers Tests', () {
    // Using Priority as a sample enum for helper tests
    const List<Priority> testValues = Priority.values;
    const String testNamesString = 'high, medium, low';

    test('tryParseEnum handles valid input (case-insensitive)', () {
      expect(EnumHelpers.tryParseEnum(testValues, 'high'), equals(Priority.high));
      expect(EnumHelpers.tryParseEnum(testValues, 'MEDIUM'), equals(Priority.medium));
      expect(EnumHelpers.tryParseEnum(testValues, 'lOw'), equals(Priority.low));
      expect(EnumHelpers.tryParseEnum(testValues, ' high '), equals(Priority.high)); // Handles whitespace
    });

    test('tryParseEnum returns null for invalid input', () {
      expect(EnumHelpers.tryParseEnum(testValues, 'unknown'), isNull);
      expect(EnumHelpers.tryParseEnum(testValues, 'h'), isNull);
    });

    test('tryParseEnum returns null for null, empty, or whitespace input', () {
      expect(EnumHelpers.tryParseEnum(testValues, null), isNull);
      expect(EnumHelpers.tryParseEnum(testValues, ''), isNull);
      expect(EnumHelpers.tryParseEnum(testValues, '   '), isNull);
    });

    test('getEnumValuesAsString returns correct comma-separated string', () {
      expect(EnumHelpers.getEnumValuesAsString(testValues), equals(testNamesString));
    });

    test('getEnumValuesAsString handles empty list', () {
      expect(EnumHelpers.getEnumValuesAsString(<Priority>[]), equals(''));
    });
  });


  group('Priority Tests', () {
    test('description returns correct strings', () {
      expect(Priority.high.description, 'Critical tasks needing immediate attention');
      expect(Priority.medium.description, 'Important tasks to be addressed soon');
      expect(Priority.low.description, 'Less critical tasks for later');
    });

    test('tryParse works correctly', () {
      expect(PriorityExtension.tryParse('high'), equals(Priority.high));
      expect(PriorityExtension.tryParse('MEDIUM'), equals(Priority.medium));
      expect(PriorityExtension.tryParse(' low '), equals(Priority.low));
      expect(PriorityExtension.tryParse('invalid'), isNull);
      expect(PriorityExtension.tryParse(null), isNull);
      expect(PriorityExtension.tryParse(''), isNull);
    });

    test('allowedValuesString returns correct string', () {
      expect(PriorityExtension.allowedValuesString, 'high, medium, low');
    });

    test('names returns correct list', () {
      expect(PriorityExtension.names, orderedEquals(['high', 'medium', 'low']));
    });
  });

  group('TaskStatus Tests', () {
    test('description returns correct strings', () {
      expect(TaskStatus.toDo.description, 'Task not yet started');
      expect(TaskStatus.inProgress.description, 'Task currently being worked on');
      expect(TaskStatus.blocked.description, 'Task progress halted');
      expect(TaskStatus.done.description, 'Task completed');
    });

    test('tryParse works correctly', () {
      expect(TaskStatusExtension.tryParse('toDo'), equals(TaskStatus.toDo));
      expect(TaskStatusExtension.tryParse('INPROGRESS'), equals(TaskStatus.inProgress));
      expect(TaskStatusExtension.tryParse(' blocked '), equals(TaskStatus.blocked));
      expect(TaskStatusExtension.tryParse('done'), equals(TaskStatus.done));
      expect(TaskStatusExtension.tryParse('invalid'), isNull);
      expect(TaskStatusExtension.tryParse(null), isNull);
    });

    test('allowedValuesString returns correct string', () {
      expect(TaskStatusExtension.allowedValuesString, 'toDo, inProgress, blocked, done');
    });

    test('names returns correct list', () {
      expect(TaskStatusExtension.names, orderedEquals(['toDo', 'inProgress', 'blocked', 'done']));
    });
  });

  group('GoalStatus Tests', () {
    test('description returns correct strings', () {
      expect(GoalStatus.notStarted.description, 'Goal not yet initiated');
      expect(GoalStatus.planning.description, 'Goal in the planning stage');
      expect(GoalStatus.inProgress.description, 'Goal currently being worked on');
      expect(GoalStatus.achieved.description, 'Goal successfully completed');
    });

    test('tryParse works correctly', () {
      expect(GoalStatusExtension.tryParse('notStarted'), equals(GoalStatus.notStarted));
      expect(GoalStatusExtension.tryParse('PLANNING'), equals(GoalStatus.planning));
      expect(GoalStatusExtension.tryParse(' inProgress '), equals(GoalStatus.inProgress));
      expect(GoalStatusExtension.tryParse('achieved'), equals(GoalStatus.achieved));
      expect(GoalStatusExtension.tryParse('invalid'), isNull);
      expect(GoalStatusExtension.tryParse(null), isNull);
    });

    test('allowedValuesString returns correct string', () {
      expect(GoalStatusExtension.allowedValuesString, 'notStarted, planning, inProgress, achieved');
    });

    test('names returns correct list', () {
      expect(GoalStatusExtension.names, orderedEquals(['notStarted', 'planning', 'inProgress', 'achieved']));
    });
  });

  group('PlanType Tests', () {
    test('description returns correct strings', () {
      expect(PlanType.strategic.description, 'High-level, long-term plan');
      expect(PlanType.tactical.description, 'Mid-level plan to achieve strategic goals');
      expect(PlanType.operational.description, 'Low-level, day-to-day action plan');
    });

    test('tryParse works correctly', () {
      expect(PlanTypeExtension.tryParse('strategic'), equals(PlanType.strategic));
      expect(PlanTypeExtension.tryParse('TACTICAL'), equals(PlanType.tactical));
      expect(PlanTypeExtension.tryParse(' operational '), equals(PlanType.operational));
      expect(PlanTypeExtension.tryParse('invalid'), isNull);
      expect(PlanTypeExtension.tryParse(null), isNull);
    });

    test('allowedValuesString returns correct string', () {
      expect(PlanTypeExtension.allowedValuesString, 'strategic, tactical, operational');
    });

    test('names returns correct list', () {
      expect(PlanTypeExtension.names, orderedEquals(['strategic', 'tactical', 'operational']));
    });
  });

  group('Likelihood Tests', () {
    test('description returns correct strings', () {
      expect(Likelihood.high.description, 'Very likely to occur');
      expect(Likelihood.medium.description, 'Moderately likely to occur');
      expect(Likelihood.low.description, 'Not very likely to occur');
    });

    test('tryParse works correctly', () {
      expect(LikelihoodExtension.tryParse('high'), equals(Likelihood.high));
      expect(LikelihoodExtension.tryParse('MEDIUM'), equals(Likelihood.medium));
      expect(LikelihoodExtension.tryParse(' low '), equals(Likelihood.low));
      expect(LikelihoodExtension.tryParse('invalid'), isNull);
      expect(LikelihoodExtension.tryParse(null), isNull);
    });

    test('allowedValuesString returns correct string', () {
      expect(LikelihoodExtension.allowedValuesString, 'high, medium, low');
    });

    test('names returns correct list', () {
      expect(LikelihoodExtension.names, orderedEquals(['high', 'medium', 'low']));
    });
  });

  group('Impact Tests', () {
    test('description returns correct strings', () {
      expect(Impact.high.description, 'Significant negative consequences');
      expect(Impact.medium.description, 'Moderate negative consequences');
      expect(Impact.low.description, 'Minor negative consequences');
    });

    test('tryParse works correctly', () {
      expect(ImpactExtension.tryParse('high'), equals(Impact.high));
      expect(ImpactExtension.tryParse('MEDIUM'), equals(Impact.medium));
      expect(ImpactExtension.tryParse(' low '), equals(Impact.low));
      expect(ImpactExtension.tryParse('invalid'), isNull);
      expect(ImpactExtension.tryParse(null), isNull);
    });

    test('allowedValuesString returns correct string', () {
      expect(ImpactExtension.allowedValuesString, 'high, medium, low');
    });

    test('names returns correct list', () {
      expect(ImpactExtension.names, orderedEquals(['high', 'medium', 'low']));
    });
  });

  group('ObstacleCategory Tests', () {
    test('description returns correct strings', () {
      expect(ObstacleCategory.technical.description, 'Issues related to technology');
      expect(ObstacleCategory.resource.description, 'Lack of necessary resources');
      expect(ObstacleCategory.market.description, 'Challenges from the market');
      expect(ObstacleCategory.behavioral.description, 'Issues related to team or individual behavior');
      expect(ObstacleCategory.communication.description, 'Issues related to information flow');
      expect(ObstacleCategory.financial.description, 'Issues related to budget or funding');
    });

    test('tryParse works correctly', () {
      expect(ObstacleCategoryExtension.tryParse('technical'), equals(ObstacleCategory.technical));
      expect(ObstacleCategoryExtension.tryParse('RESOURCE'), equals(ObstacleCategory.resource));
      expect(ObstacleCategoryExtension.tryParse(' market '), equals(ObstacleCategory.market));
      expect(ObstacleCategoryExtension.tryParse('behavioral'), equals(ObstacleCategory.behavioral));
      expect(ObstacleCategoryExtension.tryParse('communication'), equals(ObstacleCategory.communication));
      expect(ObstacleCategoryExtension.tryParse('FINANCIAL'), equals(ObstacleCategory.financial));
      expect(ObstacleCategoryExtension.tryParse('invalid'), isNull);
      expect(ObstacleCategoryExtension.tryParse(null), isNull);
    });

    test('allowedValuesString returns correct string', () {
      expect(ObstacleCategoryExtension.allowedValuesString, 'technical, resource, market, behavioral, communication, financial');
    });

    test('names returns correct list', () {
      expect(ObstacleCategoryExtension.names, orderedEquals(['technical', 'resource', 'market', 'behavioral', 'communication', 'financial']));
    });
  });
}