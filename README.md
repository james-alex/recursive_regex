# recursive_regex

[![pub package](https://img.shields.io/pub/v/recursive_regex.svg)](https://pub.dartlang.org/packages/recursive_regex)

An implementation of Dart's RegExp class that isolates delimited blocks
of text and applies the delimited pattern to each block separately.

The [RecursiveRegex] class implements Dart's [RegExp] class. As such,
it has all of the same methods as [RegExp] and can be used interchangeably
with [RegExp]s.

## Usage

```dart
import 'package:recursive_regex/recursive_regex.dart';
```

[RecursiveRegex] has 2 required parameters, [startDelimiter] and
[endDelimiter]. Both accept a [RegExp], must not be `null`, and
must not have identical patterns.

```dart
final regex = RecursiveRegex(
  startDelimiter: RegExp(r'<'),
  endDelimiter: RegExp(r'>'),
);
```

This [RecursiveRegex], if applied to a string, would capture every block
of text delimited by the `<` and `>` characters.

```dart
final input = 'a<b<c<d><e>f>g>h';
regex.allMatches(input); // ['<b<c<d><e>f>g>']
```

By default, only top-level blocks of delimited text are matched. To match
every block of delimited text, nested or not, [global] can be flagged `true`.

```dart
final input = '<a<b<c><d>>>';

final regex = RecursiveRegex(
  startDelimiter: RegExp(r'<'),
  endDelimiter: RegExp(r'>'),
  global: true,
);

regex.allMatches(input); // ['<c>', '<d>', '<b<c><d>>', '<a<b<c><d>>>']
```

Delimited blocks of text are matched in the order that they're closed.

__Note:__ [RecursiveRegex] is not optimized for parsing strings that do
not contain nested blocks of delimited text, [RegExp] would be more
efficient if you know the string doesn't contain any nested delimiters.

### [prepended] & [appended] Patterns

[Pattern]s can be provided to [RecursiveRegex]'s [prepended] and [appended]
parameters to disqualify any matched set of delimiters that aren't lead and/or
followed by the provided [Pattern].

```dart
final input = '0<a<b<1<c>2>3<d>>>';

final prepended = RecursiveRegex(
  startDelimiter: RegExp(r'<'),
  endDelimiter: RegExp(r'>'),
  prepended: RegExp(r'[0-9]'),
  global: true,
);

prepended.allMatches(input); // ['1<c>', '3<d>', '0<a<b<1<c>2>3<d>>>']

final appended = RecursiveRegex(
  startDelimiter: RegExp(r'<'),
  endDelimiter: RegExp(r'>'),
  appended: RegExp(r'[0-9]'),
  global: true,
);

appended.allMatches(input); // ['<c>2', '<1<c>2>3']

final both = RecursiveRegex(
  startDelimiter: RegExp(r'<'),
  endDelimiter: RegExp(r'>'),
  prepended: RegExp(r'[0-9]'),
  appended: RegExp(r'[0-9]'),
  global: true,
);

both.allMatches(input); // ['0<a<b<1<c>2>3']
```

### inverseMatch

A [Pattern] can be provided to the [inverseMatch] parameter to define a
pattern that should be matched, but only if it's not delimited.

__Note:__ [global] has no affect on the matches if an [inverseMatch]
pattern is provided, as all lower-level matches are delimited.

```dart
final input = 'a<b<c<d><e>f>g>h';

final regex = RecursiveRegex(
  startDelimiter: RegExp(r'<'),
  endDelimiter: RegExp(r'>'),
  inverseMatch: RegExp(r'[a-z]'),
  global: true,
);

regex.allMatches(input); // ['a', 'h']
```

## Capture Groups

The block of text captured between the delimiters can be captured in a
named group by providing [RecursiveRegex] with a [captureGroupName].

```dart
final input = '<!ELEMENT [ some markup ]>';

final regex = RecursiveRegex(
  startDelimiter: RegExp(r'<!(?<type>\w*)\s*\['),
  endDelimiter: RegExp(r']>'),
  captureGroupName: 'value',
);

print(regex.firstMatch(input).namedGroup('value')); // ' some markup '

// Groups named within the delimiters can also be called.
print(regex.firstMatch(input).namedGroup('type')); // 'ELEMENT'
```
