/// Pure tax & discount calculation logic.
/// No Flutter, no ObjectBox — just math.
/// Used by controller and UI form for live calculation.
class PurchaseTaxCalc {
  /// Calculate all amounts for one line item.
  ///
  /// [unitCost]        Price per unit as entered (incl or excl tax)
  /// [qty]             Ordered quantity
  /// [discountPercent] Discount % on this line (0 if none)
  /// [taxRate]         Tax rate % e.g. 18.0 (0 if none)
  /// [isTaxInclusive]  true = price includes tax, false = tax added on top
  ///
  /// Returns [LineCalcResult] with all computed amounts.
  static LineCalcResult calculate({
    required double unitCost,
    required double qty,
    double discountPercent = 0,
    double taxRate = 0,
    bool isTaxInclusive = false,
  }) {
    // ── Step 1: Raw line amount ──
    final rawAmount = unitCost * qty;

    // ── Step 2: Discount ──
    final discountAmount = rawAmount * (discountPercent / 100);
    final afterDiscount = rawAmount - discountAmount;

    // ── Step 3: Tax ──
    double lineAmountExcl;
    double taxAmount;
    double lineAmountIncl;

    if (taxRate <= 0) {
      // No tax
      lineAmountExcl = afterDiscount;
      taxAmount = 0;
      lineAmountIncl = afterDiscount;
    } else if (isTaxInclusive) {
      // With Tax: price already includes tax
      // Extract tax from inside the price
      // taxAmount = afterDiscount - afterDiscount / (1 + taxRate/100)
      lineAmountIncl = afterDiscount;
      taxAmount = afterDiscount - (afterDiscount / (1 + taxRate / 100));
      lineAmountExcl = afterDiscount - taxAmount;
    } else {
      // Without Tax: add tax on top
      lineAmountExcl = afterDiscount;
      taxAmount = afterDiscount * (taxRate / 100);
      lineAmountIncl = afterDiscount + taxAmount;
    }

    return LineCalcResult(
      rawAmount: rawAmount,
      discountAmount: _round(discountAmount),
      lineAmountExcl: _round(lineAmountExcl),
      taxAmount: _round(taxAmount),
      lineAmountIncl: _round(lineAmountIncl),
    );
  }

  /// Calculate purchase-level totals from all line results.
  static PurchaseTotals calculateTotals({
    required List<LineCalcResult> lines,
    double roundOff = 0,
  }) {
    final totalAmount =
    lines.fold(0.0, (sum, l) => sum + l.rawAmount);
    final totalDiscount =
    lines.fold(0.0, (sum, l) => sum + l.discountAmount);
    final totalExclTax =
    lines.fold(0.0, (sum, l) => sum + l.lineAmountExcl);
    final totalTax =
    lines.fold(0.0, (sum, l) => sum + l.taxAmount);
    final grandTotal =
    _round(totalExclTax + totalTax + roundOff);

    return PurchaseTotals(
      totalAmount: _round(totalAmount),
      totalDiscountAmount: _round(totalDiscount),
      totalExclTax: _round(totalExclTax),
      totalTaxAmount: _round(totalTax),
      roundOff: roundOff,
      grandTotal: grandTotal,
    );
  }

  /// Round to 2 decimal places
  static double _round(double value) =>
      double.parse(value.toStringAsFixed(2));
}

// ─────────────────────────────────────────────
//  RESULT CLASSES
// ─────────────────────────────────────────────

class LineCalcResult {
  final double rawAmount;
  final double discountAmount;
  final double lineAmountExcl;
  final double taxAmount;
  final double lineAmountIncl;

  const LineCalcResult({
    required this.rawAmount,
    required this.discountAmount,
    required this.lineAmountExcl,
    required this.taxAmount,
    required this.lineAmountIncl,
  });
}

class PurchaseTotals {
  final double totalAmount;
  final double totalDiscountAmount;
  final double totalExclTax;
  final double totalTaxAmount;
  final double roundOff;
  final double grandTotal;

  const PurchaseTotals({
    required this.totalAmount,
    required this.totalDiscountAmount,
    required this.totalExclTax,
    required this.totalTaxAmount,
    required this.roundOff,
    required this.grandTotal,
  });
}
