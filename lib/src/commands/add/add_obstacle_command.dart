import 'package:args/command_runner.dart';
import 'package:uuid/uuid.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/excel_service.dart';
import '../../utils/input_utils.dart';

class AddObstacleCommand extends Command<void> {
  @override
  final String name = 'obstacle';
  @override
  final String description = 'Adds a new obstacle.';
  @override
  String get invocation => '${runner?.executableName} add obstacle [arguments]';

  final ExcelService _excelService;
  final bool interactive;

  AddObstacleCommand(
      {required ExcelService excelService, this.interactive = false})
      : _excelService = excelService {
    // --- Define Arguments ---
    // Mandatory
    argParser.addOption('title',
        abbr: 't',
        help: '(Required) What is the obstacle?',
        valueHelp: 'OBSTACLE_TITLE');

    // Optional
    argParser.addOption('likelihood',
        abbr: 'l',
        help:
            'How likely is this obstacle to occur? \nAllowed: [${LikelihoodExtension.allowedValuesString}]',
        valueHelp: 'LIKELIHOOD',
        allowed: LikelihoodExtension.names,
        allowedHelp: Map.fromEntries(
            Likelihood.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('impact',
        abbr: 'i',
        help:
            'What could be the potential impact? \nAllowed: [${ImpactExtension.allowedValuesString}]',
        valueHelp: 'IMPACT',
        allowed: ImpactExtension.names,
        allowedHelp: Map.fromEntries(
            Impact.values.map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('mitigation',
        help: 'What steps can be taken to prevent or reduce this obstacle?',
        valueHelp: 'STRATEGIES');
    argParser.addOption('contingency',
        help: 'What will you do if this obstacle occurs?', valueHelp: 'PLANS');
    argParser.addOption('category',
        abbr: 'c',
        help:
            'What type of obstacle is this? \nAllowed: [${ObstacleCategoryExtension.allowedValuesString}]',
        valueHelp: 'CATEGORY',
        allowed: ObstacleCategoryExtension.names,
        allowedHelp: Map.fromEntries(ObstacleCategory.values
            .map((e) => MapEntry(e.name, e.description))));
    argParser.addOption('status',
        abbr: 's',
        help: 'What is the current status? (e.g., Open, Resolved)',
        valueHelp: 'STATUS_TEXT');
    argParser.addOption('related-to',
        help: 'Which goal, task, or plan is this related to? (Item Title)',
        valueHelp: 'ITEM_TITLE');
    argParser.addOption('assigned-to',
        help: 'Who is responsible for monitoring or addressing this?',
        valueHelp: 'PERSON_NAME');
    argParser.addOption('date-identified',
        help: 'When was this obstacle identified? (YYYY-MM-DD)',
        valueHelp: 'YYYY-MM-DD');
  }

  @override
  Future<void> run() async {
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

    // --- Interactive Mode ---
    if (interactive) {
      print('\n--- Adding New Obstacle ---');
      title = InputUtils.prompt('What is the obstacle?',
          isRequired: true, currentValue: title);
      likelihoodStr = InputUtils.promptEnum<Likelihood>(
          'Likelihood of occurrence? (${LikelihoodExtension.allowedValuesString}) (Optional):',
          Likelihood.values,
          currentValue: likelihoodStr);
      impactStr = InputUtils.promptEnum<Impact>(
          'Potential impact? (${ImpactExtension.allowedValuesString}) (Optional):',
          Impact.values,
          currentValue: impactStr);
      mitigation = InputUtils.prompt('Mitigation strategies? (Optional):',
          currentValue: mitigation);
      contingency = InputUtils.prompt('Contingency plans? (Optional):',
          currentValue: contingency);
      categoryStr = InputUtils.promptEnum<ObstacleCategory>(
          'Category? (${ObstacleCategoryExtension.allowedValuesString}) (Optional):',
          ObstacleCategory.values,
          currentValue: categoryStr);
      status = InputUtils.prompt('Current status? (e.g., Open) (Optional):',
          currentValue: status);
      relatedTo = InputUtils.prompt('Related to which item title? (Optional):',
          currentValue: relatedTo);
      assignedTo = InputUtils.prompt('Assigned to whom? (Optional):',
          currentValue: assignedTo);
      dateIdentified = InputUtils.prompt(
          'Date identified? (YYYY-MM-DD) (Optional):',
          validator: InputUtils.isValidDate,
          validationError: 'Invalid date format.',
          currentValue: dateIdentified);
      print('--------------------------\n');
    }

    // --- Validation ---
    if (title == null || title.isEmpty) {
      throw UsageException(
          'Obstacle title (--title or -t) is required.', usage);
    }
    final likelihood = LikelihoodExtension.tryParse(likelihoodStr);
    if (likelihoodStr != null &&
        likelihoodStr.isNotEmpty &&
        likelihood == null) {
      throw UsageException(
          'Invalid likelihood value: "$likelihoodStr". Allowed: ${LikelihoodExtension.allowedValuesString}',
          usage);
    }
    final impact = ImpactExtension.tryParse(impactStr);
    if (impactStr != null && impactStr.isNotEmpty && impact == null) {
      throw UsageException(
          'Invalid impact value: "$impactStr". Allowed: ${ImpactExtension.allowedValuesString}',
          usage);
    }
    final category = ObstacleCategoryExtension.tryParse(categoryStr);
    if (categoryStr != null && categoryStr.isNotEmpty && category == null) {
      throw UsageException(
          'Invalid category value: "$categoryStr". Allowed: ${ObstacleCategoryExtension.allowedValuesString}',
          usage);
    }
    if (dateIdentified != null &&
        dateIdentified.isNotEmpty &&
        !InputUtils.isValidDate(dateIdentified)) {
      throw UsageException(
          'Invalid date identified format: "$dateIdentified". Use YYYY-MM-DD.',
          usage);
    }

    // --- Create and Save ---
    final newObstacle = Obstacle(
      id: const Uuid().v4(),
      obstacleDescription: title, // Map title argument to model field
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

    try {
      final addedId = await _excelService.addItem<Obstacle>(newObstacle);
      print('✅ Obstacle added successfully with ID: $addedId');
    } catch (e) {
      print(
          '❌ Error adding obstacle to Excel file "${_excelService.filePath}": $e');
    }
  }
}
