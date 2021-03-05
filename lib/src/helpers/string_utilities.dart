extension StringUtilities on String {
  /// Replaces every character that's not a newline with a space.
  String clean() => replaceAll(RegExp('.'), ' ');

  /// Returns `true` if [input] ends with [pattern], otherwise returns `false`.
  bool endsWithPattern(Pattern pattern) {
    assert(pattern != null);
    if (!contains(pattern)) return false;
    final match = pattern.allMatches(this).last;
    if (match.end == length) return true;
    return false;
  }
}
