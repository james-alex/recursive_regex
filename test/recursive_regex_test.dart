import 'package:test/test.dart';
import 'package:recursive_regex/recursive_regex.dart';

void main() {
  test('Nested Matches', () {
    final String input = '<a<b<c><d<e>>><f>>';

    final RecursiveRegex regex = RecursiveRegex(
      startDelimiter: RegExp(r'<'),
      endDelimiter: RegExp(r'>'),
    );

    expect(regex.allMatches(input).length, equals(1));

    expect(regex.stringMatch(input), equals(input));

    final RecursiveRegex globalRegex = regex.copyWith(global: true);

    final List<RegExpMatch> matches = globalRegex.allMatches(input);

    expect(matches.length, equals(6));

    final List<String> expectedMatches = <String>[
      '<c>',
      '<e>',
      '<d<e>>',
      '<b<c><d<e>>>',
      '<f>',
      input,
    ];

    matches.forEach((RegExpMatch match) {
      expect(input.substring(match.start, match.end),
          equals(expectedMatches.first));

      expectedMatches.removeAt(0);
    });
  });
}
