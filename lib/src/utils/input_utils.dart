import 'dart:io';
import 'package:intl/intl.dart'; // For date display/validation
import 'enum_helpers.dart';

class InputUtils {
  /// Prompts the user for input.
  static String? prompt(String message,
      {bool isRequired = false,
      String? currentValue,
      bool Function(String)? validator,
      String? validationError}) {
    String? input;
    bool firstPrompt = true;
    String displayCurrent = currentValue != null && currentValue.isNotEmpty
        ? ' [Current: $currentValue]'
        : '';
    if (currentValue != null && currentValue.isNotEmpty && !isRequired) {
      displayCurrent += ' (Press Enter to keep)';
    }

    do {
      // Error messages
      if (!firstPrompt) {
        if (isRequired && (input == null || input.isEmpty)) {
          stdout.write('Input is required. ');
        } else if (validator != null &&
            input != null &&
            input.isNotEmpty &&
            !validator(input)) {
          stdout.write(validationError ?? 'Invalid input format. ');
        }
      }

      stdout.write('$message$displayCurrent: ');
      input = stdin.readLineSync()?.trim();
      firstPrompt = false;

      // Handle "Press Enter to keep" for optional fields during updates
      if (currentValue != null &&
          input != null &&
          input.isEmpty &&
          !isRequired) {
        return currentValue; // Keep the current value
      }
    } while ((isRequired && (input == null || input.isEmpty)) ||
        (validator != null &&
            input != null &&
            input.isNotEmpty &&
            !validator(input)));

    // Return null only if it was truly empty and not required
    return (input == null || input.isEmpty) ? null : input;
  }

  /// Prompts the user specifically for an enum value.
  static String? promptEnum<T extends Enum>(String message, List<T> enumValues,
      {bool isRequired = false, String? currentValue}) {
    String? input;
    bool firstPrompt = true;
    T? parsedEnum;
    String displayCurrent = currentValue != null && currentValue.isNotEmpty
        ? ' [Current: $currentValue]'
        : '';
    if (currentValue != null && currentValue.isNotEmpty && !isRequired) {
      displayCurrent += ' (Press Enter to keep)';
    }
    String allowedValues = EnumHelpers.getEnumValuesAsString(enumValues);

    do {
      if (!firstPrompt) {
        if (isRequired && (input == null || input.isEmpty)) {
          stdout.write('Input is required. ');
        } else if (input != null && input.isNotEmpty && parsedEnum == null) {
          stdout.write('Invalid value. Allowed: $allowedValues. ');
        }
      }

      stdout.write('$message$displayCurrent: ');
      input = stdin.readLineSync()?.trim();
      firstPrompt = false;

      // Handle "Press Enter to keep" for optional fields during updates
      if (currentValue != null &&
          input != null &&
          input.isEmpty &&
          !isRequired) {
        return currentValue; // Keep the current value string
      }

      if (input != null && input.isNotEmpty) {
        parsedEnum = EnumHelpers.tryParseEnum(enumValues, input);
      } else {
        parsedEnum = null; // Reset if input is empty
      }
    } while ((isRequired && (input == null || input.isEmpty)) ||
        (input != null && input.isNotEmpty && parsedEnum == null));

    // If we successfully parsed an enum, return the original valid input string.
    if (parsedEnum != null) {
      return input;
    }

    // If parsing failed (parsedEnum is null):
    // Check if the field was optional AND the input was effectively empty (null or '').
    // The 'Press Enter to keep current' case was handled earlier in the loop.
    if (!isRequired && (input == null || input.isEmpty)) {
      return null; // Explicitly return null for optional empty input that wasn't kept
    }

    // This path should ideally not be reached if the loop logic for required fields
    // is correct, but return null as a safe fallback for unexpected invalid states.
    return null;
  }

  /// Basic date validator (YYYY-MM-DD)
  static bool isValidDate(String? input) {
    if (input == null || input.isEmpty) {
      return true; // Allow empty optional dates
    }
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(input)) return false;
    try {
      // Use DateFormat for stricter parsing if needed, but DateTime.parse is usually ok
      DateFormat('yyyy-MM-dd').parseStrict(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Prompts for Yes/No confirmation
  static bool confirm(String message, {bool defaultValue = false}) {
    stdout.write('$message [y/N]: ');
    final input = stdin.readLineSync()?.trim().toLowerCase();
    return input == 'y' || input == 'yes';
  }
}
