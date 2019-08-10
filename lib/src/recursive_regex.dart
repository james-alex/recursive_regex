import 'package:meta/meta.dart';

/// An implementation of [RegExp] that isolates delimited blocks of
/// text and applies the delimiter pattern to each block separately.
class RecursiveRegex implements RegExp {
  /// An implementation of [RegExp] that isolates delimited blocks of
  /// text and applies the delimiter pattern to each block separately.
  ///
  /// [startDelimiter] and [endDelimiter] are required, must not be
  /// `null`, and must not be identical to each other.
  ///
  /// If [captureGroupName] is not `null` the block of text captured
  /// between the delimiters will be captured in a group named it.
  /// [captureGroupName] must be a least 1 character long if not `null`.
  ///
  /// [isMultiline], [isUnicode], and [isDotAll] are all `false` by
  /// default and must not be `null`.
  ///
  /// [isCaseSensitive] is `true` by default and must not be `null`.
  ///
  /// If [global] is `true`, every delimited block of text, nested
  /// not, will be matched. If `false`, only the top-level blocks of
  /// delimited text will be matched.
  ///
  /// __Note:__ Due to the way this package isolates delimited text,
  /// the [startDelimiter] shouldn't start with and the [endDelimiter]
  /// shouldn't end with a token that captures whitespace. It will cause
  /// your matches to start at the beginning of and end at the length of
  /// the inputted string.
  RecursiveRegex({
    @required this.startDelimiter,
    @required this.endDelimiter,
    this.captureGroupName,
    this.isMultiLine = false,
    this.isCaseSensitive = true,
    this.isUnicode = false,
    this.isDotAll = false,
    this.global = false,
  })  : assert(startDelimiter != null),
        assert(endDelimiter != null),
        assert(startDelimiter.pattern != endDelimiter.pattern),
        assert(captureGroupName == null || captureGroupName.length > 1),
        assert(isMultiLine != null),
        assert(isCaseSensitive != null),
        assert(isUnicode != null),
        assert(isDotAll != null),
        assert(global != null);

  /// The opening delimiter.
  final RegExp startDelimiter;

  /// The closing delimiter.
  final RegExp endDelimiter;

  /// If not `null`, the block of text captured within the
  /// delimiters will be captured in a group named this.
  final String captureGroupName;

  /// If `true`, every block of delimited text, nested or not,
  /// will be matched. If `false`, only top-level blocks of
  /// delimited text will be matched.
  final bool global;

  /// The pattern applied to delimited blocks of text.
  ///
  /// __Note:__ This pattern is applied to each delimited
  /// block of text separately, as such, it won't properly
  /// capture strings containing multiple blocks of delimited
  /// text if used with a [RegExp].
  @override
  String get pattern {
    final String captureGroup = (captureGroupName != null)
        ? '(?<$captureGroupName>(?:.|\\n)*)'
        : '(?:.|\\n)*';

    return '${startDelimiter.pattern}$captureGroup${endDelimiter.pattern}';
  }

  /// The [RegExp] applied delimited blocks of text.
  RegExp get regExp => RegExp(
        pattern,
        multiLine: isMultiLine,
        caseSensitive: isCaseSensitive,
        unicode: isUnicode,
        dotAll: isDotAll,
      );

  @override
  RegExpMatch firstMatch(String input) {
    assert(input != null);

    return getMatches(input, start: 0, stop: 0)?.first;
  }

  /// Searches [input] for the match found at [index].
  /// Returns `null` if one isn't found.
  ///
  /// [index] must not be `null` and must be `>= 0`. [index] will
  /// be counted in the order matches are found. (In the order
  /// their delimiters are closed. If an [index] of `3` is supplied,
  /// the 3rd match will be returned, however if [reverse] is `true`,
  /// the 3rd from last match will be returned.)
  ///
  /// [input] must not be `null`.
  ///
  /// If [reverse] is `true`, [input]'s delimited blocks of text
  /// will be parsed in reverse order. If looking for a match
  /// towards the end of the string, finding it in reverse order
  /// is more efficient. [reverse] must not be `null`.
  RegExpMatch nthMatch(
    int index,
    String input, {
    bool reverse = false,
  }) {
    assert(index != null && index >= 0);
    assert(input != null);
    assert(reverse != null);

    return getMatches(input, start: index, stop: index, reverse: false)?.first;
  }

  /// Returns the last match found in [input].
  ///
  /// [input]'s delimited blocks of text will be detected in
  /// reverse order, so only the last block will be parsed.
  RegExpMatch lastMatch(String input) {
    assert(input != null);

    return getMatches(input, start: 0, stop: 0, reverse: true)?.first;
  }

  /// Returns a list of every match found in [input] after [start].
  ///
  /// Returns `null` if no matches were found.
  @override
  List<RegExpMatch> allMatches(String input, [int start = 0]) {
    assert(input != null);
    assert(start != null && start >= 0);

    return getMatches(input.substring(start));
  }

  /// Returns a list of the matches found in [input].
  ///
  /// [start] and [stop] refer to the indexes of the delimited blocks
  /// of text. Only matches found between [start] and [stop] will be
  /// returned.
  ///
  /// [start] must not be `null` and must be `>= 0`.
  ///
  /// [stop] may be `null` and must be `>= start`.
  ///
  /// If [reverse] is `true`, [input]'s delimited blocks of text
  /// will be parsed in reverse order. If looking for a match
  /// towards the end of the string, finding it in reverse order
  /// is more efficient. [start] and [stop] will be counted in
  /// the order the matches are closed.
  List<RegExpMatch> getMatches(
    String input, {
    int start = 0,
    int stop,
    bool reverse = false,
  }) {
    assert(input != null);
    assert(start != null && start >= 0);
    assert(stop == null || stop >= start);
    assert(reverse != null);

    final List<RegExpMatch> matches = List<RegExpMatch>();

    int index = 0;

    final List<_Delimiter> delimiters = _getDelimiters(input);

    if (delimiters == null) return null;

    if (delimiters.length == 2) {
      if (start != null && start > 1) return null;

      return regExp.allMatches(input).toList();
    }

    String getMatch(RegExpMatch start, RegExpMatch end) =>
        _clean(input.substring(0, start.start)) +
        input.substring(start.start, end.end);

    final List<_Delimiter> openDelimiters = List<_Delimiter>();

    for (_Delimiter delimiter in (reverse) ? delimiters.reversed : delimiters) {
      if ((!reverse && delimiter.position == _DelimiterPosition.start) ||
          (reverse && delimiter.position == _DelimiterPosition.end)) {
        openDelimiters.add(delimiter);
        continue;
      }

      if (global || openDelimiters.length == 1) {
        if (index >= start && (stop == null || index <= stop)) {
          final RegExpMatch startDelimiter =
              (reverse) ? delimiter.match : openDelimiters.last.match;
          final RegExpMatch endDelimiter =
              (reverse) ? openDelimiters.last.match : delimiter.match;

          final String match = getMatch(startDelimiter, endDelimiter);

          matches.add(regExp.firstMatch(match));
        }

        index++;

        if (stop != null && index > stop) break;
      }

      openDelimiters.removeLast();
    }

    if (matches.isEmpty) return null;

    return matches;
  }

  @override
  bool hasMatch(String input) {
    assert(input != null);

    return regExp.hasMatch(input);
  }

  @override
  String stringMatch(String input) {
    assert(input != null);

    final RegExpMatch match = firstMatch(input);

    return input.substring(match.start, match.end);
  }

  /// Returns the list of substring matches found in [input].
  ///
  /// [start] and [stop] refer to the indexes of the delimited blocks
  /// of text. Only matches found between [start] and [stop] will be
  /// returned.
  ///
  /// [start] must not be `null` and must be `>= 0`.
  ///
  /// [stop] may be `null` and must be `>= start`.
  List<String> stringMatches(
    String input, {
    int start = 0,
    int stop,
    bool reverse = true,
  }) {
    assert(input != null);
    assert(start != null && start >= 0);
    assert(stop == null || stop >= start);
    assert(reverse != null);

    final List<RegExpMatch> matches = getMatches(
      input,
      start: start,
      stop: stop,
      reverse: reverse,
    );

    return matches
        ?.map((RegExpMatch match) => input.substring(match.start, match.end))
        ?.toList();
  }

  /// Match the delimited pattern against the [string] at
  /// the position of [start].
  ///
  /// [start] must not be null and must be `>= 0`.
  @override
  Match matchAsPrefix(String string, [int start = 0]) {
    assert(string != null);
    assert(start != null && start >= 0);

    return pattern.matchAsPrefix(string, start);
  }

  @override
  final bool isMultiLine;

  @override
  final bool isCaseSensitive;

  @override
  final bool isUnicode;

  @override
  final bool isDotAll;

  /// Returns a copy of [RecursiveRegex], updating any values provided by this.
  ///
  /// If [copyNull] is `true`, [captureGroupName] will be copied with a
  /// value of `null` if it is not provided with another value.
  RecursiveRegex copyWith({
    RegExp startDelimiter,
    RegExp endDelimiter,
    String captureGroupName,
    bool isMultiLine,
    bool isCaseSensitive,
    bool isUnicode,
    bool isDotAll,
    bool global,
    bool copyNull = false,
  }) {
    assert(copyNull != null);

    if (!copyNull) captureGroupName ??= this.captureGroupName;

    return RecursiveRegex(
      startDelimiter: startDelimiter ?? this.startDelimiter,
      endDelimiter: endDelimiter ?? this.endDelimiter,
      captureGroupName: captureGroupName,
      isMultiLine: isMultiLine ?? this.isMultiLine,
      isCaseSensitive: isCaseSensitive ?? this.isCaseSensitive,
      isUnicode: isUnicode ?? this.isUnicode,
      isDotAll: isDotAll ?? this.isDotAll,
      global: global ?? this.global,
    );
  }

  // Returns a list of every delimiter in the order of their occurance.
  List<_Delimiter> _getDelimiters(String input) {
    assert(input != null);

    if (!input.contains(startDelimiter)) return null;

    List<RegExpMatch> startDelimiters =
        startDelimiter.allMatches(input).toList();

    if (!input.contains(endDelimiter)) return null;

    List<RegExpMatch> endDelimiters = endDelimiter.allMatches(input).toList()
      ..removeWhere((RegExpMatch endDelimiter) =>
          endDelimiter.start < startDelimiters.first.start);

    if (startDelimiters.length > endDelimiters.length) {
      startDelimiters = startDelimiters.sublist(0, endDelimiters.length);
    } else if (endDelimiters.length > startDelimiters.length) {
      endDelimiters = endDelimiters.sublist(0, startDelimiters.length);
    }

    return _Delimiter.fromLists(startDelimiters, endDelimiters);
  }

  /// Replaces every character that's not a newline with a space.
  static String _clean(String input) {
    assert(input != null);

    return input.replaceAll(RegExp('.'), ' ');
  }

  @override
  operator ==(o) =>
      o is RecursiveRegex &&
      startDelimiter == o.startDelimiter &&
      endDelimiter == o.endDelimiter &&
      captureGroupName == o.captureGroupName &&
      isMultiLine == o.isMultiLine &&
      isCaseSensitive == o.isCaseSensitive &&
      isUnicode == o.isUnicode &&
      isDotAll == o.isDotAll;

  @override
  int get hashCode =>
      startDelimiter.hashCode ^
      endDelimiter.hashCode ^
      captureGroupName.hashCode ^
      isMultiLine.hashCode ^
      isCaseSensitive.hashCode ^
      isUnicode.hashCode ^
      isDotAll.hashCode;
}

enum _DelimiterPosition { start, end }

class _Delimiter {
  const _Delimiter(this.position, this.match)
      : assert(position != null),
        assert(match != null);

  final _DelimiterPosition position;

  final RegExpMatch match;

  static List<_Delimiter> fromLists(
    List<RegExpMatch> start,
    List<RegExpMatch> end,
  ) {
    assert(start != null);
    assert(end != null);
    assert(start.length == end.length);

    final List<_Delimiter> delimiters = List<_Delimiter>();

    delimiters.addAll(start.map((RegExpMatch delimiter) =>
        _Delimiter(_DelimiterPosition.start, delimiter)));

    delimiters.addAll(end.map((RegExpMatch delimiter) =>
        _Delimiter(_DelimiterPosition.end, delimiter)));

    delimiters.sort(
        (_Delimiter a, _Delimiter b) => a.match.start.compareTo(b.match.start));

    return delimiters;
  }
}
