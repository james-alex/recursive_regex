import 'package:meta/meta.dart';
import './helpers/delimiter.dart';
import 'helpers/string_utilities.dart' as utils;

/// An implementation of [RegExp] that isolates delimited blocks of
/// text and applies the delimiter pattern to each block separately.
@immutable
class RecursiveRegex implements RegExp {
  /// An implementation of [RegExp] that isolates delimited blocks of
  /// text and applies the delimiter pattern to each block separately.
  ///
  /// [startDelimiter] and [endDelimiter] are required, must not be
  /// `null`, and must not be identical to each other.
  ///
  /// If [prepended] and/or [appended] are not `null`, all matched sets
  /// of delimiters will be validated to be preceded and/or followed by
  /// the values of [prepended] and/or [appended] respectively. All matched
  /// sets of delimiters that do not match the prepended and/or appended
  /// patterns will be excluded from the returned [RegExpMatch]es.
  ///
  /// __Note:__ [startDelimiter], [endDelimiter], [prepended], or [appended]
  /// are set as [RegExp]s, their [multiLine], [caseSensitive], [unicode], and
  /// [dotAll] parameters will be ignored. All patterns contained within those
  /// [RegExp]s are rebuilt with this constructor's equivalent parameters.
  ///
  /// If [captureGroupName] is not `null` the block of text captured
  /// between the delimiters will be captured in a group named it.
  /// [captureGroupName] must be a least 1 character long if not `null`.
  ///
  /// [multiLine], [unicode], and [dotAll] are all `false` by
  /// default and must not be `null`.
  ///
  /// [caseSensitive] is `true` by default and must not be `null`.
  ///
  /// If [global] is `true`, every delimited block of text, nested or
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
    this.prepended,
    this.appended,
    this.captureGroupName,
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
    this.global = false,
  })  : assert(startDelimiter != null),
        assert(endDelimiter != null),
        assert((startDelimiter is String && startDelimiter != endDelimiter) ||
            (startDelimiter is RegExp && endDelimiter is RegExp &&
                startDelimiter.pattern != endDelimiter.pattern)),
        assert(captureGroupName == null || captureGroupName.length > 1),
        assert(multiLine != null),
        assert(caseSensitive != null),
        assert(unicode != null),
        assert(dotAll != null),
        assert(global != null),
        isMultiLine = multiLine,
        isCaseSensitive = caseSensitive,
        isUnicode = unicode,
        isDotAll = dotAll;

  /// The opening delimiter.
  final Pattern startDelimiter;
  String get _startDelimiter => _getPattern(startDelimiter);

  /// The closing delimiter.
  final Pattern endDelimiter;
  String get _endDelimiter => _getPattern(endDelimiter);

  /// A [Pattern] expected to precede [startDelimiter].
  ///
  /// Any [startDelimiter]s that are not preceded by [prepended] will not be
  /// matched, but will still be accounted for in the nesting order.
  final Pattern prepended;
  String get _prepended => _getPattern(prepended);

  /// A [Pattern] expected to follow [endDelimiter].
  ///
  /// Any [endDelimiter]s that are not followed by [appended] will not be
  /// matched, but will still be accounted for in the nesting order.
  final Pattern appended;
  String get _appended => _getPattern(appended);

  /// Returns [input]'s pattern as a [String].
  String _getPattern(Pattern input) => input is String
      ? _escapePattern(input).pattern
      : (input as RegExp).pattern;

  /// If not `null`, the block of text captured within the
  /// delimiters will be captured in a group named this.
  final String captureGroupName;

  @override
  final bool isMultiLine;

  @override
  final bool isCaseSensitive;

  @override
  final bool isUnicode;

  @override
  final bool isDotAll;

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
    var captureGroup = (isDotAll) ? r'.*' : r'(?:.|\s)*';

    if (captureGroupName != null) {
      captureGroup = '(?<$captureGroupName>$captureGroup)';
    }

    var pattern = '$_startDelimiter$captureGroup$_endDelimiter';

    if (prepended != null) pattern = '$_prepended$pattern';
    if (appended != null) pattern = '$pattern$_appended';

    return pattern;
  }

  /// The [RegExp] applied to delimited blocks of text.
  RegExp get regExp => _buildRegExp(pattern);

  /// Builds a [RegExp] with `this` object's specified parameters.
  RegExp _buildRegExp(String pattern) => RegExp(
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

    final matches = <RegExpMatch>[];

    var index = 0;

    final delimiters = _getDelimiters(input);

    if (delimiters == null) return null;

    if (delimiters.length == 2) {
      if (start != null && start > 1) return null;

      return regExp.allMatches(input).toList();
    }

    String getMatch(Match start, Match end) =>
        input.substring(0, start.start).clean() +
        input.substring(start.start, end.end);

    final openDelimiters = <Delimiter>[];

    for (var delimiter in (reverse) ? delimiters.reversed : delimiters) {
      if ((!reverse && delimiter.position == DelimiterPosition.start) ||
          (reverse && delimiter.position == DelimiterPosition.end)) {
        openDelimiters.add(delimiter);
        continue;
      }

      if (global || openDelimiters.length == 1) {
        if (index >= start && (stop == null || index <= stop)) {
          final startDelimiter =
              (reverse) ? delimiter.match : openDelimiters.last.match;
          final endDelimiter =
              (reverse) ? openDelimiters.last.match : delimiter.match;

          final match = getMatch(startDelimiter, endDelimiter);

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

    final match = firstMatch(input);

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

    final matches = getMatches(
      input,
      start: start,
      stop: stop,
      reverse: reverse,
    );

    return matches
        ?.map((match) => input.substring(match.start, match.end))
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
      multiLine: isMultiLine ?? this.isMultiLine,
      caseSensitive: isCaseSensitive ?? this.isCaseSensitive,
      unicode: isUnicode ?? this.isUnicode,
      dotAll: isDotAll ?? this.isDotAll,
      global: global ?? this.global,
    );
  }

  // Returns a list of every delimiter in the order of their occurance.
  List<Delimiter> _getDelimiters(String input) {
    assert(input != null);

    if (!input.contains(startDelimiter)) return null;

    var startDelimiters = startDelimiter.allMatches(input).toList();

    if (!input.contains(endDelimiter)) return null;

    var endDelimiters = endDelimiter.allMatches(input).toList()
      ..removeWhere(
          (endDelimiter) => endDelimiter.start < startDelimiters.first.start);

    if (startDelimiters.length > endDelimiters.length) {
      startDelimiters = startDelimiters.sublist(0, endDelimiters.length);
    } else if (endDelimiters.length > startDelimiters.length) {
      endDelimiters = endDelimiters.sublist(0, startDelimiters.length);
    }

    var delimiters = Delimiter.fromLists(startDelimiters, endDelimiters);

    if (delimiters.isEmpty) return delimiters;

    if (prepended != null) {
      delimiters = _checkAndUnmatch(input, delimiters);
    }

    if (appended != null) {
      delimiters = _checkAndUnmatch(input, delimiters, appended: true);
    }

    return delimiters;
  }

  /// Checks the delimiters for the [prepended] or [appended] patterns and
  /// unmatches the delimiters that are not adjoined by the pattern.
  List<Delimiter> _checkAndUnmatch(
    String input,
    List<Delimiter> delimiters, {
    bool appended = false,
  }) {
    assert(delimiters != null);
    assert(appended != null);

    final unmatchedDelimiters = <Delimiter>[];
    final removeDelimiters = <int>[];

    var lastDelimiterPosition = appended ? input.length : 0;

    for (var delimiter in appended ? delimiters.reversed : delimiters) {
      if ((!appended && delimiter.position == DelimiterPosition.start) ||
          (appended && delimiter.position == DelimiterPosition.end)) {
        if (removeDelimiters.isNotEmpty) {
          for (var j = 0; j < removeDelimiters.length; j++) {
            removeDelimiters[j]++;
          }
        }

        final slice = appended
            ? input.substring(delimiter.match.start, lastDelimiterPosition)
            : input.substring(lastDelimiterPosition, delimiter.match.end);

        final pattern = appended
            ? _buildRegExp('$_endDelimiter$_appended')
            : _buildRegExp('$_prepended$_startDelimiter');

        // If the [slice] matches the [pattern], update the delimiter's [Match]
        // to include the appended/prepended pattern.
        if (appended
            ? slice.startsWith(pattern)
            : slice.endsWithPattern(pattern)) {
          final matches = pattern.allMatches(input);

          final position =
              appended ? delimiter.match.start : delimiter.match.end;

          for (var match in matches) {
            if (appended ? match.start == position : match.end == position) {
              delimiters[delimiters.indexOf(delimiter)].match = match;              break;
            }
          }
          // Otherwise, queue the delimiter and it's corresponding
          // start/end delimiter to be removed after the loop.
        } else {
          unmatchedDelimiters.add(delimiter);
          removeDelimiters.add(0);
        }
      } else if (removeDelimiters.isNotEmpty) {
        for (var j = 0; j < removeDelimiters.length; j++) {
          if (removeDelimiters[j] == 0) {
            unmatchedDelimiters.add(delimiter);
          }
          removeDelimiters[j]--;
        }
        removeDelimiters.removeWhere((value) => value <= 0);
      }

      lastDelimiterPosition =
          appended ? delimiter.match.start : delimiter.match.end;
    }

    if (unmatchedDelimiters.isNotEmpty) {
      unmatchedDelimiters.forEach(delimiters.remove);
    }

    return delimiters;
  }

  @override
  bool operator ==(Object o) =>
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
