/// Helper functions for working with enums.
class EnumHelpers {
  /// Tries to parse an enum value from a string, case-insensitively.
  /// Returns null if the value is not found or input is null/empty.
  static T? tryParseEnum<T extends Enum>(List<T> enumValues, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final String lowerValue = value.toLowerCase().trim();
    for (final T enumValue in enumValues) {
      if (enumValue.name.toLowerCase() == lowerValue) {
        return enumValue;
      }
    }
    return null; // Not found
  }

  /// Gets a formatted string listing all possible enum values.
  static String getEnumValuesAsString<T extends Enum>(List<T> enumValues) {
    return enumValues.map((e) => e.name).join(', ');
  }
}
