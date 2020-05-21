/// Replaces every character that's not a newline with a space.
String clean(String input) {
  assert(input != null);

  return input.replaceAll(RegExp('.'), ' ');
}

/// Returns `true` if [input] ends with [pattern], otherwise returns `false`.
bool endsWith(String input, RegExp pattern) {
  assert(input != null);
  assert(pattern != null);

  if (!input.contains(pattern)) return false;

  final match = pattern.allMatches(input).last;

  if (match.end == input.length) return true;

  return false;
}
