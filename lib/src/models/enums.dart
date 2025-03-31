import '../utils/enum_helpers.dart';

enum Priority { high, medium, low }
enum TaskStatus { toDo, inProgress, blocked, done }
enum GoalStatus { notStarted, planning, inProgress, achieved }
enum PlanType { strategic, tactical, operational }
enum Likelihood { high, medium, low }
enum Impact { high, medium, low }
enum ObstacleCategory { technical, resource, market, behavioral, communication, financial }

extension PriorityExtension on Priority {
  String get description {
    switch (this) {
      case Priority.high: return 'Critical tasks needing immediate attention';
      case Priority.medium: return 'Important tasks to be addressed soon';
      case Priority.low: return 'Less critical tasks for later';
    }
  }
  static Priority? tryParse(String? value) => EnumHelpers.tryParseEnum(Priority.values, value);
  static String get allowedValuesString => EnumHelpers.getEnumValuesAsString(Priority.values);
  /// Returns a list of enum names as strings. Used for argParser allowed values.
  static List<String> get names => Priority.values.map((e) => e.name).toList();
}

extension TaskStatusExtension on TaskStatus {
  String get description {
    switch (this) {
      case TaskStatus.toDo: return 'Task not yet started';
      case TaskStatus.inProgress: return 'Task currently being worked on';
      case TaskStatus.blocked: return 'Task progress halted';
      case TaskStatus.done: return 'Task completed';
    }
  }
  static TaskStatus? tryParse(String? value) => EnumHelpers.tryParseEnum(TaskStatus.values, value);
  static String get allowedValuesString => EnumHelpers.getEnumValuesAsString(TaskStatus.values);
  /// Returns a list of enum names as strings. Used for argParser allowed values.
  static List<String> get names => TaskStatus.values.map((e) => e.name).toList();
}

extension GoalStatusExtension on GoalStatus {
  String get description {
    switch (this) {
      case GoalStatus.notStarted: return 'Goal not yet initiated';
      case GoalStatus.planning: return 'Goal in the planning stage';
      case GoalStatus.inProgress: return 'Goal currently being worked on';
      case GoalStatus.achieved: return 'Goal successfully completed';
    }
  }
  static GoalStatus? tryParse(String? value) => EnumHelpers.tryParseEnum(GoalStatus.values, value);
  static String get allowedValuesString => EnumHelpers.getEnumValuesAsString(GoalStatus.values);
  /// Returns a list of enum names as strings. Used for argParser allowed values.
  static List<String> get names => GoalStatus.values.map((e) => e.name).toList();
}

extension PlanTypeExtension on PlanType {
  String get description {
    switch (this) {
      case PlanType.strategic: return 'High-level, long-term plan';
      case PlanType.tactical: return 'Mid-level plan to achieve strategic goals';
      case PlanType.operational: return 'Low-level, day-to-day action plan';
    }
  }
  static PlanType? tryParse(String? value) => EnumHelpers.tryParseEnum(PlanType.values, value);
  static String get allowedValuesString => EnumHelpers.getEnumValuesAsString(PlanType.values);
  /// Returns a list of enum names as strings. Used for argParser allowed values.
  static List<String> get names => PlanType.values.map((e) => e.name).toList();
}

extension LikelihoodExtension on Likelihood {
  String get description {
    switch (this) {
      case Likelihood.high: return 'Very likely to occur';
      case Likelihood.medium: return 'Moderately likely to occur';
      case Likelihood.low: return 'Not very likely to occur';
    }
  }
  static Likelihood? tryParse(String? value) => EnumHelpers.tryParseEnum(Likelihood.values, value);
  static String get allowedValuesString => EnumHelpers.getEnumValuesAsString(Likelihood.values);
  /// Returns a list of enum names as strings. Used for argParser allowed values.
  static List<String> get names => Likelihood.values.map((e) => e.name).toList();
}

extension ImpactExtension on Impact {
  String get description {
    switch (this) {
      case Impact.high: return 'Significant negative consequences';
      case Impact.medium: return 'Moderate negative consequences';
      case Impact.low: return 'Minor negative consequences';
    }
  }
  static Impact? tryParse(String? value) => EnumHelpers.tryParseEnum(Impact.values, value);
  static String get allowedValuesString => EnumHelpers.getEnumValuesAsString(Impact.values);
  /// Returns a list of enum names as strings. Used for argParser allowed values.
  static List<String> get names => Impact.values.map((e) => e.name).toList();
}

extension ObstacleCategoryExtension on ObstacleCategory {
  String get description {
    switch (this) {
      case ObstacleCategory.technical: return 'Issues related to technology';
      case ObstacleCategory.resource: return 'Lack of necessary resources';
      case ObstacleCategory.market: return 'Challenges from the market';
      case ObstacleCategory.behavioral: return 'Issues related to team or individual behavior';
      case ObstacleCategory.communication: return 'Issues related to information flow';
      case ObstacleCategory.financial: return 'Issues related to budget or funding';
    }
  }
  static ObstacleCategory? tryParse(String? value) => EnumHelpers.tryParseEnum(ObstacleCategory.values, value);
  static String get allowedValuesString => EnumHelpers.getEnumValuesAsString(ObstacleCategory.values);
  /// Returns a list of enum names as strings. Used for argParser allowed values.
  static List<String> get names => ObstacleCategory.values.map((e) => e.name).toList();
}