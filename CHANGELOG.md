## [1.0.0] - March 26, 2021

* Migrated to null-safe code.

## [0.2.0] - March 5, 2021

* [startDelimiter] and [endDelimiter] are now [Pattern]s instead of [RegExp]s,
so delimiters can be provided as a [String] or a [RegExp].

* Added the [prepend] and [append] parameters. If provided, delimited blocks of
text will only be matched if they are prepended with or appended with the provided
[Pattern].

* Renamed the [isMultiLine], [isCaseSensitive], [isUnicode], and [isDotAll]
parameters to [multiLine], [caseSensitive], [unicode], and [dotAll] respectively,
to match the naming convention of Dart's [RegExp] class.

* Added the [startsWith] and [endsWith] methods.

* Added the [inverseMatch] parameter.

* Documentation and formatting changes.

## [0.1.3+1] - January 16, 2020

* Formatting changes

## [0.1.1 - 0.1.3] - August 10, 2019

* Bug fixes

## [0.1.0] - August 8, 2019

* Initial release.
