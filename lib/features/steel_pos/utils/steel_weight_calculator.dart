/// Core Steel Metallurgy & Structural Weight Calculation Utilities.
/// Standard Density of Structural Steel: 7850 kg/m³ (7.85 g/cm³).
class SteelWeightCalculator {
  static const double steelDensity = 7.85; // kg/m² per 1mm thickness

  /// Calculates TMT Rebar weight in Kilograms using standard formula:
  /// W = (D² / 162.28) * Length (m) * Pieces
  static double calculateTmtWeightKg({
    required double diameterMm,
    required double lengthMeters,
    required int pieces,
  }) {
    if (diameterMm <= 0 || lengthMeters <= 0 || pieces <= 0) return 0.0;
    // Standard engineering constant: 162.28 (derived from π/4 * 7850 / 1000)
    final weightPerMeter = (diameterMm * diameterMm) / 162.28;
    return weightPerMeter * lengthMeters * pieces;
  }

  /// Calculates MS Plate / Sheet weight in Kilograms:
  /// W = Length (m) * Width (m) * Thickness (mm) * 7.85 * Pieces
  static double calculatePlateWeightKg({
    required double lengthMeters,
    required double widthMeters,
    required double thicknessMm,
    required int pieces,
  }) {
    if (lengthMeters <= 0 || widthMeters <= 0 || thicknessMm <= 0 || pieces <= 0) return 0.0;
    return lengthMeters * widthMeters * thicknessMm * steelDensity * pieces;
  }

  /// Calculates MS Round Pipe weight in Kilograms:
  /// W = (OD - Thickness) * Thickness * 0.02466 * Length (m) * Pieces
  static double calculateRoundPipeWeightKg({
    required double outerDiameterMm,
    required double thicknessMm,
    required double lengthMeters,
    required int pieces,
  }) {
    if (outerDiameterMm <= 0 || thicknessMm <= 0 || lengthMeters <= 0 || pieces <= 0) return 0.0;
    final weightPerMeter = (outerDiameterMm - thicknessMm) * thicknessMm * 0.02466;
    return weightPerMeter * lengthMeters * pieces;
  }

  /// Calculates Square Hollow Section (SHS) weight in Kilograms:
  /// W = 4 * (Side - Thickness) * Thickness * 0.00785 * Length (m) * Pieces
  static double calculateSquareTubeWeightKg({
    required double sideMm,
    required double thicknessMm,
    required double lengthMeters,
    required int pieces,
  }) {
    if (sideMm <= 0 || thicknessMm <= 0 || lengthMeters <= 0 || pieces <= 0) return 0.0;
    final weightPerMeter = 4 * (sideMm - thicknessMm) * thicknessMm * 0.00785;
    return weightPerMeter * lengthMeters * pieces;
  }

  /// Converts Kilograms to Metric Tons (MT)
  static double kgToMetricTons(double weightKg) => weightKg / 1000.0;

  /// Converts Metric Tons (MT) to Kilograms
  static double metricTonsToKg(double metricTons) => metricTons * 1000.0;

  /// Converts Rate per Metric Ton (₹/MT) to Rate per Kg (₹/Kg)
  static double rateMtToRateKg(double ratePerMT) => ratePerMT / 1000.0;

  /// Converts Rate per Kg (₹/Kg) to Rate per Metric Ton (₹/MT)
  static double rateKgToRateMt(double ratePerKg) => ratePerKg * 1000.0;

  /// Format weight string cleanly:
  /// e.g. "14.250 MT" or "450.00 Kg"
  static String formatWeight(double weightKg) {
    if (weightKg >= 1000.0) {
      final mt = weightKg / 1000.0;
      return '${mt.toStringAsFixed(3)} MT (${weightKg.toStringAsFixed(1)} Kg)';
    } else {
      return '${weightKg.toStringAsFixed(2)} Kg';
    }
  }

  /// Format pure Metric Ton string: e.g. "14.250 MT"
  static String formatMt(double weightKg) {
    final mt = weightKg / 1000.0;
    return '${mt.toStringAsFixed(3)} MT';
  }
}
