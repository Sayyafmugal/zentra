/// An 8pt spacing scale used consistently instead of ad-hoc pixel literals
/// (e.g. `SizedBox(height: 17)`) scattered across screens.
abstract class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

/// Shared corner-radius conventions.
abstract class AppRadii {
  static const card = 12.0;
  static const button = 8.0;
  static const chip = 20.0;
  static const sheetTop = 20.0;
}
