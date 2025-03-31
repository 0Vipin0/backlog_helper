import 'package:args/command_runner.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/input_utils.dart';

class UpdateObstacleCommand extends Command<void> {
  @override
  final String name = 'obstacle';
  @override
  final String description = 'Updates an existing obstacle.';
  @override
  String get invocation => '${runner?.executableName} update obstacle --id <OBSTACLE_ID> [arguments]';

  final ExcelService _excelService;
  final bool interactive;

  UpdateObstacleCommand({required ExcelService excelService, this.interactive = false})
      : _excelService = excelService {
    // --- Define Arguments ---
    argParser.addOption('id', abbr: 'i', help: 'The unique ID of the obstacle to update (Required).', valueHelp: 'OBSTACLE_ID');

    // Optional update fields
    argParser.addOption('title', abbr: 't', help: 'New obstacle title.', valueHelp: 'OBSTACLE_TITLE');
    argParser.addOption('likelihood', abbr: 'l', help: 'New likelihood. Allowed: [${LikelihoodExtension.allowedValuesString}]', valueHelp: 'LIKELIHOOD', allowed: LikelihoodExtension.names, allowedHelp: Map.fromEntries(Likelihood.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('impact', abbr: 'm', help: 'New potential impact. Allowed: [${ImpactExtension.allowedValuesString}]', valueHelp: 'IMPACT', allowed: ImpactExtension.names, allowedHelp: Map.fromEntries(Impact.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('mitigation', help: 'New mitigation strategies.', valueHelp: 'STRATEGIES');
    argParser.addOption('contingency', help: 'New contingency plans.', valueHelp: 'PLANS');
    argParser.addOption('category', abbr: 'c', help: 'New category. Allowed: [${ObstacleCategoryExtension.allowedValuesString}]', valueHelp: 'CATEGORY', allowed: ObstacleCategoryExtension.names, allowedHelp: Map.fromEntries(ObstacleCategory.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('status', abbr:'s', help: 'New status text (e.g., Under Review).', valueHelp: 'STATUS_TEXT');
    argParser.addOption('related-to', help: 'New related item title.', valueHelp: 'ITEM_TITLE');
    argParser.addOption('assigned-to', help: 'New assigned person.', valueHelp: 'PERSON_NAME');
    argParser.addOption('date-identified', help: 'New identified date (YYYY-MM-DD).', valueHelp: 'YYYY-MM-DD');

     // Clear flags for optional fields
     argParser.addFlag('clear-likelihood', help: 'Set likelihood to empty.', negatable: false);
     argParser.addFlag('clear-impact', help: 'Set impact to empty.', negatable: false);
     argParser.addFlag('clear-mitigation', help: 'Set mitigation strategies to empty.', negatable: false);
     argParser.addFlag('clear-contingency', help: 'Set contingency plans to empty.', negatable: false);
     argParser.addFlag('clear-category', help: 'Set category to empty.', negatable: false);
     argParser.addFlag('clear-status', help: 'Set status text to empty.', negatable: false);
     argParser.addFlag('clear-related-to', help: 'Set related item to empty.', negatable: false);
     argParser.addFlag('clear-assigned-to', help: 'Set assigned person to empty.', negatable: false);
     argParser.addFlag('clear-date-identified', help: 'Set identified date to empty.', negatable: false);
 }

   @override
  Future<void> run() async {
    String? id = argResults?['id'];

    if (interactive && (id == null || id.isEmpty)) {
      id = InputUtils.prompt('Enter the ID of the obstacle to update:', isRequired: true);
    }
    if (id == null || id.isEmpty) {
      throw UsageException('Obstacle ID (--id or -i) is required for update.', usage);
    }

    Obstacle? existingObstacle;
    try {
      existingObstacle = await _excelService.getItemById<Obstacle>(id, Obstacle.fromRow);
    } catch (e) {
       print('❌ Error fetching obstacle with ID "$id": $e');
       return;
    }

    if (existingObstacle == null) {
      print('❌ Obstacle with ID "$id" not found.');
      return;
    }

    print('🔄 Updating Obstacle: ${existingObstacle.obstacleDescription} (ID: $id)');

    // --- Gather Updated Values ---
    String? title = argResults?['title'];
    String? likelihoodStr = argResults?['likelihood'];
    String? impactStr = argResults?['impact'];
    String? mitigation = argResults?['mitigation'];
    String? contingency = argResults?['contingency'];
    String? categoryStr = argResults?['category'];
    String? status = argResults?['status'];
    String? relatedTo = argResults?['related-to'];
    String? assignedTo = argResults?['assigned-to'];
    String? dateIdentified = argResults?['date-identified'];

    if (interactive) {
      print('\nEnter new values or press Enter to keep current.');
      title = InputUtils.prompt('Obstacle Title', isRequired: true, currentValue: existingObstacle.obstacleDescription);
      likelihoodStr = InputUtils.promptEnum<Likelihood>('Likelihood (${LikelihoodExtension.allowedValuesString})', Likelihood.values, currentValue: existingObstacle.likelihoodOfOccurrence?.name);
      impactStr = InputUtils.promptEnum<Impact>('Impact (${ImpactExtension.allowedValuesString})', Impact.values, currentValue: existingObstacle.potentialImpact?.name);
      mitigation = InputUtils.prompt('Mitigation Strategies', currentValue: existingObstacle.mitigationStrategies);
      contingency = InputUtils.prompt('Contingency Plans', currentValue: existingObstacle.contingencyPlans);
      categoryStr = InputUtils.promptEnum<ObstacleCategory>('Category (${ObstacleCategoryExtension.allowedValuesString})', ObstacleCategory.values, currentValue: existingObstacle.category?.name);
      status = InputUtils.prompt('Status Text', currentValue: existingObstacle.status);
      relatedTo = InputUtils.prompt('Related Item Title', currentValue: existingObstacle.relatedItem);
      assignedTo = InputUtils.prompt('Assigned To', currentValue: existingObstacle.assignedTo);
      dateIdentified = InputUtils.prompt('Date Identified (YYYY-MM-DD)', validator: InputUtils.isValidDate, validationError: 'Invalid date format.', currentValue: existingObstacle.dateIdentified);
       print('--------------------------\n');
    }

    // --- Apply Non-Interactive Args & Validate ---
    title ??= existingObstacle.obstacleDescription;
    likelihoodStr = argResults?.wasParsed('clear-likelihood') ?? false ? null : (likelihoodStr ?? existingObstacle.likelihoodOfOccurrence?.name);
    impactStr = argResults?.wasParsed('clear-impact') ?? false ? null : (impactStr ?? existingObstacle.potentialImpact?.name);
    mitigation = argResults?.wasParsed('clear-mitigation') ?? false ? null : (mitigation ?? existingObstacle.mitigationStrategies);
    contingency = argResults?.wasParsed('clear-contingency') ?? false ? null : (contingency ?? existingObstacle.contingencyPlans);
    categoryStr = argResults?.wasParsed('clear-category') ?? false ? null : (categoryStr ?? existingObstacle.category?.name);
    status = argResults?.wasParsed('clear-status') ?? false ? null : (status ?? existingObstacle.status);
    relatedTo = argResults?.wasParsed('clear-related-to') ?? false ? null : (relatedTo ?? existingObstacle.relatedItem);
    assignedTo = argResults?.wasParsed('clear-assigned-to') ?? false ? null : (assignedTo ?? existingObstacle.assignedTo);
    dateIdentified = argResults?.wasParsed('clear-date-identified') ?? false ? null : (dateIdentified ?? existingObstacle.dateIdentified);


    // Re-validate
     if (title.isEmpty) {
        throw UsageException('Obstacle title cannot be empty.', usage);
    }
    final likelihood = LikelihoodExtension.tryParse(likelihoodStr);
    if (likelihoodStr != null && likelihoodStr.isNotEmpty && likelihood == null) {
       throw UsageException('Invalid likelihood value: "$likelihoodStr". Allowed: ${LikelihoodExtension.allowedValuesString}', usage);
    }
    final impact = ImpactExtension.tryParse(impactStr);
     if (impactStr != null && impactStr.isNotEmpty && impact == null) {
       throw UsageException('Invalid impact value: "$impactStr". Allowed: ${ImpactExtension.allowedValuesString}', usage);
    }
    final category = ObstacleCategoryExtension.tryParse(categoryStr);
    if (categoryStr != null && categoryStr.isNotEmpty && category == null) {
       throw UsageException('Invalid category value: "$categoryStr". Allowed: ${ObstacleCategoryExtension.allowedValuesString}', usage);
    }
     if (dateIdentified != null && dateIdentified.isNotEmpty && !InputUtils.isValidDate(dateIdentified)) {
       throw UsageException('Invalid date identified format: "$dateIdentified". Use YYYY-MM-DD.', usage);
     }

    // --- Create Updated Obstacle Object ---
    final updatedObstacle = Obstacle(
      id: existingObstacle.id,
      createdAt: existingObstacle.createdAt, // Preserve creation date
      obstacleDescription: title,
      likelihoodOfOccurrence: likelihood,
      potentialImpact: impact,
      mitigationStrategies: mitigation,
      contingencyPlans: contingency,
      category: category,
      status: status,
      relatedItem: relatedTo,
      assignedTo: assignedTo,
      dateIdentified: dateIdentified,
    );

    // --- Save Update ---
    try {
      final success = await _excelService.updateItem<Obstacle>(updatedObstacle);
      if (success) {
        print('✅ Obstacle with ID "$id" updated successfully.');
      }
    } catch (e) {
      print('❌ Error updating obstacle with ID "$id" in Excel file "${_excelService.filePath}": $e');
    }
  }
}
