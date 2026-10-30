/// Multi-vertical POS application type identifier.
///
/// The backend authenticates users and returns a business-type hint
/// (`appType`) in the login response. This enum is the single source of
/// truth for all 7 supported verticals and drives the polymorphic
/// [AppTypeProfile] that slots 10% of the UI.
enum AppType {
  steel,
  market,
  apparel,
  electronics,
  jewellery,
  optical,
  footwear,
}

/// Parses a raw backend string (e.g. "STEEL", "steel", "Steel Terminal")
/// into a typed [AppType].
///
/// Defaults to [AppType.market] for any unknown value so the app never
/// breaks on an unrecognized vertical. Comparison is case-insensitive and
/// tolerant of whitespace / underscores.
extension AppTypeParser on AppType {
  static AppType fromString(String? raw) {
    if (raw == null) return AppType.market;
    final normalized =
        raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    if (normalized.isEmpty) return AppType.market;

    for (final type in AppType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }

    // Tolerant aliases used by some backends
    switch (normalized) {
      case 'steel':
      case 'steelterminal':
      case 'construction':
      case 'cement':
        return AppType.steel;
      case 'market':
      case 'supermarket':
      case 'kirana':
      case 'fmcg':
      case 'grocery':
        return AppType.market;
      case 'apparel':
      case 'garments':
      case 'boutique':
      case 'clothing':
      case 'fashion':
        return AppType.apparel;
      case 'electronics':
      case 'mobile':
      case 'showroom':
      case 'gadgets':
        return AppType.electronics;
      case 'jewellery':
      case 'jewelry':
      case 'gold':
      case 'gems':
      case 'ornaments':
        return AppType.jewellery;
      case 'optical':
      case 'eyewear':
      case 'lenses':
      case 'vision':
        return AppType.optical;
      case 'footwear':
      case 'shoes':
      case 'sandals':
      case 'leather':
        return AppType.footwear;
    }

    return AppType.market;
  }
}

/// Convenience top-level helper mirroring the extension for callers that
/// prefer a free function.
AppType parseAppType(String? raw) => AppTypeParser.fromString(raw);