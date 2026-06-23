/// Catalog of TTF font families bundled with the app (ROADMAP §2.5).
///
/// The list is the only thing the domain/presentation layers know about
/// the font set: the actual TTF asset declarations live in
/// `pubspec.yaml` and are accessed via `family` strings.
class FontRegistry {
  const FontRegistry();

  static const List<FontFamily> curado = <FontFamily>[
    FontFamily(family: 'Roboto', assetPath: 'assets/fonts/Roboto-Regular.ttf', license: 'Apache-2.0'),
    FontFamily(family: 'Open Sans', assetPath: 'assets/fonts/OpenSans-Regular.ttf', license: 'OFL-1.1'),
    FontFamily(family: 'Lato', assetPath: 'assets/fonts/Lato-Regular.ttf', license: 'OFL-1.1'),
    FontFamily(family: 'Merriweather', assetPath: 'assets/fonts/Merriweather-Regular.ttf', license: 'OFL-1.1'),
    FontFamily(family: 'Source Code Pro', assetPath: 'assets/fonts/SourceCodePro-Regular.ttf', license: 'OFL-1.1'),
  ];

  /// Returns the family by name, or `null` if it is not part of the
  /// curated set (presentation should treat that as a bug).
  static FontFamily? byName(String name) {
    for (final f in curado) {
      if (f.family == name) return f;
    }
    return null;
  }
}

class FontFamily {
  const FontFamily({required this.family, required this.assetPath, required this.license});

  /// The name used by `TextStyle(fontFamily: ...)` (matches pubspec).
  final String family;

  /// Path of the TTF asset, relative to the project root.
  final String assetPath;

  /// SPDX-like license identifier (OFL-1.1 / Apache-2.0 / ...).
  final String license;
}
