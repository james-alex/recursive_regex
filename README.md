# recursive_regex

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
RegExp regex = RecursiveRegex(
  startDelimiter: RegExp(r'<'),
  endDelimiter: RegExp(r'>'),
);
```

This [RecursiveRegex], if applied to a string, would capture every block
of text delimited by the `<` and `>` characters.

```dart
String input = '<a<b<c><d>>>';

regex.allMatches(input); // ['<a<b<c><d>>>']
```

By default, only top-level blocks of delimited text are matched. To match
every block of delimited text, nested or not, `global` can be flagged `true`.

```dart
String input = '<a<b<c><d>>>';

RegExp regex = RecursiveRegex(
  startDelimiter: RegExp(r'<'),
  endDelimiter: RegExp(r'>'),
  global: true,
);

regex.allMatches(input); //['<c>', '<d>', '<b<c><d>>', '<a<b<c><d>>>']
```

Delimited blocks of text are matched in the order that they're closed.

__Note:__ [RecursiveRegex] is not optimized for parsing strings that do
not contain nested blocks of delimited text, [RegExp] would be more
efficient if you know the string doesn't contain any nested delimiters.

## Methods

[RecursiveRegex] has the same methods as [RegExp] (`@override` methods),
plus a few more.

```dart
/// Returns the first match found in [input].
@override
RegExpMatch firstMatch(String input);

/// Searches [input] for the match found at [index].
RegExpMatch nthMatch(int index, String input, {bool reverse = false});

/// Returns the last match found in [input].
RegExpMatch lastMatch(String input);

/// Returns a list of every match found in [input] after [start].
@override
List<RegExpMatch> allMatches(String input, [int start = 0]);

/// Returns a list of the matches found in [input].
List<RegExpMatch> getMatches(String input, {
  int start = 0, int stop, bool reverse = false,
});

/// Returns `true` if [input] contains a match, otherwise returns `false`.
@override
bool hasMatch(String input);

/// Returns the first substring match found in [input].
@override
String stringMatch(String input);

/// Returns the list of substring matches found in [input].
List<String> stringMatches(String input, {
  int start = 0, int stop, bool reverse = false,
});

/// Match the delimited pattern against the start of [string].
@override
Match matchAsPrefix(String string, [int start = 0]);
```

Behind the scenes, `firstMatch()`, `nthMatch()`, `lastMatch()`, and
`allMatches()` return results from `getMatches()`.

`getMatches()`, will identify every block of delimited text, and will apply
the delimited pattern to each block seperately. The pattern will only be
applied to the blocks being returned, all others will be ignored.

If `getMatches()` [reverse] parameter is true, blocks of delimited text will
be identified in [input] from the bottom-up, as such, calling `lastMatch()`
is significantly more efficient than calling `allMatches().last`.

`getMatches()` [start] and [stop] parameters set the range of matches that should be returned. Matches with indexes that occur before [start] and after
[stop] will be ignored. `nthMatches(3, input)` would call
`getMatches(input, start: 3, stop: 3)`.

## Capture Groups

The block of text captured between the delimiters can be captured in a
named group by providing [RecursiveRegex] with a [captureGroupName].

```dart
String input = '<!ELEMENT [ some markup ]>';

RegExp regex = RecursiveRegex(
  startDelimiter: RegExp(r'<!(?<type>\w*)\s*\['),
  endDelimiter: RegExp(r']>'),
  captureGroupName: 'value',
);

print(regex.firstMatch(input).namedGroup('value')); // ' some markup '

// Groups named within the delimiters can also be called.
print(regex.firstMatch(input).namedGroup('type')); // 'ELEMENT'
```
