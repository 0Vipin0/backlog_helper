class ExcelConstants {
  static const String defaultFilename = 'project_data.xlsx';

  // Sheet Names (Must match model types for simplicity in service)
  static const String sheetTasks = 'BacklogTasks';
  static const String sheetGoals = 'FutureGoals';
  static const String sheetPlans = 'PlanningItems';
  static const String sheetObstacles = 'Obstacles';

  // Common Columns (Must be first for consistency)
  static const String colId = 'ID';
  static const String colCreatedAt = 'CreatedAt';
  static const String colUpdatedAt = 'UpdatedAt';

  // --- Headers for each sheet ---
  // Order matters! Must match the order in `toRowData` and `fromRow`

  static const List<String> headersTasks = [
    colId,
    'Task Title',          // taskTitle (Mandatory)
    'Description',         // description
    'Priority',            // priority (Mandatory, Enum)
    'Estimated Effort',    // estimatedEffort
    'Status',              // status (Enum)
    'Due Date',            // dueDate (YYYY-MM-DD)
    'Tags/Categories',     // tagsCategories
    'Dependencies',        // dependencies (Task Titles)
    'Reasoning',           // reasoning (Goal/Plan Title)
    'Resolution',          // resolution
    colCreatedAt,          // Auto
    colUpdatedAt,          // Auto
  ];

  static const List<String> headersGoals = [
    colId,
    'Goal Title',          // goalDescription (Mandatory) - Mapped from goalDescription
    'Target Completion Date', // targetCompletionDate (Mandatory, YYYY-MM-DD)
    'Priority',            // priority (Mandatory, Enum)
    'KPIs',                // kpis
    'Resources Required',  // resourcesRequired
    'Current Status',      // currentStatus (Enum)
    'Motivation',          // motivation
    'First Step',          // firstStep (Task Title)
    'Potential Challenges',// potentialChallenges (Obstacle Titles)
    'Support Contacts',    // supportContacts
    colCreatedAt,          // Auto
    colUpdatedAt,          // Auto
  ];

  static const List<String> headersPlans = [
    colId,
    'Plan Title',          // planItemDescription (Mandatory) - Mapped from planItemDescription
    'Type of Plan',        // typeOfPlan (Mandatory, Enum)
    'Start Date',          // startDate (YYYY-MM-DD)
    'End Date',            // endDate (YYYY-MM-DD)
    'Dependencies',        // dependencies (Plan Titles)
    'Progress',            // progress
    'Status',              // status (String: e.g., On Track, At Risk) (Mandatory)
    'Related Goal',        // relatedGoal (Goal Title)
    'Key Milestones',      // keyMilestones (Task Titles)
    'Allocated Resources', // allocatedResources
    colCreatedAt,          // Auto
    colUpdatedAt,          // Auto
  ];

  static const List<String> headersObstacles = [
    colId,
    'Obstacle Title',      // obstacleDescription (Mandatory) - Mapped from obstacleDescription
    'Likelihood',          // likelihoodOfOccurrence (Enum)
    'Impact',              // potentialImpact (Enum)
    'Mitigation Strategies', // mitigationStrategies
    'Contingency Plans',   // contingencyPlans
    'Category',            // category (Enum)
    'Status',              // status (String: e.g., Open, Resolved)
    'Related Item',        // relatedItem (Goal/Task/Plan Title)
    'Assigned To',         // assignedTo
    'Date Identified',     // dateIdentified (YYYY-MM-DD)
    colCreatedAt,          // Auto
    colUpdatedAt,          // Auto
  ];

  // Helper to get headers based on sheet name
  static List<String> getHeadersForSheet(String sheetName) {
    switch (sheetName) {
      case sheetTasks: return headersTasks;
      case sheetGoals: return headersGoals;
      case sheetPlans: return headersPlans;
      case sheetObstacles: return headersObstacles;
      default: throw ArgumentError('Unknown sheet name: $sheetName');
    }
  }
}
