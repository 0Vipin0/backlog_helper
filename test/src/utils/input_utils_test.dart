import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:backlog_helper/src/models/enums.dart';
import 'package:backlog_helper/src/utils/input_utils.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockStdin extends Mock implements Stdin {}

class MockStdout extends Mock implements Stdout {}

class FakeEncoding extends Fake implements Encoding {}

void main() {
  setUpAll(() {
    // Register a fallback value for the Encoding type.
    // systemEncoding is a sensible default provided by dart:io.
    // Alternatively, use utf8 from dart:convert.
    registerFallbackValue(systemEncoding);
    // Or: registerFallbackValue<Encoding>(utf8);

    // You could also use the Fake class if systemEncoding/utf8 weren't available
    // registerFallbackValue<Encoding>(FakeEncoding());
  });

  // Helper to run tests with IO Overrides
  Future<T> runWithOverrides<T>(
    FutureOr<T> Function() body, {
    required List<String?> inputs,
    required MockStdout mockStdout,
  }) {
    final mockStdin = MockStdin();

    // --- Setup for mocktail ---
    final inputIterator = inputs.iterator;
    // Now this `any(named: 'encoding')` call will work because a fallback is registered
    when(() => mockStdin.readLineSync(
          encoding: any(named: 'encoding'),
          retainNewlines: any(named: 'retainNewlines'),
        )).thenAnswer((_) {
      if (inputIterator.moveNext()) {
        return inputIterator.current;
      }
      return null;
    });

    final capturedOutput = StringBuffer();
    // Capture stdout writes using thenAnswer to avoid potential issues with void returns
    when(() => mockStdout.write(any())).thenAnswer((invocation) {
      final dynamic arg = invocation.positionalArguments.first;
      capturedOutput.write(arg); // Write the captured argument
    });
    // --- End setup for mocktail ---

    return IOOverrides.runZoned(
      () => Future<T>.value(body()),
      stdin: () => mockStdin,
      stdout: () => mockStdout,
    );
  }

  group('InputUtils Tests', () {
    late MockStdout mockStdout;

    setUp(() {
      mockStdout = MockStdout();
    });

    tearDown(() {
      resetMocktailState();
    });

    // ... rest of your test groups (prompt, promptEnum, etc.) remain the same ...
    // Group: prompt
    group('prompt', () {
      test('should return input when valid', () async {
        final inputs = ['valid input'];
        final result = await runWithOverrides(
          () => InputUtils.prompt('Enter value'),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('valid input'));
        verify(() => mockStdout.write('Enter value: ')).called(1);
      });

      test('should return null when optional and input is empty', () async {
        final inputs = [''];
        final result = await runWithOverrides(
          () => InputUtils.prompt('Enter optional value'),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isNull);
        verify(() => mockStdout.write('Enter optional value: ')).called(1);
      });

      test(
          'should return currentValue when optional, has current, and input is empty',
          () async {
        final inputs = ['']; // User presses Enter
        final result = await runWithOverrides(
          () => InputUtils.prompt('Enter value',
              currentValue: 'old', isRequired: false),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('old'));
        // Verify the specific prompt text
        verify(() => mockStdout.write(
            'Enter value [Current: old] (Press Enter to keep): ')).called(1);
      });

      test(
          'should return new value when optional, has current, and input is provided',
          () async {
        final inputs = ['new value'];
        final result = await runWithOverrides(
          () => InputUtils.prompt('Enter value',
              currentValue: 'old', isRequired: false),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('new value'));
        verify(() => mockStdout.write(
            'Enter value [Current: old] (Press Enter to keep): ')).called(1);
      });

      test('should re-prompt when required and input is empty first', () async {
        final inputs = ['', 'required input'];
        final result = await runWithOverrides(
          () => InputUtils.prompt('Enter required', isRequired: true),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('required input'));
        // Verify prompt called twice, verify error message
        verify(() => mockStdout.write('Enter required: ')).called(2);
        verify(() => mockStdout.write('Input is required. ')).called(1);
      });

      test('should re-prompt when required, has current, and input is empty',
          () async {
        // Note: For required fields, pressing Enter does NOT keep the current value
        final inputs = ['', 'new required'];
        final result = await runWithOverrides(
          () => InputUtils.prompt('Enter required',
              currentValue: 'current', isRequired: true),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('new required'));
        verify(() => mockStdout.write('Enter required [Current: current]: '))
            .called(2);
        verify(() => mockStdout.write('Input is required. ')).called(1);
      });

      test('should re-prompt with default validation error', () async {
        // Validator: s.length > 3
        // Inputs: First is invalid (len 3), second is valid (len 5)
        final inputs = ['inv', 'valid'];
        final result = await runWithOverrides(
          () => InputUtils.prompt('Enter >3 chars',
              validator: (s) => s.length > 3 // Validator check
              ),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        // Expect the *second* input because the first one failed validation
        expect(result, equals('valid'));
        // Verify it prompted twice
        verify(() => mockStdout.write('Enter >3 chars: ')).called(2);
        // Verify the error message was shown once
        verify(() => mockStdout.write('Invalid input format. ')).called(1);
      });

      test('should re-prompt with custom validation error', () async {
        // Validator: s == 'good'
        // Inputs: First is invalid ('bad'), second is valid ('good')
        final inputs = ['bad', 'good'];
        final result = await runWithOverrides(
          () => InputUtils.prompt(
            'Enter good/bad',
            validator: (s) => s == 'good', // Validator check
            validationError: 'Must be "good". ',
          ),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('good'));
        verify(() => mockStdout.write('Enter good/bad: ')).called(2);
        verify(() => mockStdout.write('Must be "good". ')).called(1);
      });

      test('should re-prompt with custom validation error', () async {
        final inputs = ['bad', 'good'];
        final result = await runWithOverrides(
          () => InputUtils.prompt(
            'Enter good/bad',
            validator: (s) => s == 'good',
            validationError: 'Must be "good". ',
          ),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('good'));
        verify(() => mockStdout.write('Enter good/bad: ')).called(2);
        verify(() => mockStdout.write('Must be "good". ')).called(1);
      });
      test('should handle validator correctly when input is empty and optional',
          () async {
        final inputs = ['']; // Empty input for an optional field
        final result = await runWithOverrides(
          () => InputUtils.prompt(
            'Enter optional number',
            validator: (s) =>
                int.tryParse(s) !=
                null, // Validator should not run on empty optional input
            isRequired: false,
            validationError: 'Not a number. ',
          ),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isNull); // Should return null for empty optional
        verify(() => mockStdout.write('Enter optional number: ')).called(1);
        // Ensure validation error was NOT printed
        verifyNever(() => mockStdout.write('Not a number. '));
      });
    });

    // Group: promptEnum
    group('promptEnum', () {
      // Use Priority as a sample enum
      const sampleEnum = Priority.values;
      const allowedStr = 'high, medium, low';

      test('should return valid enum input string', () async {
        final inputs = ['medium'];
        final result = await runWithOverrides(
          () => InputUtils.promptEnum('Select Priority', sampleEnum),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('medium'));
        verify(() => mockStdout.write('Select Priority: ')).called(1);
      });

      test('should return valid enum input string (case-insensitive)',
          () async {
        final inputs = ['HIGH'];
        final result = await runWithOverrides(
          () => InputUtils.promptEnum('Select Priority', sampleEnum),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('HIGH')); // Returns the original input string
        verify(() => mockStdout.write('Select Priority: ')).called(1);
      });

      test('should return null when optional and input is empty', () async {
        final inputs = [''];
        final result = await runWithOverrides(
          () => InputUtils.promptEnum('Select Priority', sampleEnum,
              isRequired: false),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isNull);
        verify(() => mockStdout.write('Select Priority: ')).called(1);
      });

      test(
          'should return currentValue when optional, has current, and input is empty',
          () async {
        final inputs = ['']; // User presses Enter
        final result = await runWithOverrides(
          () => InputUtils.promptEnum('Priority', sampleEnum,
              currentValue: 'low', isRequired: false),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('low'));
        verify(() => mockStdout.write(
            'Priority [Current: low] (Press Enter to keep): ')).called(1);
      });

      test('should re-prompt when required and input is empty first', () async {
        final inputs = ['', 'high'];
        final result = await runWithOverrides(
          () => InputUtils.promptEnum('Select Priority', sampleEnum,
              isRequired: true),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('high'));
        verify(() => mockStdout.write('Select Priority: ')).called(2);
        verify(() => mockStdout.write('Input is required. ')).called(1);
      });

      test('should re-prompt when input is invalid', () async {
        final inputs = ['invalid', 'medium'];
        final result = await runWithOverrides(
          () => InputUtils.promptEnum('Select Priority', sampleEnum),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('medium'));
        verify(() => mockStdout.write('Select Priority: ')).called(2);
        verify(() => mockStdout.write('Invalid value. Allowed: $allowedStr. '))
            .called(1);
      });

      test(
          'should handle required enum with current value correctly (re-prompts on empty)',
          () async {
        final inputs = [
          '',
          'high'
        ]; // Empty should re-prompt, not keep current for required
        final result = await runWithOverrides(
          () => InputUtils.promptEnum('Priority', sampleEnum,
              currentValue: 'medium', isRequired: true),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, equals('high'));
        verify(() => mockStdout.write('Priority [Current: medium]: '))
            .called(2);
        verify(() => mockStdout.write('Input is required. '))
            .called(1); // Required error first
      });
    });

    // Group: isValidDate
    group('isValidDate', () {
      test('should return true for valid YYYY-MM-DD', () {
        expect(InputUtils.isValidDate('2023-10-27'), isTrue);
        expect(InputUtils.isValidDate('2024-02-29'), isTrue); // Leap year
      });

      test('should return false for invalid format', () {
        expect(InputUtils.isValidDate('2023/10/27'), isFalse);
        expect(InputUtils.isValidDate('27-10-2023'), isFalse);
        expect(InputUtils.isValidDate('20231027'), isFalse);
        expect(InputUtils.isValidDate('abc'), isFalse);
        expect(InputUtils.isValidDate(' 2023-10-27 '), isFalse); // Extra spaces
      });

      test('should return false for invalid date values', () {
        expect(InputUtils.isValidDate('2023-13-01'), isFalse); // Invalid month
        expect(InputUtils.isValidDate('2023-00-01'), isFalse); // Invalid month
        expect(InputUtils.isValidDate('2023-12-32'), isFalse); // Invalid day
        expect(InputUtils.isValidDate('2023-02-29'), isFalse); // Non-leap year
        expect(
            InputUtils.isValidDate('2023-11-31'), isFalse); // Nov has 30 days
      });

      test(
          'should return true for null or empty (considered valid for optional)',
          () {
        expect(InputUtils.isValidDate(null), isTrue);
        expect(InputUtils.isValidDate(''), isTrue);
      });

      test('should return false for whitespace only string', () {
        expect(InputUtils.isValidDate('   '), isFalse);
      });
    });

    // Group: confirm
    group('confirm', () {
      test('should return true for "y"', () async {
        final inputs = ['y'];
        final result = await runWithOverrides(
          () => InputUtils.confirm('Proceed?'),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isTrue);
        verify(() => mockStdout.write('Proceed? [y/N]: ')).called(1);
      });

      test('should return true for "yes" (case-insensitive)', () async {
        final inputs = ['YeS'];
        final result = await runWithOverrides(
          () => InputUtils.confirm('Proceed?'),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isTrue);
        verify(() => mockStdout.write('Proceed? [y/N]: ')).called(1);
      });

      test('should return true for " y " (with whitespace)', () async {
        final inputs = [' y '];
        final result = await runWithOverrides(
          () => InputUtils.confirm('Proceed?'),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isTrue);
        verify(() => mockStdout.write('Proceed? [y/N]: ')).called(1);
      });

      test('should return false for "n"', () async {
        final inputs = ['n'];
        final result = await runWithOverrides(
          () => InputUtils.confirm('Proceed?'),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isFalse);
        verify(() => mockStdout.write('Proceed? [y/N]: ')).called(1);
      });

      test('should return false for empty input', () async {
        final inputs = [''];
        final result = await runWithOverrides(
          () => InputUtils.confirm('Proceed?'),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isFalse);
        verify(() => mockStdout.write('Proceed? [y/N]: ')).called(1);
      });

      test('should return false for other input', () async {
        final inputs = ['maybe'];
        final result = await runWithOverrides(
          () => InputUtils.confirm('Proceed?'),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isFalse);
        verify(() => mockStdout.write('Proceed? [y/N]: ')).called(1);
      });

      test('should return false for null input (simulates Ctrl+D/EOF)',
          () async {
        final inputs = <String?>[null]; // Simulate EOF
        final result = await runWithOverrides(
          () => InputUtils.confirm('Proceed?'),
          inputs: inputs,
          mockStdout: mockStdout,
        );
        expect(result, isFalse);
        verify(() => mockStdout.write('Proceed? [y/N]: ')).called(1);
      });

      // Note: The `defaultValue` parameter is not actually used in the implementation
      // test('should use defaultValue if provided (though current code doesnt)', () async { ... });
    });
  });
}
