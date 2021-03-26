/// Whether [Delimiter] is an opening or closing delimiter.
enum DelimiterPosition {
  /// An opening delimiter.
  start,

  /// A closing delimiter.
  end,
}

/// A delimiter matched in a [String].
class Delimiter {
  /// A delimiter matched in a [String].
  ///
  /// [position] and [match] both must not be `null`.
  Delimiter(this.position, this.match);

  /// The type of delimiter (opening or closing.)
  final DelimiterPosition position;

  /// The delimiter as matched in a [String] by a [Pattern].
  Match match;

  /// Joins and sorts two lists of delimiters by their order
  /// of occurence in a string.
  static List<Delimiter> fromLists(
    List<Match> start,
    List<Match> end,
  ) {
    assert(start.length == end.length);

    final delimiters = <Delimiter>[];

    delimiters.addAll(start
        .map((delimiter) => Delimiter(DelimiterPosition.start, delimiter)));

    delimiters.addAll(
        end.map((delimiter) => Delimiter(DelimiterPosition.end, delimiter)));

    delimiters.sort((a, b) => a.match.start.compareTo(b.match.start));

    return delimiters;
  }
}
