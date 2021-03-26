import 'package:test/test.dart';
import 'package:recursive_regex/recursive_regex.dart';

void main() {
  test('Nested Matches', () {
    final input = '<a<b<c><d<e>>><f>>';

    final regex = RecursiveRegex(
      startDelimiter: RegExp(r'<'),
      endDelimiter: RegExp(r'>'),
    );

    expect(regex.allMatches(input).length, equals(1));

    expect(regex.stringMatch(input), equals(input));

    final globalRegex = regex.copyWith(global: true);

    final matches = globalRegex.allMatches(input);

    expect(matches.length, equals(6));

    final expectedMatches = <String>[
      '<c>',
      '<e>',
      '<d<e>>',
      '<b<c><d<e>>>',
      '<f>',
      input,
    ];

    for (var match in matches) {
      expect(input.substring(match.start, match.end),
          equals(expectedMatches.first));

      expectedMatches.removeAt(0);
    }
  });

  test('Appended & Prepended Values', () {
    final input =
        'Test { void update { false } Test { /* Test { /* */ } Test */ false Test { } Test } true } test { test }';

    final prepended = RecursiveRegex(
      startDelimiter: '{',
      endDelimiter: '}',
      prepended: 'Test ',
      global: true,
    );

    final prependedMatches = prepended.allMatches(input);
    expect(prependedMatches.length, equals(4));

    final appended = RecursiveRegex(
      startDelimiter: '{',
      endDelimiter: '}',
      appended: ' Test',
      global: true,
    );

    final appendedMatches = appended.allMatches(input);
    expect(appendedMatches.length, equals(3));

    final both = RecursiveRegex(
      startDelimiter: '{',
      endDelimiter: '}',
      prepended: 'Test ',
      appended: ' Test',
      global: true,
    );

    final bothMatches = both.allMatches(input);
    expect(bothMatches.length, equals(2));
  });

  test('Inverse Matches', () {
    final input =
        'Object test4 { void update() Test { /* test6 */ false Test { test3 } } test2 } test1 true test5';

    final regex = RecursiveRegex(
      startDelimiter: '{',
      endDelimiter: '}',
      inverseMatch: RegExp('test[1-5]'),
    );

    final matches = regex.allMatches(input);
    final expectedMatches = <String>['test4', 'test1', 'test5'];

    for (var match in matches) {
      expect(input.substring(match.start, match.end),
          equals(expectedMatches.removeAt(0)));
    }
  });
}
