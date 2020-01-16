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
}
